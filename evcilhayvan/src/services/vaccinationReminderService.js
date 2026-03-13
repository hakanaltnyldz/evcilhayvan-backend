import VaccinationRecord from "../models/VaccinationRecord.js";
import Pet from "../models/Pet.js";

const REMINDER_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 saat
const REMINDER_DAYS_BEFORE = 7;

export function startVaccinationReminderJob(io) {
  console.log("[VaccinationReminder] Job started, interval: 24h");

  async function checkReminders() {
    try {
      const now = new Date();
      const reminderCutoff = new Date();
      reminderCutoff.setDate(reminderCutoff.getDate() + REMINDER_DAYS_BEFORE);

      // Yaklasan ve henuz bildirim gonderilmemis kayitlari bul
      const records = await VaccinationRecord.find({
        nextDueDate: { $gte: now, $lte: reminderCutoff },
        reminderSent: false,
      }).populate({
        path: "petId",
        select: "name species ownerId",
      });

      let sentCount = 0;
      for (const record of records) {
        if (!record.petId?.ownerId) continue;

        const userId = String(record.petId.ownerId);
        const daysUntil = Math.ceil(
          (record.nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
        );

        // Socket.io ile bildirim gonder
        if (io?.to) {
          io.to(`user:${userId}`).emit("vaccination:reminder", {
            petName: record.petId.name,
            petSpecies: record.petId.species,
            vaccineName: record.vaccineName,
            nextDueDate: record.nextDueDate,
            daysUntilDue: daysUntil,
            recordId: record._id,
          });
        }

        record.reminderSent = true;
        await record.save();
        sentCount++;
      }

      if (sentCount > 0) {
        console.log(`[VaccinationReminder] ${sentCount} reminder(s) sent`);
      }
    } catch (err) {
      console.error("[VaccinationReminder] Error:", err.message);
    }
  }

  // Ilk calistirma (5 saniye sonra)
  setTimeout(checkReminders, 5000);
  // Gunluk tekrar
  setInterval(checkReminders, REMINDER_INTERVAL_MS);
}
