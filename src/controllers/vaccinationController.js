import mongoose from "mongoose";
import VaccinationRecord from "../models/VaccinationRecord.js";
import VaccinationSchedule from "../models/VaccinationSchedule.js";
import Pet from "../models/Pet.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

// GET /api/vaccinations/schedules?species=dog
export async function getSchedules(req, res) {
  try {
    const { species } = req.query;
    const filter = { isActive: true };
    if (species) filter.species = species;

    const schedules = await VaccinationSchedule.find(filter).sort({ species: 1, firstDoseMonths: 1 });
    return sendOk(res, 200, { schedules });
  } catch (err) {
    console.error("[getSchedules]", err);
    return sendError(res, 500, "Asi programi yuklenemedi", "internal_error", err.message);
  }
}

// POST /api/vaccinations/schedules (admin)
export async function createSchedule(req, res) {
  try {
    const { species, vaccineName, vaccineCode, description, firstDoseMonths, secondDoseMonths, repeatIntervalMonths, isRequired } = req.body;

    if (!species || !vaccineName || !vaccineCode || firstDoseMonths == null) {
      return sendError(res, 400, "species, vaccineName, vaccineCode ve firstDoseMonths gerekli", "validation_error");
    }

    const schedule = await VaccinationSchedule.create({
      species, vaccineName, vaccineCode, description,
      firstDoseMonths, secondDoseMonths, repeatIntervalMonths,
      isRequired: isRequired !== false,
    });

    return sendOk(res, 201, { schedule });
  } catch (err) {
    console.error("[createSchedule]", err);
    return sendError(res, 500, "Asi programi olusturulamadi", "internal_error", err.message);
  }
}

// GET /api/vaccinations/pet/:petId
export async function getPetVaccinations(req, res) {
  try {
    const userId = req.user.sub;
    const { petId } = req.params;

    const pet = await Pet.findOne({ _id: petId, ownerId: userId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    const records = await VaccinationRecord.find({ petId })
      .populate("veterinaryId", "name")
      .sort({ dateAdministered: -1 });

    return sendOk(res, 200, { records });
  } catch (err) {
    console.error("[getPetVaccinations]", err);
    return sendError(res, 500, "Asi kayitlari yuklenemedi", "internal_error", err.message);
  }
}

// POST /api/vaccinations/records
export async function addVaccinationRecord(req, res) {
  try {
    const userId = req.user.sub;
    const { petId, vaccineName, vaccineCode, dateAdministered, nextDueDate, veterinaryId, batchNumber, notes } = req.body;

    if (!petId || !vaccineName || !dateAdministered) {
      return sendError(res, 400, "petId, vaccineName ve dateAdministered gerekli", "validation_error");
    }

    const pet = await Pet.findOne({ _id: petId, ownerId: userId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    const record = await VaccinationRecord.create({
      petId, userId, veterinaryId,
      vaccineName, vaccineCode, batchNumber,
      dateAdministered: new Date(dateAdministered),
      nextDueDate: nextDueDate ? new Date(nextDueDate) : null,
      notes,
    });

    // Pet'in vaccinated alanini guncelle
    if (!pet.vaccinated) {
      pet.vaccinated = true;
      await pet.save();
    }

    await recordAudit("vaccination.record.create", {
      userId,
      entityType: "vaccination_record",
      entityId: record._id.toString(),
    });

    return sendOk(res, 201, { record });
  } catch (err) {
    console.error("[addVaccinationRecord]", err);
    return sendError(res, 500, "Asi kaydi olusturulamadi", "internal_error", err.message);
  }
}

// PUT /api/vaccinations/records/:id
export async function updateVaccinationRecord(req, res) {
  try {
    const userId = req.user.sub;
    const { id } = req.params;

    const record = await VaccinationRecord.findOne({ _id: id, userId });
    if (!record) return sendError(res, 404, "Asi kaydi bulunamadi", "record_not_found");

    const allowed = ["vaccineName", "vaccineCode", "batchNumber", "dateAdministered", "nextDueDate", "veterinaryId", "notes"];
    for (const key of allowed) {
      if (req.body[key] !== undefined) {
        record[key] = key.includes("Date") && req.body[key] ? new Date(req.body[key]) : req.body[key];
      }
    }
    record.reminderSent = false;
    await record.save();

    return sendOk(res, 200, { record });
  } catch (err) {
    console.error("[updateVaccinationRecord]", err);
    return sendError(res, 500, "Asi kaydi guncellenemedi", "internal_error", err.message);
  }
}

// DELETE /api/vaccinations/records/:id
export async function deleteVaccinationRecord(req, res) {
  try {
    const userId = req.user.sub;
    const { id } = req.params;

    const record = await VaccinationRecord.findOneAndDelete({ _id: id, userId });
    if (!record) return sendError(res, 404, "Asi kaydi bulunamadi", "record_not_found");

    return sendOk(res, 200, { deleted: true });
  } catch (err) {
    console.error("[deleteVaccinationRecord]", err);
    return sendError(res, 500, "Asi kaydi silinemedi", "internal_error", err.message);
  }
}

// GET /api/vaccinations/pet/:petId/calendar
export async function getVaccinationCalendar(req, res) {
  try {
    const userId = req.user.sub;
    const { petId } = req.params;

    const pet = await Pet.findOne({ _id: petId, ownerId: userId });
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya size ait degil", "pet_not_found");

    const schedules = await VaccinationSchedule.find({ species: pet.species, isActive: true });
    const records = await VaccinationRecord.find({ petId }).sort({ dateAdministered: -1 });

    const now = new Date();
    const calendar = schedules.map((schedule) => {
      const matchingRecords = records.filter(
        (r) => r.vaccineCode === schedule.vaccineCode || r.vaccineName === schedule.vaccineName
      );
      const lastRecord = matchingRecords[0] || null;

      let status = "not_started";
      let nextDueDate = null;
      let daysUntilDue = null;

      if (lastRecord && lastRecord.nextDueDate) {
        nextDueDate = lastRecord.nextDueDate;
        const diffMs = nextDueDate.getTime() - now.getTime();
        daysUntilDue = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

        if (daysUntilDue < 0) {
          status = "overdue";
        } else if (daysUntilDue <= 30) {
          status = "due_soon";
        } else {
          status = "completed";
        }
      } else if (lastRecord && !lastRecord.nextDueDate) {
        status = "completed";
      } else {
        // Hic kayit yok - pet yasi kontrol et
        const petAgeMonths = pet.ageMonths || 0;
        if (petAgeMonths >= schedule.firstDoseMonths) {
          status = "overdue";
          // Tahmini tarih hesapla
          const birthDate = new Date();
          birthDate.setMonth(birthDate.getMonth() - petAgeMonths);
          nextDueDate = new Date(birthDate);
          nextDueDate.setMonth(nextDueDate.getMonth() + schedule.firstDoseMonths);
          daysUntilDue = Math.ceil((nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        } else {
          status = "upcoming";
          const birthDate = new Date();
          birthDate.setMonth(birthDate.getMonth() - petAgeMonths);
          nextDueDate = new Date(birthDate);
          nextDueDate.setMonth(nextDueDate.getMonth() + schedule.firstDoseMonths);
          daysUntilDue = Math.ceil((nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        }
      }

      return {
        schedule: schedule.toJSON(),
        lastRecord: lastRecord ? lastRecord.toJSON() : null,
        status,
        nextDueDate,
        daysUntilDue,
      };
    });

    // Duruma gore sirala: overdue > due_soon > upcoming > not_started > completed
    const statusOrder = { overdue: 0, due_soon: 1, upcoming: 2, not_started: 3, completed: 4 };
    calendar.sort((a, b) => (statusOrder[a.status] || 5) - (statusOrder[b.status] || 5));

    return sendOk(res, 200, { calendar, pet: { id: pet._id, name: pet.name, species: pet.species, ageMonths: pet.ageMonths } });
  } catch (err) {
    console.error("[getVaccinationCalendar]", err);
    return sendError(res, 500, "Asi takvimi yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/vaccinations/reminders
export async function getReminders(req, res) {
  try {
    const userId = req.user.sub;

    // Kullanicinin petlerini bul
    const pets = await Pet.find({ ownerId: userId, isActive: true }).select("_id name species");
    const petIds = pets.map((p) => p._id);

    // Yaklasan asi kayitlarini bul (30 gun icinde)
    const thirtyDaysLater = new Date();
    thirtyDaysLater.setDate(thirtyDaysLater.getDate() + 30);

    const records = await VaccinationRecord.find({
      petId: { $in: petIds },
      nextDueDate: { $lte: thirtyDaysLater, $gte: new Date() },
    })
      .populate("petId", "name species")
      .sort({ nextDueDate: 1 });

    return sendOk(res, 200, { reminders: records });
  } catch (err) {
    console.error("[getReminders]", err);
    return sendError(res, 500, "Hatirlatmalar yuklenemedi", "internal_error", err.message);
  }
}
