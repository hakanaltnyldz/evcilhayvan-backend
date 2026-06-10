import { validationResult } from "express-validator";
import mongoose from "mongoose";
import Appointment from "../models/Appointment.js";
import Prescription from "../models/Prescription.js";
import Veterinary from "../models/Veterinary.js";
import Pet from "../models/Pet.js";
import User from "../models/User.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import { sendEmail } from "../utils/mail.js";
import { sendPush } from "../utils/fcm.js";
import { awardPoints } from "../utils/points.js";

const DEFAULT_APPOINTMENT_SLOT_MINUTES = 30;

function getAppointmentSlotMinutes(vet) {
  const slotMinutes = Number(vet?.appointmentSlotMinutes);
  return Number.isFinite(slotMinutes) && slotMinutes > 0
    ? slotMinutes
    : DEFAULT_APPOINTMENT_SLOT_MINUTES;
}

function getDateKey(date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

function parseTimeWindow(open, close) {
  if (!open || !close) return null;

  const [openH, openM] = String(open).split(":").map(Number);
  const [closeH, closeM] = String(close).split(":").map(Number);

  if ([openH, openM, closeH, closeM].some((value) => Number.isNaN(value))) {
    return null;
  }

  return { openH, openM, closeH, closeM };
}

function getAvailabilityOverride(vet, targetDate) {
  const overrides = Array.isArray(vet?.availabilityOverrides)
    ? vet.availabilityOverrides
    : [];
  const targetKey = getDateKey(targetDate);

  return (
    overrides.find((item) => {
      if (!item?.date) return false;
      return getDateKey(new Date(item.date)) === targetKey;
    }) || null
  );
}

function getWorkingWindow(vet, targetDate) {
  const availabilityOverride = getAvailabilityOverride(vet, targetDate);
  if (availabilityOverride?.isClosed) {
    return { isAvailable: false };
  }

  const overrideWindow = parseTimeWindow(
    availabilityOverride?.open,
    availabilityOverride?.close
  );
  if (overrideWindow) {
    return { isAvailable: true, ...overrideWindow };
  }

  const jsDay = targetDate.getDay();
  const dayIndex = jsDay === 0 ? 6 : jsDay - 1;
  const workingHours = Array.isArray(vet?.workingHours) ? vet.workingHours : [];

  if (workingHours.length === 0) {
    return { isAvailable: true, openH: 9, openM: 0, closeH: 18, closeM: 0 };
  }

  const hours = workingHours.find((wh) => wh.day === dayIndex);
  if (!hours || hours.isClosed || !hours.open || !hours.close) {
    return { isAvailable: false };
  }

  const parsedWindow = parseTimeWindow(hours.open, hours.close);
  if (!parsedWindow) {
    return { isAvailable: false };
  }

  return { isAvailable: true, ...parsedWindow };
}

function formatMinutes(minutes) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}`;
}

function getAppointmentViewerRole(user, appointment) {
  const currentUserId = String(user?.sub || "");
  const ownerId = String(appointment?.userId?._id || appointment?.userId || "");
  const vetUserId = String(appointment?.veterinaryId?.userId || "");
  const registeredById = String(appointment?.veterinaryId?.registeredBy || "");

  if (user?.role === "admin") return "admin";
  if (currentUserId && ownerId === currentUserId) return "owner";
  if (currentUserId && vetUserId && vetUserId === currentUserId) return "vet";
  if (currentUserId && registeredById && registeredById === currentUserId) return "vet";
  return null;
}

function getAppointmentStatusLabel(status) {
  switch (status) {
    case "pending":
      return "Beklemede";
    case "confirmed":
      return "Onaylandi";
    case "cancelled":
      return "Iptal edildi";
    case "completed":
      return "Tamamlandi";
    case "no_show":
      return "Gelmedi";
    default:
      return status;
  }
}

async function loadAppointmentWithRelations(id) {
  return Appointment.findById(id)
    .populate("userId", "name avatarUrl email phone")
    .populate("petId", "name species photos")
    .populate(
      "veterinaryId",
      "name address phone email photos workingHours availabilityOverrides userId registeredBy appointmentSlotMinutes clinicConsultationFee onlineConsultationFee"
    );
}

async function emitAppointmentNotification({
  appointment,
  eventName,
  socketPayload,
  title,
  body,
  pushType,
  excludeUserId = null,
}) {
  const ownerId = String(appointment?.userId?._id || appointment?.userId || "");
  const vetUserId = String(appointment?.veterinaryId?.userId || "");
  const registeredById = String(appointment?.veterinaryId?.registeredBy || "");

  const recipients = [...new Set([ownerId, vetUserId || registeredById].filter(Boolean))].filter(
    (id) => !excludeUserId || String(id) !== String(excludeUserId)
  );

  if (!recipients.length) return;

  const socket = await getIo();
  if (socket?.to) {
    recipients.forEach((userId) => {
      socket.to(`user:${userId}`).emit(eventName, socketPayload);
    });
  }

  await sendPush(recipients, {
    title,
    body,
    data: {
      type: pushType,
      appointmentId: String(appointment._id),
      ...(socketPayload || {}),
    },
  }).catch(() => {});
}

async function ensureAppointmentSlotAvailable({
  veterinaryId,
  appointmentDate,
  endDate,
  excludeAppointmentId = null,
}) {
  const query = {
    veterinaryId,
    status: { $in: ["pending", "confirmed"] },
    date: { $lt: endDate },
    endDate: { $gt: appointmentDate },
  };

  if (excludeAppointmentId && mongoose.Types.ObjectId.isValid(excludeAppointmentId)) {
    query._id = { $ne: excludeAppointmentId };
  }

  return Appointment.findOne(query);
}

function parseFutureAppointmentDate(value) {
  const appointmentDate = new Date(value);
  if (Number.isNaN(appointmentDate.getTime())) {
    return { error: "Gecersiz randevu tarihi" };
  }
  if (appointmentDate <= new Date()) {
    return { error: "Randevu tarihi gelecekte olmali" };
  }
  return { appointmentDate };
}

function validateAppointmentWindow(vet, appointmentDate) {
  const workingWindow = getWorkingWindow(vet, appointmentDate);
  if (!workingWindow.isAvailable) {
    return { error: "Bu gun icin randevu kabul edilmiyor", code: "outside_working_hours" };
  }

  const { openH, openM, closeH, closeM } = workingWindow;
  const slotMinutes = getAppointmentSlotMinutes(vet);
  const appointmentMinutes = appointmentDate.getHours() * 60 + appointmentDate.getMinutes();

  if (
    appointmentMinutes < openH * 60 + openM ||
    appointmentMinutes + slotMinutes > closeH * 60 + closeM
  ) {
    return { error: "Randevu calisma saatleri disinda", code: "outside_working_hours" };
  }

  return { slotMinutes, workingWindow };
}

function normalizeMedications(input) {
  if (!Array.isArray(input)) return [];

  return input
    .map((item) => ({
      name: item?.name?.toString().trim() || "",
      dosage: item?.dosage?.toString().trim() || "",
      frequency: item?.frequency?.toString().trim() || "",
      durationDays: Number(item?.durationDays) || null,
      instructions: item?.instructions?.toString().trim() || "",
    }))
    .filter((item) => item.name);
}

function getAppointmentFee(vet, type) {
  const clinicFee = Math.max(0, Number(vet?.clinicConsultationFee) || 0);
  const onlineFee = Math.max(0, Number(vet?.onlineConsultationFee) || 0);
  return type === "online" ? onlineFee || clinicFee : clinicFee;
}

function managedVetFilter(userId) {
  return {
    isActive: true,
    $or: [
      { userId },
      { registeredBy: userId },
    ],
  };
}

async function findManagedVetByUser(userId, projection = null) {
  const query = Veterinary.findOne(managedVetFilter(userId)).sort({ updatedAt: -1 });
  if (projection) query.select(projection);
  return query;
}

function normalizeOptionalText(value, maxLength = 2000) {
  if (value === undefined) return undefined;
  const trimmed = String(value ?? "").trim();
  if (!trimmed) return "";
  return trimmed.slice(0, maxLength);
}

function parseOptionalDate(value) {
  if (value === undefined) return undefined;
  if (value === null || value === "") return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new Error("Gecersiz tarih");
  }
  return parsed;
}

async function getIo() {
  try {
    const server = await import("../../server.js");
    return server.io || null;
  } catch {
    return null;
  }
}

// POST /api/appointments
export async function createAppointment(req, res) {
  try {
    const userId = req.user.sub;
    const { petId, veterinaryId, date, reason, notes, type = 'clinic' } = req.body;

    if (!petId || !veterinaryId || !date) {
      return sendError(res, 400, "petId, veterinaryId ve date gerekli", "validation_error");
    }

    const pet = await Pet.findOne({ _id: petId, ownerId: userId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    const vet = await Veterinary.findById(veterinaryId);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    if (vet.userId && String(vet.userId) === String(userId)) {
      return sendError(res, 403, "Kendi kliniginize randevu alamazsiniz", "own_vet_forbidden");
    }

    const { appointmentDate, error: dateError } = parseFutureAppointmentDate(date);
    if (dateError) {
      return sendError(res, 400, dateError, "validation_error");
    }

    const { slotMinutes, error: windowError, code } = validateAppointmentWindow(vet, appointmentDate);
    if (windowError) {
      return sendError(res, 400, windowError, code);
    }

    const endDate = new Date(appointmentDate.getTime() + slotMinutes * 60000);
    const conflict = await ensureAppointmentSlotAvailable({
      veterinaryId,
      appointmentDate,
      endDate,
    });

    if (conflict) {
      return sendError(res, 409, "Bu saat dilimi dolu", "slot_conflict");
    }

    const appointmentType = ['clinic', 'online'].includes(type) ? type : 'clinic';
    if (appointmentType === "online" && vet.acceptsOnlineAppointments !== true) {
      return sendError(res, 400, "Bu klinik online randevu kabul etmiyor", "online_not_available");
    }

    const feeAmount = getAppointmentFee(vet, appointmentType);
    const meetingUrl = appointmentType === 'online'
      ? null // Onaylanınca üretilecek
      : null;

    const appointment = await Appointment.create({
      userId,
      petId,
      veterinaryId,
      date: appointmentDate,
      endDate,
      reason: reason || "",
      notes: notes || "",
      status: "pending",
      type: appointmentType,
      meetingUrl,
      feeAmount,
    });

    const populated = await loadAppointmentWithRelations(appointment._id);

    await recordAudit("appointment.create", {
      userId,
      entityType: "appointment",
      entityId: appointment._id.toString(),
    });

    // N-1: Veterinere push bildirimi + socket (vet zaten yukarıda yüklendi)
    const vetNotificationUserId = vet?.userId || vet?.registeredBy;
    if (vetNotificationUserId) {
      const petName = populated.petId?.name || "Evcil hayvan";
      sendPush([String(vetNotificationUserId)], {
        title: "Yeni Randevu Talebi",
        body: `${petName} için yeni bir randevu talebi aldınız.`,
        data: { type: "appointment", appointmentId: appointment._id.toString() },
      }).catch(() => {});
      const socket = await getIo();
      if (socket?.to) {
        socket.to(`user:${String(vetNotificationUserId)}`).emit("appointment:new", {
          appointmentId: appointment._id,
          petName,
          date: appointment.date,
        });
      }
    }

    awardPoints(userId, 10).catch(() => {});
    return sendOk(res, 201, { appointment: populated });
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 409, "Bu saat dilimi dolu", "slot_conflict");
    }
    console.error("[createAppointment]", err);
    return sendError(res, 500, "Randevu olusturulamadi", "internal_error", err.message);
  }
}

// GET /api/appointments/me
export async function getMyAppointments(req, res) {
  try {
    const userId = req.user.sub;
    const { status, petId, page = 1, limit = 20 } = req.query;
    const filter = {};

    if (req.user.role === "vet") {
      const vetIds = await Veterinary.find(managedVetFilter(userId)).distinct("_id");
      filter.veterinaryId = { $in: vetIds };
    } else {
      filter.userId = userId;
    }

    if (status) filter.status = status;
    if (petId) filter.petId = petId;

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Appointment.find(filter)
        .populate("userId", "name avatarUrl")
        .populate("petId", "name species photos")
        .populate("veterinaryId", "name address phone photos userId")
        .sort({ date: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Appointment.countDocuments(filter),
    ]);

    return sendOk(res, 200, {
      appointments: items,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + items.length < total,
    });
  } catch (err) {
    console.error("[getMyAppointments]", err);
    return sendError(res, 500, "Randevular yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/appointments/vet-schedule  — veteriner kliniğine gelen randevular
export async function getVetSchedule(req, res) {
  try {
    const userId = req.user.sub;
    const { status, date, page = 1, limit = 50 } = req.query;

    // Kullanıcının sahip olduğu kliniği bul
    const vet = await findManagedVetByUser(userId);
    if (!vet) {
      return sendError(res, 404, "Klinik bulunamadi veya size ait degil", "vet_not_found");
    }

    const filter = { veterinaryId: vet._id };
    if (status) filter.status = status;
    if (date) {
      const d = new Date(date);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);
      filter.date = { $gte: d, $lt: next };
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Appointment.find(filter)
        .populate("userId", "name avatarUrl email phone")
        .populate("petId", "name species photos")
        .sort({ date: 1 })
        .skip(skip)
        .limit(Number(limit)),
      Appointment.countDocuments(filter),
    ]);

    return sendOk(res, 200, {
      appointments: items,
      vetName: vet.name,
      vetId: vet._id,
      total,
      page: Number(page),
      hasMore: skip + items.length < total,
    });
  } catch (err) {
    console.error("[getVetSchedule]", err);
    return sendError(res, 500, "Klinik randevulari yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/appointments/:id
export async function getAppointment(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const appointment = await loadAppointmentWithRelations(req.params.id);

    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!viewerRole) {
      return sendError(res, 403, "Bu randevuyu gorme yetkiniz yok", "forbidden");
    }

    return sendOk(res, 200, { appointment });
  } catch (err) {
    console.error("[getAppointment]", err);
    return sendError(res, 500, "Randevu detayi alinamadi", "internal_error", err.message);
  }
}

// PATCH /api/appointments/:id/status
export async function updateAppointmentStatus(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const userId = req.user.sub;
    const { id } = req.params;
    const { status, cancelReason, vetNotes, meetingUrl } = req.body;

    const validStatuses = ["confirmed", "cancelled", "completed", "no_show"];
    if (!validStatuses.includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "validation_error");
    }

    const appointment = await loadAppointmentWithRelations(id);
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!viewerRole) {
      return sendError(res, 403, "Bu randevuyu guncelleme yetkiniz yok", "forbidden");
    }

    if (viewerRole === "owner" && status !== "cancelled") {
      return sendError(res, 403, "Sahip tarafinda sadece iptal islemi yapilabilir", "forbidden");
    }

    if (vetNotes !== undefined && !["vet", "admin"].includes(viewerRole)) {
      return sendError(res, 403, "Veteriner notu ekleme yetkiniz yok", "forbidden");
    }
    if (meetingUrl !== undefined && !["vet", "admin"].includes(viewerRole)) {
      return sendError(res, 403, "Gorusme linki ekleme yetkiniz yok", "forbidden");
    }

    const validTransitions = {
      pending: ["confirmed", "cancelled"],
      confirmed: ["cancelled", "completed", "no_show"],
      cancelled: [],
      completed: [],
      no_show: [],
    };

    if (!validTransitions[appointment.status]?.includes(status)) {
      return sendError(
        res,
        400,
        `${appointment.status} durumundan ${status} durumuna gecilemez`,
        "invalid_transition"
      );
    }

    appointment.status = status;
    if (status === "cancelled") {
      appointment.cancelledBy = userId;
      appointment.cancelReason = cancelReason || "";
      appointment.completedAt = undefined;
    }
    if (status === "confirmed" && meetingUrl !== undefined) {
      if (appointment.type !== "online") {
        return sendError(res, 400, "Sadece online randevuya gorusme linki eklenebilir", "validation_error");
      }
      const normalizedMeetingUrl = normalizeOptionalText(meetingUrl, 500);
      if (normalizedMeetingUrl) {
        try {
          const parsedMeetingUrl = new URL(normalizedMeetingUrl);
          if (!["http:", "https:"].includes(parsedMeetingUrl.protocol)) {
            return sendError(res, 400, "Gorusme linki http veya https olmali", "validation_error");
          }
          appointment.meetingUrl = normalizedMeetingUrl;
        } catch {
          return sendError(res, 400, "Gorusme linki gecersiz", "validation_error");
        }
      } else {
        appointment.meetingUrl = null;
      }
    }
    if (status === "completed") {
      appointment.completedAt = new Date();
    }
    if (status === "no_show") {
      appointment.completedAt = undefined;
    }
    if (vetNotes !== undefined) {
      appointment.vetNotes = normalizeOptionalText(vetNotes) || "";
      appointment.clinicalRecordUpdatedAt = new Date();
    }
    await appointment.save();

    // Socket.io bildirimi
    const socket = await getIo();
    if (socket?.to) {
      socket.to(`user:${String(appointment.userId)}`).emit("appointment:updated", {
        appointmentId: appointment._id,
        status,
        veterinaryName: appointment.veterinaryId?.name || "",
        date: appointment.date,
      });
    }
    if (status !== "cancelled") {
      appointment.cancelledBy = appointment.cancelledBy || undefined;
      if (status !== "cancelled") appointment.cancelReason = appointment.cancelReason || "";
    }

    await appointment.save();
    const updatedAppointment = await loadAppointmentWithRelations(id);
    const statusLabel = getAppointmentStatusLabel(status);

    await emitAppointmentNotification({
      appointment: updatedAppointment,
      eventName: "appointment:updated",
      socketPayload: {
        appointmentId: String(updatedAppointment._id),
        status,
        statusLabel,
        veterinaryName: updatedAppointment.veterinaryId?.name || "",
        petName: updatedAppointment.petId?.name || "",
        date: updatedAppointment.date,
        action: "status_changed",
      },
      title: "Randevu Guncellendi",
      body: `${updatedAppointment.veterinaryId?.name || "Veteriner"} randevusu ${statusLabel.toLowerCase()}.`,
      pushType: "appointment_updated",
      excludeUserId: userId,
    });

    // N-2: Kullanıcıya email bildirimi
    const appointmentUser = await User.findById(appointment.userId).select("email name");
    if (appointmentUser?.email) {
      const vetName = appointment.veterinaryId?.name || "Veteriner";
      const dateStr = new Date(appointment.date).toLocaleString("tr-TR", {
        day: "2-digit", month: "long", year: "numeric",
        hour: "2-digit", minute: "2-digit",
      });
      if (status === "confirmed") {
        const meetingLine = appointment.meetingUrl
          ? `<p><strong>🎥 Video Bağlantısı:</strong> <a href="${appointment.meetingUrl}">${appointment.meetingUrl}</a></p>`
          : '';
        sendEmail(
          appointmentUser.email,
          "Randevunuz Onaylandı ✓",
          `<h2>Randevunuz onaylandı!</h2>
           <p>Merhaba ${appointmentUser.name},</p>
           <p><strong>Veteriner:</strong> ${vetName}</p>
           <p><strong>Tarih:</strong> ${dateStr}</p>
           ${meetingLine}
           <p>Randevunuzu zamanında iptal etmek isterseniz uygulamamızı kullanabilirsiniz.</p>`
        ).catch(() => {});
      } else if (status === "cancelled") {
        sendEmail(
          appointmentUser.email,
          "Randevunuz İptal Edildi",
          `<h2>Randevunuz iptal edildi.</h2>
           <p>Merhaba ${appointmentUser.name},</p>
           <p><strong>Veteriner:</strong> ${vetName}</p>
           <p><strong>Tarih:</strong> ${dateStr}</p>
           ${cancelReason ? `<p><strong>Neden:</strong> ${cancelReason}</p>` : ""}
           <p>Yeni bir randevu oluşturmak için uygulamamızı kullanabilirsiniz.</p>`
        ).catch(() => {});
      }
    }

    await recordAudit("appointment.status_update", {
      userId,
      entityType: "appointment",
      entityId: id,
      metadata: { newStatus: status },
    });

    return sendOk(res, 200, { appointment: updatedAppointment });
  } catch (err) {
    console.error("[updateAppointmentStatus]", err);
    return sendError(res, 500, "Randevu durumu guncellenemedi", "internal_error", err.message);
  }
}

// PATCH /api/appointments/:id/reschedule
export async function rescheduleAppointment(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const userId = req.user.sub;
    const { id } = req.params;
    const { date, reason } = req.body;

    if (!date) {
      return sendError(res, 400, "Yeni randevu tarihi gerekli", "validation_error");
    }

    const appointment = await loadAppointmentWithRelations(id);
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!viewerRole) {
      return sendError(res, 403, "Bu randevuyu yeniden planlama yetkiniz yok", "forbidden");
    }

    if (["cancelled", "completed", "no_show"].includes(appointment.status)) {
      return sendError(res, 400, "Bu randevu yeniden planlanamaz", "invalid_status");
    }

    const { appointmentDate, error: dateError } = parseFutureAppointmentDate(date);
    if (dateError) {
      return sendError(res, 400, dateError, "validation_error");
    }

    const vet = await Veterinary.findById(appointment.veterinaryId?._id || appointment.veterinaryId);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    const { slotMinutes, error: windowError, code } = validateAppointmentWindow(vet, appointmentDate);
    if (windowError) {
      return sendError(res, 400, windowError, code);
    }

    const endDate = new Date(appointmentDate.getTime() + slotMinutes * 60000);
    const conflict = await ensureAppointmentSlotAvailable({
      veterinaryId: vet._id,
      appointmentDate,
      endDate,
      excludeAppointmentId: appointment._id,
    });

    if (conflict) {
      return sendError(res, 409, "Bu saat dilimi dolu", "slot_conflict");
    }

    appointment.date = appointmentDate;
    appointment.endDate = endDate;
    appointment.rescheduledAt = new Date();
    appointment.rescheduledBy = userId;
    appointment.rescheduleReason = reason?.toString().trim() || "";
    appointment.reminderSent = false;
    appointment.status = viewerRole === "owner" ? "pending" : "confirmed";

    await appointment.save();

    const updatedAppointment = await loadAppointmentWithRelations(id);
    const dateLabel = updatedAppointment.date.toLocaleString("tr-TR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    await emitAppointmentNotification({
      appointment: updatedAppointment,
      eventName: "appointment:updated",
      socketPayload: {
        appointmentId: String(updatedAppointment._id),
        status: updatedAppointment.status,
        statusLabel: getAppointmentStatusLabel(updatedAppointment.status),
        veterinaryName: updatedAppointment.veterinaryId?.name || "",
        petName: updatedAppointment.petId?.name || "",
        date: updatedAppointment.date,
        action: "rescheduled",
        rescheduleReason: updatedAppointment.rescheduleReason || "",
      },
      title: "Randevu Yeniden Planlandi",
      body: `${updatedAppointment.veterinaryId?.name || "Veteriner"} randevusu ${dateLabel} icin guncellendi.`,
      pushType: "appointment_rescheduled",
      excludeUserId: userId,
    });

    await recordAudit("appointment.reschedule", {
      userId,
      entityType: "appointment",
      entityId: id,
      metadata: { newDate: updatedAppointment.date },
    });

    return sendOk(res, 200, { appointment: updatedAppointment });
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 409, "Bu saat dilimi dolu", "slot_conflict");
    }
    console.error("[rescheduleAppointment]", err);
    return sendError(res, 500, "Randevu yeniden planlanamadi", "internal_error", err.message);
  }
}

// PATCH /api/appointments/:id/clinical-record
export async function updateAppointmentClinicalRecord(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const appointment = await loadAppointmentWithRelations(req.params.id);
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!["vet", "admin"].includes(viewerRole || "")) {
      return sendError(res, 403, "Sadece veteriner veya admin klinik kaydi guncelleyebilir", "forbidden");
    }

    if (appointment.status === "cancelled") {
      return sendError(res, 400, "Iptal edilen randevuya klinik kayit eklenemez", "invalid_status");
    }

    const { vetNotes, diagnosis, treatmentSummary, followUpDate, feeAmount } = req.body || {};
    const changedFields = [];

    if (vetNotes !== undefined) {
      appointment.vetNotes = normalizeOptionalText(vetNotes) || "";
      changedFields.push("vetNotes");
    }
    if (diagnosis !== undefined) {
      appointment.diagnosis = normalizeOptionalText(diagnosis, 500) || "";
      changedFields.push("diagnosis");
    }
    if (treatmentSummary !== undefined) {
      appointment.treatmentSummary = normalizeOptionalText(treatmentSummary, 2000) || "";
      changedFields.push("treatmentSummary");
    }
    if (followUpDate !== undefined) {
      const parsedFollowUpDate = parseOptionalDate(followUpDate);
      appointment.followUpDate = parsedFollowUpDate || undefined;
      changedFields.push("followUpDate");
    }
    if (feeAmount !== undefined) {
      const parsedFeeAmount = Number(feeAmount);
      if (!Number.isFinite(parsedFeeAmount) || parsedFeeAmount < 0) {
        return sendError(res, 400, "Ucret tutari gecersiz", "validation_error");
      }
      appointment.feeAmount = Math.round(parsedFeeAmount * 100) / 100;
      changedFields.push("feeAmount");
    }

    if (!changedFields.length) {
      return sendError(res, 400, "Guncellenecek klinik kayit alani bulunamadi", "validation_error");
    }

    appointment.clinicalRecordUpdatedAt = new Date();
    await appointment.save();

    const updatedAppointment = await loadAppointmentWithRelations(req.params.id);

    await emitAppointmentNotification({
      appointment: updatedAppointment,
      eventName: "appointment:clinical_record_updated",
      socketPayload: {
        appointmentId: String(updatedAppointment._id),
        veterinaryName: updatedAppointment.veterinaryId?.name || "",
        petName: updatedAppointment.petId?.name || "",
        action: "clinical_record_updated",
      },
      title: "Veteriner Notlari Guncellendi",
      body: `${updatedAppointment.petId?.name || "Evcil hayvaniniz"} icin klinik kayit guncellendi.`,
      pushType: "appointment_clinical_record_updated",
      excludeUserId: req.user.sub,
    });

    await recordAudit("appointment.clinical_record.update", {
      userId: req.user.sub,
      entityType: "appointment",
      entityId: req.params.id,
      metadata: { changedFields },
    });

    return sendOk(res, 200, { appointment: updatedAppointment });
  } catch (err) {
    console.error("[updateAppointmentClinicalRecord]", err);
    return sendError(res, 500, "Klinik kayit guncellenemedi", "internal_error", err.message);
  }
}

// GET /api/appointments/vet-earnings
export async function getVetEarningsSummary(req, res) {
  try {
    const userId = req.user.sub;
    const vet = await findManagedVetByUser(
      userId,
      "_id name clinicConsultationFee onlineConsultationFee"
    );
    if (!vet) {
      return sendError(res, 404, "Klinik bulunamadi veya size ait degil", "vet_not_found");
    }

    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    monthStart.setHours(0, 0, 0, 0);
    const dailyStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 13);
    dailyStart.setHours(0, 0, 0, 0);
    const monthlyStart = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    monthlyStart.setHours(0, 0, 0, 0);

    const basePipeline = [
      { $match: { veterinaryId: vet._id } },
      {
        $addFields: {
          settledAt: { $ifNull: ["$completedAt", "$date"] },
          resolvedFeeAmount: { $ifNull: ["$feeAmount", 0] },
        },
      },
    ];

    const [
      statsRaw,
      dailyTrendRaw,
      monthlyTrendRaw,
      typeBreakdownRaw,
      recentCompleted,
    ] = await Promise.all([
      Appointment.aggregate([
        ...basePipeline,
        {
          $group: {
            _id: null,
            totalAppointments: { $sum: 1 },
            pendingAppointments: {
              $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] },
            },
            confirmedAppointments: {
              $sum: { $cond: [{ $eq: ["$status", "confirmed"] }, 1, 0] },
            },
            completedAppointments: {
              $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] },
            },
            cancelledAppointments: {
              $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] },
            },
            noShowAppointments: {
              $sum: { $cond: [{ $eq: ["$status", "no_show"] }, 1, 0] },
            },
            totalRevenue: {
              $sum: {
                $cond: [{ $eq: ["$status", "completed"] }, "$resolvedFeeAmount", 0],
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
                  "$resolvedFeeAmount",
                  0,
                ],
              },
            },
            upcomingRevenue: {
              $sum: {
                $cond: [{ $eq: ["$status", "confirmed"] }, "$resolvedFeeAmount", 0],
              },
            },
            averageCompletedFee: {
              $avg: {
                $cond: [{ $eq: ["$status", "completed"] }, "$resolvedFeeAmount", null],
              },
            },
          },
        },
      ]),
      Appointment.aggregate([
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
            revenue: { $sum: "$resolvedFeeAmount" },
            appointments: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      Appointment.aggregate([
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
            revenue: { $sum: "$resolvedFeeAmount" },
            appointments: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      Appointment.aggregate([
        ...basePipeline,
        { $match: { status: "completed" } },
        {
          $group: {
            _id: "$type",
            revenue: { $sum: "$resolvedFeeAmount" },
            appointments: { $sum: 1 },
          },
        },
        { $sort: { revenue: -1 } },
      ]),
      Appointment.find({ veterinaryId: vet._id, status: "completed" })
        .populate("userId", "name")
        .populate("petId", "name")
        .sort({ completedAt: -1, date: -1 })
        .limit(5)
        .lean(),
    ]);

    const stats = statsRaw?.[0] || {};

    const dailySeries = [];
    for (let index = 0; index < 14; index += 1) {
      const cursor = new Date(dailyStart);
      cursor.setDate(cursor.getDate() + index);
      const key = getDateKey(cursor);
      const matched = (dailyTrendRaw || []).find((item) => item._id === key);
      dailySeries.push({
        key,
        label: `${String(cursor.getDate()).padStart(2, "0")}/${String(cursor.getMonth() + 1).padStart(2, "0")}`,
        revenue: Math.round(((matched?.revenue || 0) * 100)) / 100,
        appointments: matched?.appointments || 0,
      });
    }

    const monthlySeries = [];
    for (let index = 0; index < 6; index += 1) {
      const cursor = new Date(monthlyStart);
      cursor.setMonth(cursor.getMonth() + index);
      const key = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, "0")}`;
      const matched = (monthlyTrendRaw || []).find((item) => item._id === key);
      monthlySeries.push({
        key,
        label: `${String(cursor.getMonth() + 1).padStart(2, "0")}/${cursor.getFullYear()}`,
        revenue: Math.round(((matched?.revenue || 0) * 100)) / 100,
        appointments: matched?.appointments || 0,
      });
    }

    return sendOk(res, 200, {
      summary: {
        vetId: vet._id,
        vetName: vet.name,
        totalRevenue: Math.round(((stats.totalRevenue || 0) * 100)) / 100,
        thisMonthRevenue: Math.round(((stats.thisMonthRevenue || 0) * 100)) / 100,
        upcomingRevenue: Math.round(((stats.upcomingRevenue || 0) * 100)) / 100,
        averageCompletedFee: Math.round(((stats.averageCompletedFee || 0) * 100)) / 100,
        totalAppointments: stats.totalAppointments || 0,
        pendingAppointments: stats.pendingAppointments || 0,
        confirmedAppointments: stats.confirmedAppointments || 0,
        completedAppointments: stats.completedAppointments || 0,
        cancelledAppointments: stats.cancelledAppointments || 0,
        noShowAppointments: stats.noShowAppointments || 0,
        clinicConsultationFee: Math.round(((vet.clinicConsultationFee || 0) * 100)) / 100,
        onlineConsultationFee: Math.round(((vet.onlineConsultationFee || 0) * 100)) / 100,
      },
      dailyTrend: dailySeries,
      monthlyTrend: monthlySeries,
      typeBreakdown: (typeBreakdownRaw || []).map((item) => ({
        type: item._id || "clinic",
        label: item._id === "online" ? "Online" : "Klinik",
        revenue: Math.round(((item.revenue || 0) * 100)) / 100,
        appointments: item.appointments || 0,
      })),
      recentCompleted: recentCompleted.map((item) => ({
        id: item._id,
        petName: item.petId?.name || "Pet",
        ownerName: item.userId?.name || "Musteri",
        type: item.type || "clinic",
        feeAmount: Math.round((((item.feeAmount || 0) * 100))) / 100,
        completedAt: item.completedAt || item.date,
      })),
    });
  } catch (err) {
    console.error("[getVetEarningsSummary]", err);
    return sendError(res, 500, "Veteriner kazanc ozeti alinamadi", "internal_error", err.message);
  }
}

// GET /api/appointments/vet/:veterinaryId/slots?date=2026-03-01
export async function getAvailableSlots(req, res) {
  try {
    const { veterinaryId } = req.params;
    const { date, excludeAppointmentId } = req.query;

    if (!date) return sendError(res, 400, "date parametresi gerekli", "validation_error");

    const vet = await Veterinary.findById(veterinaryId);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    const targetDate = new Date(date);
    if (Number.isNaN(targetDate.getTime())) {
      return sendError(res, 400, "Gecersiz tarih", "validation_error");
    }

    const workingWindow = getWorkingWindow(vet, targetDate);
    if (!workingWindow.isAvailable) {
      return sendOk(res, 200, {
        slots: [],
        allSlots: [],
        bookedCount: 0,
        slotMinutes: getAppointmentSlotMinutes(vet),
      });
    }

    const { openH, openM, closeH, closeM } = workingWindow;
    const slotMinutes = getAppointmentSlotMinutes(vet);

    const allSlots = [];
    let current = openH * 60 + openM;
    const end = closeH * 60 + closeM;
    while (current + slotMinutes <= end) {
      allSlots.push(formatMinutes(current));
      current += slotMinutes;
    }

    const dayStart = new Date(targetDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(targetDate);
    dayEnd.setHours(23, 59, 59, 999);

    const query = {
      veterinaryId,
      status: { $in: ["pending", "confirmed"] },
      date: { $gte: dayStart, $lte: dayEnd },
    };
    if (
      excludeAppointmentId &&
      mongoose.Types.ObjectId.isValid(String(excludeAppointmentId))
    ) {
      query._id = { $ne: excludeAppointmentId };
    }

    const booked = await Appointment.find(query).select("date");
    const bookedTimes = new Set(
      booked.map((item) => {
        const bookedDate = new Date(item.date);
        return formatMinutes(bookedDate.getHours() * 60 + bookedDate.getMinutes());
      })
    );

    const now = new Date();
    const isToday =
      now.getFullYear() === targetDate.getFullYear() &&
      now.getMonth() === targetDate.getMonth() &&
      now.getDate() === targetDate.getDate();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();

    const availableSlots = allSlots.filter((slot) => {
      const [hours, minutes] = slot.split(":").map(Number);
      const slotMinutesFromStart = hours * 60 + minutes;
      if (isToday && slotMinutesFromStart <= currentMinutes) return false;
      return !bookedTimes.has(slot);
    });

    return sendOk(res, 200, {
      slots: availableSlots,
      allSlots,
      bookedCount: bookedTimes.size,
      slotMinutes,
    });
  } catch (err) {
    console.error("[getAvailableSlots]", err);
    return sendError(res, 500, "Musait saatler alinamadi", "internal_error", err.message);
  }
}

// GET /api/appointments/:id/prescriptions
export async function getAppointmentPrescriptions(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const appointment = await loadAppointmentWithRelations(req.params.id);
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!viewerRole) {
      return sendError(res, 403, "Bu recetelere erisim yetkiniz yok", "forbidden");
    }

    const prescriptions = await Prescription.find({ appointmentId: appointment._id }).sort({
      createdAt: -1,
    });

    return sendOk(res, 200, { prescriptions });
  } catch (err) {
    console.error("[getAppointmentPrescriptions]", err);
    return sendError(res, 500, "Receteler yuklenemedi", "internal_error", err.message);
  }
}

// POST /api/appointments/:id/prescriptions
export async function createAppointmentPrescription(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());

    const appointment = await loadAppointmentWithRelations(req.params.id);
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    const viewerRole = getAppointmentViewerRole(req.user, appointment);
    if (!["vet", "admin"].includes(viewerRole || "")) {
      return sendError(res, 403, "Sadece veteriner veya admin recete olusturabilir", "forbidden");
    }

    const { diagnosis, medications, notes, followUpDate } = req.body;
    const normalizedMedications = normalizeMedications(medications);

    if (!diagnosis || !String(diagnosis).trim()) {
      return sendError(res, 400, "Tani alani gerekli", "validation_error");
    }
    if (!normalizedMedications.length) {
      return sendError(res, 400, "En az bir ilac bilgisi gerekli", "validation_error");
    }

    let parsedFollowUpDate;
    if (followUpDate) {
      parsedFollowUpDate = new Date(followUpDate);
      if (Number.isNaN(parsedFollowUpDate.getTime())) {
        return sendError(res, 400, "Gecersiz takip tarihi", "validation_error");
      }
    }

    const prescription = await Prescription.create({
      appointmentId: appointment._id,
      petId: appointment.petId?._id || appointment.petId,
      veterinaryId: appointment.veterinaryId?._id || appointment.veterinaryId,
      vetUserId: appointment.veterinaryId?.userId || req.user.sub,
      ownerUserId: appointment.userId?._id || appointment.userId,
      diagnosis: String(diagnosis).trim(),
      medications: normalizedMedications,
      notes: notes?.toString().trim() || "",
      followUpDate: parsedFollowUpDate || undefined,
    });

    appointment.diagnosis = String(diagnosis).trim();
    appointment.followUpDate = parsedFollowUpDate || appointment.followUpDate;
    appointment.clinicalRecordUpdatedAt = new Date();
    await appointment.save();

    await emitAppointmentNotification({
      appointment,
      eventName: "prescription:created",
      socketPayload: {
        appointmentId: String(appointment._id),
        prescriptionId: String(prescription._id),
        veterinaryName: appointment.veterinaryId?.name || "",
        petName: appointment.petId?.name || "",
      },
      title: "Yeni Recete Hazirlandi",
      body: `${appointment.petId?.name || "Petiniz"} icin yeni bir recete olusturuldu.`,
      pushType: "prescription_created",
      excludeUserId: req.user.sub,
    });

    await recordAudit("appointment.prescription.create", {
      userId: req.user.sub,
      entityType: "prescription",
      entityId: prescription._id.toString(),
      metadata: { appointmentId: appointment._id.toString() },
    });

    return sendOk(res, 201, { prescription });
  } catch (err) {
    console.error("[createAppointmentPrescription]", err);
    return sendError(res, 500, "Recete olusturulamadi", "internal_error", err.message);
  }
}
