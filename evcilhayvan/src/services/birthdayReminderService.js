import Pet from "../models/Pet.js";

const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 saat

export function startBirthdayReminderJob(io) {
  console.log("[BirthdayReminder] Job started, interval: 24h");

  async function checkBirthdays() {
    try {
      const now = new Date();
      const todayMonth = now.getMonth() + 1; // 1-12
      const todayDay = now.getDate();

      // Bugün doğum günü olan aktif ilanları bul
      const pets = await Pet.aggregate([
        { $match: { isActive: true, birthDate: { $exists: true, $ne: null } } },
        {
          $addFields: {
            bMonth: { $month: "$birthDate" },
            bDay: { $dayOfMonth: "$birthDate" },
          },
        },
        {
          $match: { bMonth: todayMonth, bDay: todayDay },
        },
        {
          $lookup: {
            from: "users",
            localField: "ownerId",
            foreignField: "_id",
            as: "owner",
          },
        },
        { $unwind: "$owner" },
        {
          $project: {
            name: 1,
            species: 1,
            ownerId: 1,
            birthDate: 1,
          },
        },
      ]);

      let sentCount = 0;
      for (const pet of pets) {
        const userId = String(pet.ownerId);
        const ageYears = todayMonth === (new Date(pet.birthDate).getMonth() + 1)
          ? now.getFullYear() - new Date(pet.birthDate).getFullYear()
          : null;

        const ageText = ageYears && ageYears > 0 ? `${ageYears} yaşına giriyor!` : "doğum günü bugün!";

        io.to(userId).emit("pet:birthday", {
          petId: String(pet._id),
          petName: pet.name,
          message: `🎂 ${pet.name}'in ${ageText}`,
        });
        sentCount++;
      }

      if (sentCount > 0) {
        console.log(`[BirthdayReminder] ${sentCount} doğum günü bildirimi gönderildi.`);
      }
    } catch (err) {
      console.error("[BirthdayReminder] Hata:", err.message);
    }
  }

  // İlk çalıştırma: 10 saniye sonra (uygulama başladıktan sonra)
  setTimeout(checkBirthdays, 10_000);
  // Sonraki çalıştırmalar: her 24 saatte bir
  setInterval(checkBirthdays, CHECK_INTERVAL_MS);
}
