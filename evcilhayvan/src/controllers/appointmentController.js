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
import { io } from "../../server.js";
import { awardPoints } from "../utils/points.js";

const DEFAULT_APPOINTMENT_SLOT_MINUTES = 30;

function getAppointmentSlotMinutes(vet) {
  const slotMinutes = Number(vet?.appointmentSlotMinutes);
  return Number.isFinite(slotMinutes) && slotMinutes > 0
    ? slotMinutes
    : DEFAULT_APPOINTMENT_SLOT_MINUTES;
}

function getWorkingWindow(vet, targetDate) {
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

  const [openH, openM] = hours.open.split(":").map(Number);
  const [closeH, closeM] = hours.close.split(":").map(Number);

  if ([openH, openM, closeH, closeM].some((value) => Number.isNaN(value))) {
    return { isAvailable: false };
  }

  return { isAvailable: true, openH, openM, closeH, closeM };
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

  if (user?.role === "admin") return "admin";
  if (currentUserId && ownerId === currentUserId) return "owner";
  if (currentUserId && vetUserId && vetUserId === currentUserId) return "vet";
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
    .populate("userId", "name avatarUrl")
    .populate("petId", "name species photos")
    .populate(
      "veterinaryId",
      "name address phone email photos workingHours userId appointmentSlotMinutes"
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

  const recipients = [...new Set([ownerId, vetUserId].filter(Boolean))].filter(
    (id) => !excludeUserId || String(id) !== String(excludeUserId)
  );

  if (!recipients.length) return;

  if (io?.to) {
    recipients.forEach((userId) => {
      io.to(`user:${userId}`).emit(eventName, socketPayload);
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
    });

    const populated = await loadAppointmentWithRelations(appointment._id);

    await recordAudit("appointment.create", {
      userId,
      entityType: "appointment",
      entityId: appointment._id.toString(),
    });

    // N-1: Veterinere push bildirimi + socket (vet zaten yukarıda yüklendi)
    if (vet?.userId) {
      const petName = populated.petId?.name || "Evcil hayvan";
      sendPush([String(vet.userId)], {
        title: "Yeni Randevu Talebi",
        body: `${petName} için yeni bir randevu talebi aldınız.`,
        data: { type: "appointment", appointmentId: appointment._id.toString() },
      }).catch(() => {});
      if (io?.to) {
        io.to(`user:${String(vet.userId)}`).emit("appointment:new", {
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
      const vetIds = await Veterinary.find({ userId, isActive: true }).distinct("_id");
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
    const vet = await Veterinary.findOne({ userId, isActive: true });
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
    const { status, cancelReason, vetNotes } = req.body;

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
    }
    if (status === "confirmed" && appointment.type === "online" && !appointment.meetingUrl) {
      appointment.meetingUrl = `https://meet.google.com/lookup/${appointment._id.toString().slice(-8)}`;
    }
    await appointment.save();

    // Socket.io bildirimi
    if (io?.to) {
      io.to(`user:${String(appointment.userId)}`).emit("appointment:updated", {
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
