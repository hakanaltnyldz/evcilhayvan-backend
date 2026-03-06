import { validationResult } from "express-validator";
import PetSitter from "../models/PetSitter.js";
import SitterBooking from "../models/SitterBooking.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

function buildLocation(bodyLocation) {
  if (bodyLocation?.coordinates?.length === 2) {
    return { type: "Point", coordinates: bodyLocation.coordinates.map(Number) };
  }
  return undefined;
}

// POST / - Bakici profili olustur
export async function createSitter(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());

  try {
    const userId = req.user.sub;
    const exists = await PetSitter.findOne({ userId });
    if (exists) return sendError(res, 409, "Zaten bakici profiliniz var", "already_exists");

    const body = { ...req.body, userId };
    const location = buildLocation(body.location);
    if (location) body.location = location; else delete body.location;

    let doc = await PetSitter.create(body);
    doc = await doc.populate("userId", "name avatarUrl");

    await recordAudit("petsitter.create", { userId, entityType: "PetSitter", entityId: doc.id });
    return sendOk(res, 201, { sitter: doc });
  } catch (err) {
    console.error("[PetSitter] create error:", err.message);
    return sendError(res, 500, "Profil olusturulamadi", "create_error");
  }
}

// GET / - Liste + geo filtre
export async function listSitters(req, res) {
  try {
    const { lat, lng, radiusKm = 20, service, species, minRating = 0, page = 1, limit = 20 } = req.query;
    const skip = (Number(page) - 1) * Number(limit);

    if (lat && lng) {
      const pipeline = [];
      pipeline.push({
        $geoNear: {
          near: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          distanceField: "distanceMeters",
          spherical: true,
          maxDistance: Number(radiusKm) * 1000,
        },
      });

      const match = { isActive: true, availability: true };
      if (service) match["services.type"] = service;
      if (species) match.speciesServed = species;
      if (Number(minRating) > 0) match.rating = { $gte: Number(minRating) };
      pipeline.push({ $match: match });
      pipeline.push({ $sort: { distanceMeters: 1 } });
      pipeline.push({ $skip: skip });
      pipeline.push({ $limit: Number(limit) });
      pipeline.push({ $lookup: { from: "users", localField: "userId", foreignField: "_id", as: "user" } });
      pipeline.push({ $unwind: { path: "$user", preserveNullAndEmptyArrays: true } });
      pipeline.push({
        $addFields: {
          id: "$_id",
          ownerName: "$user.name",
          ownerAvatar: "$user.avatarUrl",
          distanceKm: { $round: [{ $divide: ["$distanceMeters", 1000] }, 2] },
        },
      });
      pipeline.push({ $project: { user: 0, __v: 0 } });

      const sitters = await PetSitter.aggregate(pipeline);
      return sendOk(res, 200, { sitters });
    }

    // Normal query
    const filter = { isActive: true, availability: true };
    if (service) filter["services.type"] = service;
    if (species) filter.speciesServed = species;
    if (Number(minRating) > 0) filter.rating = { $gte: Number(minRating) };

    const sitters = await PetSitter.find(filter)
      .sort({ rating: -1 })
      .skip(skip)
      .limit(Number(limit))
      .populate("userId", "name avatarUrl")
      .lean();

    return sendOk(res, 200, { sitters: sitters.map(s => ({ ...s, id: s._id })) });
  } catch (err) {
    console.error("[PetSitter] list error:", err.message);
    return sendError(res, 500, "Bakicilar listelenemedi", "list_error");
  }
}

// GET /me - Kendi bakici profilim
export async function mySitterProfile(req, res) {
  try {
    const userId = req.user.sub;
    const sitter = await PetSitter.findOne({ userId }).lean();
    if (!sitter) return sendError(res, 404, "Bakici profiliniz bulunamadi", "not_found");
    return sendOk(res, 200, { sitter: { ...sitter, id: sitter._id } });
  } catch (err) {
    return sendError(res, 500, "Profil alinamadi", "get_error");
  }
}

// GET /:id - Detay
export async function getSitter(req, res) {
  try {
    const sitter = await PetSitter.findById(req.params.id).populate("userId", "name avatarUrl").lean();
    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");

    // Son yorumlari da getir
    const recentBookings = await SitterBooking.find({
      sitterId: sitter._id,
      status: "completed",
      ownerReview: { $exists: true },
    })
      .sort({ completedAt: -1 })
      .limit(10)
      .populate("petOwnerId", "name avatarUrl")
      .lean();

    return sendOk(res, 200, {
      sitter: { ...sitter, id: sitter._id },
      reviews: recentBookings.map(b => ({
        ownerName: b.petOwnerId?.name,
        ownerAvatar: b.petOwnerId?.avatarUrl,
        rating: b.ownerReview.rating,
        comment: b.ownerReview.comment,
        date: b.completedAt,
      })),
    });
  } catch (err) {
    return sendError(res, 500, "Bakici alinamadi", "get_error");
  }
}

// PUT /:id - Profil guncelle
export async function updateSitter(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await PetSitter.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Bakici bulunamadi", "not_found");
    if (String(doc.userId) !== userId) return sendError(res, 403, "Yetkiniz yok", "forbidden");

    const allowed = ["displayName", "bio", "avatar", "photos", "services", "speciesServed", "experience", "address", "workingHours"];
    for (const key of allowed) {
      if (req.body[key] !== undefined) doc[key] = req.body[key];
    }
    if (req.body.location) {
      const loc = buildLocation(req.body.location);
      if (loc) doc.location = loc;
    }

    await doc.save();
    return sendOk(res, 200, { sitter: doc });
  } catch (err) {
    return sendError(res, 500, "Profil guncellenemedi", "update_error");
  }
}

// PATCH /:id/availability - Musaitlik toggle
export async function toggleAvailability(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await PetSitter.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Bakici bulunamadi", "not_found");
    if (String(doc.userId) !== userId) return sendError(res, 403, "Yetkiniz yok", "forbidden");

    doc.availability = !doc.availability;
    await doc.save();
    return sendOk(res, 200, { availability: doc.availability });
  } catch (err) {
    return sendError(res, 500, "Guncelleme basarisiz", "toggle_error");
  }
}
