import mongoose from "mongoose";
import Appointment from "../models/Appointment.js";
import Veterinary from "../models/Veterinary.js";
import Pet from "../models/Pet.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import { io } from "../../server.js";

// POST /api/appointments
export async function createAppointment(req, res) {
  try {
    const userId = req.user.sub;
    const { petId, veterinaryId, date, reason, notes } = req.body;

    if (!petId || !veterinaryId || !date) {
      return sendError(res, 400, "petId, veterinaryId ve date gerekli", "validation_error");
    }

    // Pet kontrolu
    const pet = await Pet.findOne({ _id: petId, ownerId: userId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    // Veteriner kontrolu
    const vet = await Veterinary.findById(veterinaryId);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    const appointmentDate = new Date(date);
    if (appointmentDate <= new Date()) {
      return sendError(res, 400, "Randevu tarihi gelecekte olmali", "validation_error");
    }

    // Slot cakisma kontrolu
    const slotMinutes = vet.appointmentSlotMinutes || 30;
    const endDate = new Date(appointmentDate.getTime() + slotMinutes * 60000);

    const conflict = await Appointment.findOne({
      veterinaryId,
      status: { $in: ["pending", "confirmed"] },
      date: { $lt: endDate },
      endDate: { $gt: appointmentDate },
    });

    if (conflict) {
      return sendError(res, 409, "Bu saat dilimi dolu", "slot_conflict");
    }

    const appointment = await Appointment.create({
      userId,
      petId,
      veterinaryId,
      date: appointmentDate,
      endDate,
      reason: reason || "",
      notes: notes || "",
      status: "pending",
    });

    const populated = await Appointment.findById(appointment._id)
      .populate("petId", "name species photos")
      .populate("veterinaryId", "name address phone");

    await recordAudit("appointment.create", {
      userId,
      entityType: "appointment",
      entityId: appointment._id.toString(),
    });

    return sendOk(res, 201, { appointment: populated });
  } catch (err) {
    console.error("[createAppointment]", err);
    return sendError(res, 500, "Randevu olusturulamadi", "internal_error", err.message);
  }
}

// GET /api/appointments/me
export async function getMyAppointments(req, res) {
  try {
    const userId = req.user.sub;
    const { status, petId, page = 1, limit = 20 } = req.query;
    const filter = { userId };

    if (status) filter.status = status;
    if (petId) filter.petId = petId;

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Appointment.find(filter)
        .populate("petId", "name species photos")
        .populate("veterinaryId", "name address phone photos")
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

// GET /api/appointments/:id
export async function getAppointment(req, res) {
  try {
    const userId = req.user.sub;
    const { id } = req.params;

    const appointment = await Appointment.findOne({ _id: id, userId })
      .populate("petId", "name species breed photos ageMonths")
      .populate("veterinaryId", "name address phone email photos workingHours");

    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
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
    const userId = req.user.sub;
    const { id } = req.params;
    const { status, cancelReason } = req.body;

    const validStatuses = ["confirmed", "cancelled", "completed", "no_show"];
    if (!validStatuses.includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "validation_error");
    }

    const appointment = await Appointment.findById(id)
      .populate("veterinaryId", "name");
    if (!appointment) {
      return sendError(res, 404, "Randevu bulunamadi", "appointment_not_found");
    }

    // Kullanici sadece kendi randevusunu iptal edebilir
    if (String(appointment.userId) !== String(userId) && req.user.role !== "admin") {
      return sendError(res, 403, "Bu randevuyu guncelleme yetkiniz yok", "forbidden");
    }

    if (appointment.status === "cancelled") {
      return sendError(res, 400, "Iptal edilmis randevu guncellenemez", "already_cancelled");
    }

    appointment.status = status;
    if (status === "cancelled") {
      appointment.cancelledBy = userId;
      appointment.cancelReason = cancelReason || "";
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

    await recordAudit("appointment.status_update", {
      userId,
      entityType: "appointment",
      entityId: id,
      metadata: { newStatus: status },
    });

    return sendOk(res, 200, { appointment });
  } catch (err) {
    console.error("[updateAppointmentStatus]", err);
    return sendError(res, 500, "Randevu durumu guncellenemedi", "internal_error", err.message);
  }
}

// GET /api/appointments/vet/:veterinaryId/slots?date=2026-03-01
export async function getAvailableSlots(req, res) {
  try {
    const { veterinaryId } = req.params;
    const { date } = req.query;

    if (!date) return sendError(res, 400, "date parametresi gerekli", "validation_error");

    const vet = await Veterinary.findById(veterinaryId);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    const targetDate = new Date(date);
    // Pazartesi=0, Pazar=6 formatina cevir (JS Date: Pazar=0)
    const jsDay = targetDate.getDay();
    const dayIndex = jsDay === 0 ? 6 : jsDay - 1;

    const hours = vet.workingHours.find((wh) => wh.day === dayIndex);
    if (!hours || hours.isClosed || !hours.open || !hours.close) {
      return sendOk(res, 200, { slots: [], message: "Bu gun kapali" });
    }

    // Slotlari olustur
    const [openH, openM] = hours.open.split(":").map(Number);
    const [closeH, closeM] = hours.close.split(":").map(Number);
    const slotMinutes = vet.appointmentSlotMinutes || 30;

    const slots = [];
    let current = openH * 60 + openM;
    const end = closeH * 60 + closeM;

    while (current + slotMinutes <= end) {
      const h = Math.floor(current / 60);
      const m = current % 60;
      slots.push(`${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`);
      current += slotMinutes;
    }

    // Dolu slotlari cikar
    const dayStart = new Date(targetDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(targetDate);
    dayEnd.setHours(23, 59, 59, 999);

    const booked = await Appointment.find({
      veterinaryId,
      status: { $in: ["pending", "confirmed"] },
      date: { $gte: dayStart, $lte: dayEnd },
    }).select("date");

    const bookedTimes = new Set(
      booked.map((a) => {
        const d = new Date(a.date);
        return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
      })
    );

    const availableSlots = slots.filter((s) => !bookedTimes.has(s));

    return sendOk(res, 200, { slots: availableSlots, allSlots: slots, bookedCount: bookedTimes.size });
  } catch (err) {
    console.error("[getAvailableSlots]", err);
    return sendError(res, 500, "Musait saatler alinamadi", "internal_error", err.message);
  }
}
