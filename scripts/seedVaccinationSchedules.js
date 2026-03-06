import mongoose from "mongoose";
import "dotenv/config";
import VaccinationSchedule from "../src/models/VaccinationSchedule.js";

const SCHEDULES = [
  // Kopek
  { species: "dog", vaccineName: "Karma Asi (DHPPi)", vaccineCode: "dhppi", description: "Distemper, Hepatit, Parvovirus, Parainfluenza", firstDoseMonths: 2, secondDoseMonths: 3, repeatIntervalMonths: 12, isRequired: true },
  { species: "dog", vaccineName: "Kuduz", vaccineCode: "rabies", description: "Kuduz virusu asisi", firstDoseMonths: 3, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: true },
  { species: "dog", vaccineName: "Coronavirus", vaccineCode: "coronavirus", description: "Koronavirus asisi", firstDoseMonths: 2, secondDoseMonths: 3, repeatIntervalMonths: 12, isRequired: false },
  { species: "dog", vaccineName: "Kennel Cough (Bordetella)", vaccineCode: "bordetella", description: "Kulube oksurugu asisi", firstDoseMonths: 4, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: false },
  { species: "dog", vaccineName: "Leptospiroz", vaccineCode: "leptospirosis", description: "Leptospiroz bakterisi asisi", firstDoseMonths: 3, secondDoseMonths: 4, repeatIntervalMonths: 12, isRequired: false },
  { species: "dog", vaccineName: "Lyme", vaccineCode: "lyme", description: "Lyme hastaligi asisi", firstDoseMonths: 4, secondDoseMonths: 5, repeatIntervalMonths: 12, isRequired: false },

  // Kedi
  { species: "cat", vaccineName: "Karma Asi (FVRCP)", vaccineCode: "fvrcp", description: "Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia", firstDoseMonths: 2, secondDoseMonths: 3, repeatIntervalMonths: 12, isRequired: true },
  { species: "cat", vaccineName: "Kuduz", vaccineCode: "rabies", description: "Kuduz virusu asisi", firstDoseMonths: 3, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: true },
  { species: "cat", vaccineName: "FeLV (Feline Leukemia)", vaccineCode: "felv", description: "Kedi losemi virusu asisi", firstDoseMonths: 2, secondDoseMonths: 3, repeatIntervalMonths: 12, isRequired: false },
  { species: "cat", vaccineName: "FIP", vaccineCode: "fip", description: "Feline Infeksiyoz Peritonit", firstDoseMonths: 4, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: false },
  { species: "cat", vaccineName: "Klamidya", vaccineCode: "chlamydia", description: "Chlamydophila felis asisi", firstDoseMonths: 2, secondDoseMonths: 3, repeatIntervalMonths: 12, isRequired: false },

  // Kus
  { species: "bird", vaccineName: "Newcastle", vaccineCode: "newcastle", description: "Newcastle hastaligi asisi", firstDoseMonths: 1, secondDoseMonths: 2, repeatIntervalMonths: 6, isRequired: true },
  { species: "bird", vaccineName: "Polyoma", vaccineCode: "polyoma", description: "Polyoma virus asisi", firstDoseMonths: 1, secondDoseMonths: 2, repeatIntervalMonths: 12, isRequired: false },
  { species: "bird", vaccineName: "PBFD", vaccineCode: "pbfd", description: "Psittacine Beak and Feather Disease", firstDoseMonths: 2, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: false },

  // Kemirgen (Tavsan)
  { species: "rodent", vaccineName: "Kuduz (Tavsan)", vaccineCode: "rabies_rabbit", description: "Tavsan kuduz asisi", firstDoseMonths: 3, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: true },
  { species: "rodent", vaccineName: "Myxomatosis", vaccineCode: "myxomatosis", description: "Myxomatosis asisi", firstDoseMonths: 2, secondDoseMonths: null, repeatIntervalMonths: 6, isRequired: true },
  { species: "rodent", vaccineName: "RHD", vaccineCode: "rhd", description: "Rabbit Haemorrhagic Disease", firstDoseMonths: 2, secondDoseMonths: null, repeatIntervalMonths: 12, isRequired: true },
];

async function seed() {
  const uri = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/evcilhayvan";
  await mongoose.connect(uri);
  console.log("MongoDB connected for seeding");

  for (const s of SCHEDULES) {
    await VaccinationSchedule.findOneAndUpdate(
      { species: s.species, vaccineCode: s.vaccineCode },
      { $set: s },
      { upsert: true }
    );
  }

  console.log(`${SCHEDULES.length} vaccination schedule(s) seeded.`);
  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error("Seed error:", err);
  process.exit(1);
});
