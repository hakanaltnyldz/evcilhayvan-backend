import { validationResult } from "express-validator";
import HealthRecord from "../models/HealthRecord.js";
import Pet from "../models/Pet.js";
import { sendError, sendOk } from "../utils/apiResponse.js";

// Yardımcı: Pet sahibi mi?
async function assertOwner(petId, userId) {
  const pet = await Pet.findById(petId).select("ownerId");
  if (!pet) return { error: 404, message: "Pet bulunamadı." };
  if (String(pet.ownerId) !== String(userId)) return { error: 403, message: "Yetki yok." };
  return { ok: true };
}

// GET /api/health/:petId
export const getRecords = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const { petId } = req.params;
    const userId = req.user.sub;
    const check = await assertOwner(petId, userId);
    if (!check.ok) return sendError(res, check.error, check.message, check.error === 404 ? "not_found" : "forbidden");

    const { type, from, to, limit = 50 } = req.query;
    const filter = { petId };
    if (type) filter.type = type;
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = new Date(from);
      if (to) filter.date.$lte = new Date(to);
    }

    const records = await HealthRecord.find(filter)
      .sort({ date: -1 })
      .limit(Number(limit));

    return sendOk(res, 200, { records });
  } catch (err) {
    console.error("[getRecords]", err);
    return sendError(res, 500, err.message, "internal_error");
  }
};

// POST /api/health/:petId
export const addRecord = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const { petId } = req.params;
    const userId = req.user.sub;
    const check = await assertOwner(petId, userId);
    if (!check.ok) return sendError(res, check.error, check.message, check.error === 404 ? "not_found" : "forbidden");

    const { type, date, weightKg, medicationName, dosage, frequency,
            vetName, diagnosis, notes } = req.body;

    const validTypes = ["weight", "medication", "vet_visit", "note"];
    if (!type || !validTypes.includes(type)) {
      return sendError(res, 400, "Geçerli bir kayıt tipi seçin.", "validation_error");
    }
    if (!date) return sendError(res, 400, "Tarih zorunludur.", "validation_error");

    const record = await HealthRecord.create({
      petId,
      ownerId: userId,
      type,
      date: new Date(date),
      weightKg: weightKg !== undefined ? Number(weightKg) : undefined,
      medicationName,
      dosage,
      frequency,
      vetName,
      diagnosis,
      notes,
    });

    return sendOk(res, 201, { record });
  } catch (err) {
    console.error("[addRecord]", err);
    return sendError(res, 500, err.message, "internal_error");
  }
};

// PUT /api/health/record/:id
export const updateRecord = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const userId = req.user.sub;
    const record = await HealthRecord.findById(req.params.id);
    if (!record) return sendError(res, 404, "Kayıt bulunamadı.", "not_found");
    if (String(record.ownerId) !== String(userId)) return sendError(res, 403, "Yetki yok.", "forbidden");

    const allowed = ["date", "weightKg", "medicationName", "dosage",
                     "frequency", "vetName", "diagnosis", "notes"];
    allowed.forEach((field) => {
      if (req.body[field] !== undefined) record[field] = req.body[field];
    });
    await record.save();
    return sendOk(res, 200, { record });
  } catch (err) {
    console.error("[updateRecord]", err);
    return sendError(res, 500, err.message, "internal_error");
  }
};

// DELETE /api/health/record/:id
export const deleteRecord = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const userId = req.user.sub;
    const record = await HealthRecord.findById(req.params.id);
    if (!record) return sendError(res, 404, "Kayıt bulunamadı.", "not_found");
    if (String(record.ownerId) !== String(userId)) return sendError(res, 403, "Yetki yok.", "forbidden");
    await record.deleteOne();
    return sendOk(res, 200, { message: "Kayıt silindi." });
  } catch (err) {
    console.error("[deleteRecord]", err);
    return sendError(res, 500, err.message, "internal_error");
  }
};

// GET /api/health/:petId/weight-chart  — son 20 kilo kaydı (grafik için)
export const getWeightChart = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return sendError(res, 400, "Gecersiz ID", "validation_error", errors.array());
    const { petId } = req.params;
    const userId = req.user.sub;
    const check = await assertOwner(petId, userId);
    if (!check.ok) return sendError(res, check.error, check.message, check.error === 404 ? "not_found" : "forbidden");

    const records = await HealthRecord.find({ petId, type: "weight" })
      .select("date weightKg")
      .sort({ date: 1 })
      .limit(20);

    return sendOk(res, 200, { weightData: records });
  } catch (err) {
    console.error("[getWeightChart]", err);
    return sendError(res, 500, err.message, "internal_error");
  }
};
