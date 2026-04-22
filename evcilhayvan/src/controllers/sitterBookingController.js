import { validationResult } from "express-validator";
import mongoose from "mongoose";
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

function normalizeReviewPayload(review) {
  if (!review || review.rating === undefined || review.rating === null) {
    return null;
  }

  const rating = Number(review.rating);
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    throw new Error("Gecerli bir puan girin (1-5)");
  }

  return {
    rating: Math.min(5, Math.max(1, rating)),
    comment: String(review.comment || "").trim().slice(0, 1000),
    createdAt: new Date(),
  };
}

function getMonthKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function getDateKey(date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

function buildSeriesMap(startDate, length, keyBuilder) {
  const map = new Map();
  for (let index = 0; index < length; index += 1) {
    const cursor = new Date(startDate);
    keyBuilder.advance(cursor, index);
    const key = keyBuilder.key(cursor);
    map.set(key, {
      key,
      label: keyBuilder.label(cursor),
      revenue: 0,
      bookings: 0,
    });
  }
  return map;
}

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

// GET /financial-summary - bakici finansal ozeti
export async function getMyFinancialSummary(req, res) {
  try {
    const sitterUserId = req.user.sub;
    const sitterUserObjectId = new mongoose.Types.ObjectId(sitterUserId);
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    monthStart.setHours(0, 0, 0, 0);

    const dailyStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 13);
    dailyStart.setHours(0, 0, 0, 0);

    const monthlyStart = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    monthlyStart.setHours(0, 0, 0, 0);

    const basePipeline = [
      { $match: { sitterUserId: sitterUserObjectId } },
      {
        $addFields: {
          payoutAmount: { $ifNull: ["$earnings.payableAmount", "$totalPrice"] },
          settledAt: { $ifNull: ["$completedAt", "$endDate"] },
        },
      },
    ];

    const [statsRaw, dailyTrendRaw, monthlyTrendRaw, serviceBreakdownRaw, recentCompleted] =
      await Promise.all([
        SitterBooking.aggregate([
          ...basePipeline,
          {
            $group: {
              _id: null,
              totalBookings: { $sum: 1 },
              pendingBookings: {
                $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] },
              },
              acceptedBookings: {
                $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] },
              },
              activeBookings: {
                $sum: { $cond: [{ $eq: ["$status", "active"] }, 1, 0] },
              },
              completedBookings: {
                $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] },
              },
              cancelledBookings: {
                $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] },
              },
              pausedBookings: {
                $sum: {
                  $cond: [{ $eq: ["$earnings.status", "paused"] }, 1, 0],
                },
              },
              totalRevenue: {
                $sum: {
                  $cond: [{ $eq: ["$status", "completed"] }, "$payoutAmount", 0],
                },
              },
              thisMonthRevenue: {
                $sum: {
                  $cond: [
                    {
                      $and: [
                        { $eq: ["$status", "completed"] },
                        { $gte: ["$settledAt", monthStart] },
                      ],
                    },
                    "$payoutAmount",
                    0,
                  ],
                },
              },
              pipelineRevenue: {
                $sum: {
                  $cond: [
                    { $in: ["$status", ["accepted", "active"]] },
                    "$payoutAmount",
                    0,
                  ],
                },
              },
              pausedRevenue: {
                $sum: {
                  $cond: [
                    { $eq: ["$earnings.status", "paused"] },
                    "$payoutAmount",
                    0,
                  ],
                },
              },
            },
          },
        ]),
        SitterBooking.aggregate([
          ...basePipeline,
          {
            $match: {
              status: "completed",
              settledAt: { $gte: dailyStart },
            },
          },
          {
            $group: {
              _id: {
                $dateToString: {
                  format: "%Y-%m-%d",
                  date: "$settledAt",
                  timezone: "Europe/Istanbul",
                },
              },
              revenue: { $sum: "$payoutAmount" },
              bookings: { $sum: 1 },
            },
          },
          { $sort: { _id: 1 } },
        ]),
        SitterBooking.aggregate([
          ...basePipeline,
          {
            $match: {
              status: "completed",
              settledAt: { $gte: monthlyStart },
            },
          },
          {
            $group: {
              _id: {
                $dateToString: {
                  format: "%Y-%m",
                  date: "$settledAt",
                  timezone: "Europe/Istanbul",
                },
              },
              revenue: { $sum: "$payoutAmount" },
              bookings: { $sum: 1 },
            },
          },
          { $sort: { _id: 1 } },
        ]),
        SitterBooking.aggregate([
          ...basePipeline,
          { $match: { status: "completed" } },
          {
            $group: {
              _id: "$serviceType",
              revenue: { $sum: "$payoutAmount" },
              bookings: { $sum: 1 },
            },
          },
          { $sort: { revenue: -1 } },
        ]),
        SitterBooking.find({
          sitterUserId,
          status: "completed",
        })
          .sort({ completedAt: -1, endDate: -1 })
          .limit(5)
          .populate("petOwnerId", "name")
          .populate("petId", "name")
          .lean(),
      ]);

    const stats = statsRaw?.[0] || {};

    const dailySeries = buildSeriesMap(dailyStart, 14, {
      advance: (date, index) => date.setDate(date.getDate() + index),
      key: (date) => getDateKey(date),
      label: (date) => `${String(date.getDate()).padStart(2, "0")}/${String(date.getMonth() + 1).padStart(2, "0")}`,
    });
    for (const item of dailyTrendRaw || []) {
      if (!dailySeries.has(item._id)) continue;
      dailySeries.set(item._id, {
        ...dailySeries.get(item._id),
        revenue: Math.round((item.revenue || 0) * 100) / 100,
        bookings: item.bookings || 0,
      });
    }

    const monthlySeries = buildSeriesMap(monthlyStart, 6, {
      advance: (date, index) => date.setMonth(date.getMonth() + index),
      key: (date) => getMonthKey(date),
      label: (date) => `${String(date.getMonth() + 1).padStart(2, "0")}/${date.getFullYear()}`,
    });
    for (const item of monthlyTrendRaw || []) {
      if (!monthlySeries.has(item._id)) continue;
      monthlySeries.set(item._id, {
        ...monthlySeries.get(item._id),
        revenue: Math.round((item.revenue || 0) * 100) / 100,
        bookings: item.bookings || 0,
      });
    }

    return sendOk(res, 200, {
      summary: {
        totalRevenue: Math.round((stats.totalRevenue || 0) * 100) / 100,
        thisMonthRevenue: Math.round((stats.thisMonthRevenue || 0) * 100) / 100,
        pipelineRevenue: Math.round((stats.pipelineRevenue || 0) * 100) / 100,
        pausedRevenue: Math.round((stats.pausedRevenue || 0) * 100) / 100,
        totalBookings: stats.totalBookings || 0,
        pendingBookings: stats.pendingBookings || 0,
        acceptedBookings: stats.acceptedBookings || 0,
        activeBookings: stats.activeBookings || 0,
        completedBookings: stats.completedBookings || 0,
        cancelledBookings: stats.cancelledBookings || 0,
        pausedBookings: stats.pausedBookings || 0,
      },
      dailyTrend: [...dailySeries.values()],
      monthlyTrend: [...monthlySeries.values()],
      serviceBreakdown: (serviceBreakdownRaw || []).map((item) => ({
        serviceType: item._id,
        serviceLabel: SERVICE_LABELS[item._id] || item._id,
        revenue: Math.round((item.revenue || 0) * 100) / 100,
        bookings: item.bookings || 0,
      })),
      recentCompleted: recentCompleted.map((booking) => ({
        id: booking._id,
        serviceType: booking.serviceType,
        serviceLabel: SERVICE_LABELS[booking.serviceType] || booking.serviceType,
        revenue: Math.round(((booking.earnings?.payableAmount ?? booking.totalPrice) || 0) * 100) / 100,
        completedAt: booking.completedAt || booking.endDate,
        ownerName: booking.petOwnerId?.name || "Musteri",
        petName: booking.petId?.name || "Pet",
      })),
    });
  } catch (err) {
    console.error("[SitterBooking] financial summary error:", err.message);
    return sendError(res, 500, "Finansal ozet alinamadi", "financial_summary_error");
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

    let normalizedReview = null;
    try {
      normalizedReview = normalizeReviewPayload(review);
    } catch (reviewError) {
      return sendError(res, 400, reviewError.message, "validation_error");
    }

    if (booking.status === "completed" && status === "completed" && normalizedReview) {
      if (isOwner) {
        if (booking.ownerReview) {
          return sendError(res, 409, "Bakici icin zaten yorum biraktiniz", "duplicate_review");
        }
        booking.ownerReview = normalizedReview;
        await booking.save();
        await _updateSitterRating(booking.sitterId);
        sendPush([String(booking.sitterUserId)], {
          title: "Yeni Bakici Degerlendirmesi",
          body: `${booking.petOwnerId?.name || "Musteri"} sizin icin yorum birakti.`,
          data: {
            type: "sitter_owner_review",
            bookingId: String(booking._id),
          },
        }).catch(() => {});
        return sendOk(res, 200, { booking });
      }

      if (isSitter) {
        if (booking.sitterReview) {
          return sendError(res, 409, "Bu musteri icin zaten degerlendirme yaptiniz", "duplicate_review");
        }
        booking.sitterReview = normalizedReview;
        await booking.save();
        sendPush([String(booking.petOwnerId?._id || booking.petOwnerId)], {
          title: "Yeni Musteri Degerlendirmesi",
          body: `${booking.sitterId?.displayName || "Bakici"} sizin icin bir degerlendirme birakti.`,
          data: {
            type: "sitter_review_received",
            bookingId: String(booking._id),
          },
        }).catch(() => {});
        return sendOk(res, 200, { booking });
      }
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
      if (normalizedReview && isSitter && !booking.sitterReview) {
        booking.sitterReview = normalizedReview;
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
