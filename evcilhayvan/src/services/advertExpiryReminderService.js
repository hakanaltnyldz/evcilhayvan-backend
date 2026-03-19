// src/services/advertExpiryReminderService.js
// Her 24 saatte bir çalışır. 30 günlük ilan süresi dolmak üzere olan
// (28-30 gün önce oluşturulan) aktif ilanlar için sahiplerine bildirim gönderir.

import Pet from "../models/Pet.js";

const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 saat
const ADVERT_LIFETIME_DAYS = 30;
const WARN_BEFORE_DAYS = 2; // 2 gün kala uyar

export function startAdvertExpiryReminderJob(io) {
  console.log("[AdvertExpiry] Job started, interval: 24h");

  async function checkExpiry() {
    try {
      const now = new Date();
      // Uyarı penceresi: 28-30 gün önce oluşturulan ilanlar
      const warnAfterDays = ADVERT_LIFETIME_DAYS - WARN_BEFORE_DAYS;
      const windowStart = new Date(now - warnAfterDays * 24 * 60 * 60 * 1000);
      const windowEnd = new Date(now - (warnAfterDays - 1) * 24 * 60 * 60 * 1000);

      const pets = await Pet.find({
        isActive: true,
        createdAt: { $gte: windowStart, $lt: windowEnd },
      })
        .select("_id name species advertType ownerId createdAt")
        .lean();

      let sentCount = 0;
      for (const pet of pets) {
        const userId = String(pet.ownerId);
        const daysLeft = ADVERT_LIFETIME_DAYS - warnAfterDays;
        const typeLabel = pet.advertType === "mating" ? "eşleştirme" : "sahiplendirme";

        io.to(userId).emit("advert:expiry_warning", {
          petId: String(pet._id),
          petName: pet.name,
          daysLeft,
          message: `⏰ "${pet.name}" adlı ${typeLabel} ilanınızın süresi ${daysLeft} gün içinde dolacak. Yenilemek ister misiniz?`,
        });
        sentCount++;
      }

      if (sentCount > 0) {
        console.log(`[AdvertExpiry] ${sentCount} ilan süresi uyarısı gönderildi.`);
      }
    } catch (err) {
      console.error("[AdvertExpiry] Hata:", err.message);
    }
  }

  // İlk çalıştırma: 15 saniye sonra
  setTimeout(checkExpiry, 15_000);
  setInterval(checkExpiry, CHECK_INTERVAL_MS);
}
