import { validationResult } from "express-validator";
import SitterBooking from "../models/SitterBooking.js";
import PetSitter from "../models/PetSitter.js";
import Pet from "../models/Pet.js";
import User from "../models/User.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import { sendPush } from "../utils/fcm.js";
import { sendEmail } from "../utils/mail.js";
import {
  cancelTrackingGrace,
  computePayableAmount,
  markServiceCompleted,
  markServiceStarted,
} from "../services/sitterTrackingService.js";

const SERVICE_LABELS = {
  walking: "Gezdirme",
  home_sitting: "Ev Bakimi",
  boarding: "Pansiyonda Bakim",
  daycare: "Gunduz Bakimi",
  grooming: "Timar/Bakim",
};

// POST / - Rezervasyon olustur
export async function createBooking(req, res) {
  try {
    const petOwnerId = req.user.sub;
    const { sitterId, petId, serviceType, startDate, endDate, notes } = req.body;

    if (!sitterId || !petId || !serviceType || !startDate || !endDate) {
      return sendError(res, 400, "Eksik alan", "missing_fields");
    }

    const sitter = await PetSitter.findById(sitterId);
    if (!sitter || !sitter.isActive) return sendError(res, 404, "Bakici bulunamadi", "not_found");
    if (!sitter.availability) return sendError(res, 400, "Bakici simdilik musait degil", "not_available");

    // Pet sahiplik kontrolu
    const pet = await Pet.findOne({ _id: petId, ownerId: petOwnerId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    // Fiyat hesapla
    const serviceInfo = sitter.services.find(s => s.type === serviceType);
    if (!serviceInfo) return sendError(res, 400, "Bakici bu hizmeti sunmuyor", "service_not_offered");

    // E-2: Fiyat tanımlı değilse hata dön
    if (!serviceInfo.pricePerDay && !serviceInfo.pricePerHour) {
      return sendError(res, 400, "Bu hizmet icin fiyat tanimlanmamis", "invalid_service_price");
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    if (end <= start) return sendError(res, 400, "Bitis tarihi baslangictan once olamaz", "invalid_dates");

    const hours = Math.ceil((end - start) / (1000 * 60 * 60));
    const days = Math.ceil(hours / 24);
    const totalPrice = days >= 1 && serviceInfo.pricePerDay > 0
      ? days * serviceInfo.pricePerDay
      : hours * (serviceInfo.pricePerHour || 0);

    // Tarih cakisma kontrolu
    const overlap = await SitterBooking.findOne({
      sitterId,
      status: { $in: ["pending", "accepted", "active"] },
      startDate: { $lt: end },
      endDate: { $gt: start },
    });
    if (overlap) return sendError(res, 409, "Bu tarihler icin bakici musait degil", "date_conflict");

    const booking = await SitterBooking.create({
      petOwnerId,
      sitterId,
      sitterUserId: sitter.userId,
      petId,
      serviceType,
      startDate: start,
      endDate: end,
      totalPrice,
      notes,
      earnings: {
        status: "pending",
        totalPausedMs: 0,
        payableAmount: totalPrice,
      },
    });

    // Socket bildirim - bakiciya
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${sitter.userId}`).emit("sitter:new_booking", {
        bookingId: booking.id,
        ownerName: req.user.name || "Pet sahibi",
        petName: pet.name,
        serviceType,
        serviceLabel: SERVICE_LABELS[serviceType],
        startDate,
        endDate,
        totalPrice,
      });
    }

    // FCM push - bakiciya
    sendPush([String(sitter.userId)], {
      title: "Yeni Rezervasyon",
      body: `${SERVICE_LABELS[serviceType] || serviceType} rezervasyon istegi aldınız`,
      data: {
        type: "sitter_booking",
        bookingId: String(booking._id),
        petName: pet.name,
        serviceType,
      },
    }).catch(() => {});

    await recordAudit("sitter_booking.create", {
      userId: petOwnerId,
      entityType: "SitterBooking",
      entityId: booking.id,
    });

    return sendOk(res, 201, { booking });
  } catch (err) {
    console.error("[SitterBooking] create error:", err.message);
    return sendError(res, 500, "Rezervasyon olusturulamadi", "create_error");
  }
}

// GET /me - Benim rezervasyonlarim (sahip olarak)
export async function myBookings(req, res) {
  try {
    const petOwnerId = req.user.sub;
    const bookings = await SitterBooking.find({ petOwnerId })
      .sort({ createdAt: -1 })
      .populate("sitterId", "displayName avatar rating")
      .populate("petId", "name species photos images")
      .lean();

    return sendOk(res, 200, { bookings: bookings.map(b => ({ ...b, id: b._id })) });
  } catch (err) {
    return sendError(res, 500, "Rezervasyonlar alinamadi", "list_error");
  }
}

// GET /incoming - Gelen rezervasyonlar (bakici olarak)
export async function incomingBookings(req, res) {
  try {
    const sitterUserId = req.user.sub;
    const bookings = await SitterBooking.find({ sitterUserId })
      .sort({ createdAt: -1 })
      .populate("petOwnerId", "name avatarUrl")
      .populate("petId", "name species photos images")
      .lean();

    return sendOk(res, 200, { bookings: bookings.map(b => ({ ...b, id: b._id })) });
  } catch (err) {
    return sendError(res, 500, "Rezervasyonlar alinamadi", "list_error");
  }
}

// GET /:id - Detay
export async function getBooking(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const userId = req.user.sub;
    const booking = await SitterBooking.findById(req.params.id)
      .populate("petOwnerId", "name avatarUrl")
      .populate("sitterId", "displayName avatar rating")
      .populate("petId", "name species photos images")
      .lean();

    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadi", "not_found");

    const isOwner = String(booking.petOwnerId?._id) === userId;
    const isSitter = String(booking.sitterUserId) === userId;
    if (!isOwner && !isSitter) return sendError(res, 403, "Yetkiniz yok", "forbidden");

    return sendOk(res, 200, { booking: { ...booking, id: booking._id } });
  } catch (err) {
    return sendError(res, 500, "Rezervasyon alinamadi", "get_error");
  }
}

// PATCH /:id/status - Durum guncelle
export async function updateBookingStatus(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const userId = req.user.sub;
    const { status, review } = req.body;

    if (!["accepted", "active", "rejected", "cancelled", "completed"].includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "invalid_status");
    }

    const booking = await SitterBooking.findById(req.params.id)
      .populate("petOwnerId", "name")
      .populate("sitterId", "displayName");
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadi", "not_found");

    const isOwner = String(booking.petOwnerId?._id || booking.petOwnerId) === userId;
    const isSitter = String(booking.sitterUserId) === userId;

    if (
      booking.status === "completed" &&
      status === "completed" &&
      isOwner &&
      review?.rating &&
      !booking.ownerReview
    ) {
      booking.ownerReview = {
        rating: Math.min(5, Math.max(1, review.rating)),
        comment: review.comment || "",
      };
      await booking.save();
      await _updateSitterRating(booking.sitterId);
      return sendOk(res, 200, { booking });
    }

    // Durum gecis matrisi
    const validTransitions = {
      pending:   ["accepted", "rejected", "cancelled"],
      accepted:  ["active", "cancelled"],
      active:    ["completed", "cancelled"],
      rejected:  [],
      cancelled: [],
      completed: [],
    };
    if (!validTransitions[booking.status]?.includes(status)) {
      return sendError(res, 400, `${booking.status} durumundan ${status} durumuna gecilemez`, "invalid_transition");
    }

    // Yetki kontrolu
    if (["accepted", "active", "rejected", "completed"].includes(status) && !isSitter) {
      return sendError(res, 403, "Sadece bakici bu islemi yapabilir", "forbidden");
    }
    if (status === "cancelled" && !isOwner) {
      return sendError(res, 403, "Sadece sahip iptal edebilir", "forbidden");
    }
    if (status === "cancelled") {
      cancelTrackingGrace(booking.id);
      booking.status = status;
      booking.liveTracking = {
        ...(booking.liveTracking?.toObject?.() ?? booking.liveTracking ?? {}),
        isActive: false,
        required: false,
        interruptedAt: undefined,
        graceEndsAt: undefined,
      };
      booking.earnings = {
        ...(booking.earnings?.toObject?.() ?? booking.earnings ?? {}),
        status: "paused",
        pausedAt: new Date(),
        pauseReason: "booking_cancelled",
        payableAmount: 0,
      };
    } else if (status === "accepted") {
      booking.status = status;
      booking.respondedAt = new Date();
      booking.earnings = {
        ...(booking.earnings?.toObject?.() ?? booking.earnings ?? {}),
        status: "pending",
        payableAmount: computePayableAmount(booking),
      };
    } else if (status === "active") {
      cancelTrackingGrace(booking.id);
      markServiceStarted(booking, { now: new Date() });
    } else if (status === "completed") {
      cancelTrackingGrace(booking.id);
      markServiceCompleted(booking, { now: new Date() });
      if (review?.rating) {
        booking.ownerReview = {
          rating: Math.min(5, Math.max(1, review.rating)),
          comment: review.comment || "",
        };
      }
    } else {
      booking.status = status;
      if (status === "rejected") booking.respondedAt = new Date();
    }

    await booking.save();
    if (status === "completed") {
      await _updateSitterRating(booking.sitterId);
    }

    // Socket bildirim
    const io = req.app.get("io");
    if (io) {
      const targetUserId = isSitter
        ? String(booking.petOwnerId?._id || booking.petOwnerId)
        : String(booking.sitterUserId);
      io.to(`user:${targetUserId}`).emit("sitter:booking_update", {
        bookingId: booking.id,
        status,
        serviceType: booking.serviceType,
        serviceLabel: SERVICE_LABELS[booking.serviceType] || booking.serviceType,
        sitterName: booking.sitterId?.displayName || "Bakici",
        ownerName: booking.petOwnerId?.name || "Pet sahibi",
        liveTrackingActive: booking.liveTracking?.isActive === true,
        earningsStatus: booking.earnings?.status || "pending",
        payableAmount: booking.earnings?.payableAmount ?? booking.totalPrice,
      });
      if (status === "active") {
        io.to(`user:${targetUserId}`).emit("sitter:walk_started", {
          bookingId: booking.id,
          startedAt: Date.now(),
        });
      }
      if (status === "completed") {
        io.to(`user:${targetUserId}`).emit("sitter:walk_ended", {
          bookingId: booking.id,
          endedAt: Date.now(),
        });
      }
    }

    // FCM push - karsi tarafa
    {
      const targetUserId = isSitter
        ? String(booking.petOwnerId?._id || booking.petOwnerId)
        : String(booking.sitterUserId);
      const statusLabels = {
        accepted: "Rezervasyonunuz kabul edildi",
        active: "Bakici kopegi teslim aldi. Canli konum acildi",
        rejected: "Rezervasyonunuz reddedildi",
        cancelled: "Rezervasyon iptal edildi",
        completed: "Rezervasyon tamamlandi",
      };
      sendPush([targetUserId], {
        title: "Rezervasyon Guncellendi",
        body: statusLabels[status] || `Durum: ${status}`,
        data: {
          type: "sitter_booking_update",
          bookingId: String(booking._id),
          status,
          serviceType: booking.serviceType,
        },
      }).catch(() => {});
    }

    // N-3: Bakım tamamlandığında pet sahibine email
    if (status === "completed") {
      const petOwner = await User.findById(booking.petOwnerId).select("email name");
      if (petOwner?.email) {
        const sitterLabel = SERVICE_LABELS[booking.serviceType] || booking.serviceType;
        const startStr = new Date(booking.startDate).toLocaleDateString("tr-TR", {
          day: "2-digit", month: "long", year: "numeric",
        });
        sendEmail(
          petOwner.email,
          "Bakım Hizmeti Tamamlandı ✓",
          `<h2>Bakım hizmetiniz tamamlandı!</h2>
           <p>Merhaba ${petOwner.name},</p>
           <p><strong>Hizmet:</strong> ${sitterLabel}</p>
           <p><strong>Tarih:</strong> ${startStr}</p>
           <p>Bakıcınızı değerlendirmek için uygulamayı ziyaret edebilirsiniz.</p>`
        ).catch(() => {});
      }
    }

    await recordAudit("sitter_booking.status", {
      userId,
      entityType: "SitterBooking",
      entityId: booking.id,
      metadata: { status },
    });

    return sendOk(res, 200, { booking });
  } catch (err) {
    console.error("[SitterBooking] status error:", err.message);
    return sendError(res, 500, "Durum guncellenemedi", "status_error");
  }
}

async function _updateSitterRating(sitterId) {
  const bookings = await SitterBooking.find({
    sitterId,
    status: "completed",
    ownerReview: { $exists: true },
  }).lean();

  if (bookings.length === 0) return;

  const total = bookings.reduce((sum, b) => sum + (b.ownerReview?.rating || 0), 0);
  const avg = Number((total / bookings.length).toFixed(1));

  await PetSitter.findByIdAndUpdate(sitterId, {
    rating: avg,
    reviewCount: bookings.length,
  });
}
