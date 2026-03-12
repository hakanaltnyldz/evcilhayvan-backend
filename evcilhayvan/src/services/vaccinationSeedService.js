import VaccinationSchedule from "../models/VaccinationSchedule.js";

const SCHEDULES = [
  // ── Köpek ──────────────────────────────────────────────────────────────
  {
    species: "dog",
    vaccineName: "Karma Aşı (DHPPi)",
    vaccineCode: "dog_dhppi",
    description: "Distemper, Hepatit, Parvovirüs, Parainfluenza karma aşısı",
    firstDoseMonths: 2,
    secondDoseMonths: 3,
    repeatIntervalMonths: 12,
    isRequired: true,
  },
  {
    species: "dog",
    vaccineName: "Kuduz Aşısı",
    vaccineCode: "dog_rabies",
    description: "Zorunlu kuduz aşısı",
    firstDoseMonths: 3,
    repeatIntervalMonths: 12,
    isRequired: true,
  },
  {
    species: "dog",
    vaccineName: "Leptospirosis Aşısı",
    vaccineCode: "dog_lepto",
    description: "Leptospirosis bakteriyel enfeksiyonuna karşı koruyucu aşı",
    firstDoseMonths: 3,
    secondDoseMonths: 4,
    repeatIntervalMonths: 12,
    isRequired: false,
  },
  {
    species: "dog",
    vaccineName: "Bordetella (Kennel Öksürüğü)",
    vaccineCode: "dog_bordetella",
    description: "Kennel öksürüğüne karşı aşı, özellikle toplu yaşam alanları için",
    firstDoseMonths: 2,
    repeatIntervalMonths: 12,
    isRequired: false,
  },
  {
    species: "dog",
    vaccineName: "Lyme Hastalığı Aşısı",
    vaccineCode: "dog_lyme",
    description: "Kene kaynaklı Lyme hastalığına karşı koruyucu",
    firstDoseMonths: 3,
    secondDoseMonths: 4,
    repeatIntervalMonths: 12,
    isRequired: false,
  },

  // ── Kedi ───────────────────────────────────────────────────────────────
  {
    species: "cat",
    vaccineName: "Üçlü Karma Aşı (FVRCP)",
    vaccineCode: "cat_fvrcp",
    description: "Felin Viral Riniotrakeit, Kalisivirüs, Panloköpeni karma aşısı",
    firstDoseMonths: 2,
    secondDoseMonths: 3,
    repeatIntervalMonths: 12,
    isRequired: true,
  },
  {
    species: "cat",
    vaccineName: "Kuduz Aşısı",
    vaccineCode: "cat_rabies",
    description: "Zorunlu kuduz aşısı",
    firstDoseMonths: 3,
    repeatIntervalMonths: 12,
    isRequired: true,
  },
  {
    species: "cat",
    vaccineName: "Felin Lösemi Virüsü (FeLV)",
    vaccineCode: "cat_felv",
    description: "Felin lösemi virüsüne karşı koruyucu, dış mekan kediler için önerilir",
    firstDoseMonths: 2,
    secondDoseMonths: 3,
    repeatIntervalMonths: 12,
    isRequired: false,
  },
  {
    species: "cat",
    vaccineName: "Felin İmmün Yetmezlik Virüsü (FIV)",
    vaccineCode: "cat_fiv",
    description: "Kedi AIDS'i olarak da bilinen FIV'e karşı koruyucu",
    firstDoseMonths: 4,
    repeatIntervalMonths: 12,
    isRequired: false,
  },

  // ── Kuş ────────────────────────────────────────────────────────────────
  {
    species: "bird",
    vaccineName: "Polyomavirus Aşısı",
    vaccineCode: "bird_polyoma",
    description: "Papağan polyomavirus enfeksiyonuna karşı koruyucu",
    firstDoseMonths: 1,
    secondDoseMonths: 2,
    repeatIntervalMonths: 12,
    isRequired: false,
  },
  {
    species: "bird",
    vaccineName: "Newcastle Hastalığı Aşısı",
    vaccineCode: "bird_newcastle",
    description: "Newcastle hastalığına karşı koruyucu aşı",
    firstDoseMonths: 1,
    repeatIntervalMonths: 12,
    isRequired: false,
  },
];

export async function seedVaccinationSchedules() {
  try {
    const count = await VaccinationSchedule.countDocuments();
    if (count > 0) {
      console.log(`ℹ️  Vaccination schedules already seeded (${count} records)`);
      return;
    }

    await VaccinationSchedule.insertMany(SCHEDULES);
    console.log(`✅ Vaccination schedules seeded: ${SCHEDULES.length} templates added`);
  } catch (err) {
    console.error("⚠️  Vaccination seed failed:", err.message);
  }
}
