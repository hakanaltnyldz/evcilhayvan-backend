import HealthRecord from "../models/HealthRecord.js";
import Pet from "../models/Pet.js";

// Yardımcı: Pet sahibi mi?
async function assertOwner(petId, userId, res) {
  const pet = await Pet.findById(petId).select("ownerId");
  if (!pet) { res.sendError("Pet bulunamadı.", 404); return false; }
  if (String(pet.ownerId) !== String(userId)) { res.sendError("Yetki yok.", 403); return false; }
  return true;
}

// GET /api/health/:petId
export const getRecords = async (req, res) => {
  try {
    const { petId } = req.params;
    if (!await assertOwner(petId, req.user.id, res)) return;

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

    res.sendOk({ records });
  } catch (err) {
    res.sendError(err.message);
  }
};

// POST /api/health/:petId
export const addRecord = async (req, res) => {
  try {
    const { petId } = req.params;
    if (!await assertOwner(petId, req.user.id, res)) return;

    const { type, date, weightKg, medicationName, dosage, frequency,
            vetName, diagnosis, notes } = req.body;

    const validTypes = ["weight", "medication", "vet_visit", "note"];
    if (!type || !validTypes.includes(type)) {
      return res.sendError("Geçerli bir kayıt tipi seçin.", 400);
    }
    if (!date) return res.sendError("Tarih zorunludur.", 400);

    const record = await HealthRecord.create({
      petId,
      ownerId: req.user.id,
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

    res.sendOk({ record }, 201);
  } catch (err) {
    res.sendError(err.message);
  }
};

// PUT /api/health/record/:id
export const updateRecord = async (req, res) => {
  try {
    const record = await HealthRecord.findById(req.params.id);
    if (!record) return res.sendError("Kayıt bulunamadı.", 404);
    if (String(record.ownerId) !== String(req.user.id)) return res.sendError("Yetki yok.", 403);

    const allowed = ["date", "weightKg", "medicationName", "dosage",
                     "frequency", "vetName", "diagnosis", "notes"];
    allowed.forEach((field) => {
      if (req.body[field] !== undefined) record[field] = req.body[field];
    });
    await record.save();
    res.sendOk({ record });
  } catch (err) {
    res.sendError(err.message);
  }
};

// DELETE /api/health/record/:id
export const deleteRecord = async (req, res) => {
  try {
    const record = await HealthRecord.findById(req.params.id);
    if (!record) return res.sendError("Kayıt bulunamadı.", 404);
    if (String(record.ownerId) !== String(req.user.id)) return res.sendError("Yetki yok.", 403);
    await record.deleteOne();
    res.sendOk({ message: "Kayıt silindi." });
  } catch (err) {
    res.sendError(err.message);
  }
};

// GET /api/health/:petId/weight-chart  — son 20 kilo kaydı (grafik için)
export const getWeightChart = async (req, res) => {
  try {
    const { petId } = req.params;
    if (!await assertOwner(petId, req.user.id, res)) return;

    const records = await HealthRecord.find({ petId, type: "weight" })
      .select("date weightKg")
      .sort({ date: 1 })
      .limit(20);

    res.sendOk({ weightData: records });
  } catch (err) {
    res.sendError(err.message);
  }
};
