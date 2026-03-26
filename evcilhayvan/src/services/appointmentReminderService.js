// src/services/appointmentReminderService.js
// Her saat çalışır, 24 saat sonrası olan randevular için FCM + socket bildirimi gönderir.

import Appointment from "../models/Appointment.js";
import { sendPush } from "../utils/fcm.js";

const INTERVAL_MS = 60 * 60 * 1000; // 1 saat

export function startAppointmentReminderJob(io) {
  console.log("[AppointmentReminder] Job started, interval: 1h");

  async function checkReminders() {
    try {
      const now = new Date();

      // 23–25 saat sonrası pencere (saatlik kontrol ile kaçırmamak için 2h pencere)
      const windowStart = new Date(now.getTime() + 23 * 60 * 60 * 1000);
      const windowEnd   = new Date(now.getTime() + 25 * 60 * 60 * 1000);

      const appointments = await Appointment.find({
        date: { $gte: windowStart, $lte: windowEnd },
        status: { $in: ["pending", "confirmed"] },
        reminderSent: false,
      })
        .populate("userId", "name +fcmTokens")
        .populate("petId", "name species")
        .populate("veterinaryId", "name address");

      let sent = 0;

      for (const appt of appointments) {
        if (!appt.userId) continue;

        const userId   = String(appt.userId._id);
        const petName  = appt.petId?.name ?? "Evcil hayvanınız";
        const vetName  = appt.veterinaryId?.name ?? "Veteriner";
        const apptDate = new Date(appt.date);

        const dateStr = apptDate.toLocaleDateString("tr-TR", {
          day: "numeric",
          month: "long",
          hour: "2-digit",
          minute: "2-digit",
        });

        // Socket.io bildirimi (uygulama açıksa)
        if (io?.to) {
          io.to(`user:${userId}`).emit("appointment:reminder", {
            appointmentId: String(appt._id),
            petName,
            vetName,
            date: appt.date,
            dateStr,
          });
        }

        // FCM push (uygulama kapalıysa)
        await sendPush(userId, {
          title: "🗓️ Randevu Hatırlatıcısı",
          body: `${petName} için yarın saat ${apptDate.toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}'da ${vetName} randevunuz var.`,
          data: {
            type: "appointment_reminder",
            appointmentId: String(appt._id),
          },
        });

        appt.reminderSent = true;
        await appt.save();
        sent++;
      }

      if (sent > 0) {
        console.log(`[AppointmentReminder] ${sent} reminder(s) sent`);
      }
    } catch (err) {
      console.error("[AppointmentReminder] Error:", err.message);
    }
  }

  // İlk çalıştırma 15s sonra
  setTimeout(checkReminders, 15_000);
  // Saatlik tekrar
  setInterval(checkReminders, INTERVAL_MS);
}
