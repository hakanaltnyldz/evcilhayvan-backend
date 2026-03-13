import { validationResult } from "express-validator";
import LostFoundPet from "../models/LostFoundPet.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

function buildLocation(bodyLocation) {
  if (bodyLocation?.coordinates?.length === 2) {
    return {
      type: "Point",
      coordinates: bodyLocation.coordinates.map(Number),
    };
  }
  return undefined;
}

// POST / - Yeni kayip/bulunan ilani olustur
export async function createReport(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());
  }

  try {
    const userId = req.user.sub;
    const body = { ...req.body, userId };

    const location = buildLocation(body.location);
    if (location) {
      body.location = location;
    } else {
      delete body.location;
    }

    let doc = await LostFoundPet.create(body);
    doc = await doc.populate("userId", "name avatarUrl");

    await recordAudit("lostfound.create", {
      userId,
      entityType: "LostFoundPet",
      entityId: doc.id,
      metadata: { type: doc.type },
    });

    // Socket.io broadcast
    const io = req.app.get("io");
    if (io) {
      io.emit("lostfound:new", {
        id: doc.id,
        type: doc.type,
        petName: doc.petName,
        species: doc.species,
        color: doc.color,
        lastSeenAddress: doc.lastSeenAddress,
        photo: doc.photos?.[0],
      });
    }

    return sendOk(res, 201, { report: doc });
  } catch (err) {
    console.error("[LostFound] create error:", err.message);
    return sendError(res, 500, "Ilan olusturulamadi", "create_error");
  }
}

// GET / - Liste + filtre
export async function listReports(req, res) {
  try {
    const { type, species, status = "active", lat, lng, radiusKm = 50, page = 1, limit = 20 } = req.query;

    const hasGeo = lat && lng;
    const skip = (Number(page) - 1) * Number(limit);

    if (hasGeo) {
      // Geo-query ile
      const pipeline = [];

      pipeline.push({
        $geoNear: {
          near: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          distanceField: "distanceMeters",
          spherical: true,
          maxDistance: Number(radiusKm) * 1000,
        },
      });

      const matchFilter = { status: status || "active" };
      if (type) matchFilter.type = type;
      if (species) matchFilter.species = species;
      pipeline.push({ $match: matchFilter });

      pipeline.push({ $sort: { distanceMeters: 1 } });
      pipeline.push({ $skip: skip });
      pipeline.push({ $limit: Number(limit) });
      pipeline.push({
        $lookup: { from: "users", localField: "userId", foreignField: "_id", as: "user" },
      });
      pipeline.push({ $unwind: { path: "$user", preserveNullAndEmptyArrays: true } });
      pipeline.push({
        $addFields: {
          id: "$_id",
          userName: "$user.name",
          userAvatar: "$user.avatarUrl",
          distanceKm: { $round: [{ $divide: ["$distanceMeters", 1000] }, 2] },
        },
      });
      pipeline.push({ $project: { user: 0, __v: 0 } });

      const reports = await LostFoundPet.aggregate(pipeline);
      return sendOk(res, 200, { reports });
    }

    // Normal query (geo yok)
    const filter = { status: status || "active" };
    if (type) filter.type = type;
    if (species) filter.species = species;

    const reports = await LostFoundPet.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .populate("userId", "name avatarUrl")
      .lean();

    // userId'yi userName/userAvatar olarak duzelt
    const mapped = reports.map((r) => ({
      ...r,
      id: r._id,
      userName: r.userId?.name,
      userAvatar: r.userId?.avatarUrl,
    }));

    return sendOk(res, 200, { reports: mapped });
  } catch (err) {
    console.error("[LostFound] list error:", err.message);
    return sendError(res, 500, "Ilanlar listelenemedi", "list_error");
  }
}

// GET /near - Harita icin yakin ilanlar
export async function nearbyReports(req, res) {
  try {
    const { lat, lng, radiusKm = 20 } = req.query;
    if (!lat || !lng) {
      return sendError(res, 400, "lat ve lng parametreleri gerekli", "missing_params");
    }

    const pipeline = [
      {
        $geoNear: {
          near: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          distanceField: "distanceMeters",
          spherical: true,
          maxDistance: Number(radiusKm) * 1000,
        },
      },
      { $match: { status: "active" } },
      { $limit: 100 },
      {
        $project: {
          _id: 1,
          type: 1,
          petName: 1,
          species: 1,
          color: 1,
          photos: { $arrayElemAt: ["$photos", 0] },
          location: 1,
          reward: 1,
          distanceKm: { $round: [{ $divide: ["$distanceMeters", 1000] }, 2] },
        },
      },
    ];

    const reports = await LostFoundPet.aggregate(pipeline);
    const mapped = reports.map((r) => ({ ...r, id: r._id }));
    return sendOk(res, 200, { reports: mapped });
  } catch (err) {
    console.error("[LostFound] nearby error:", err.message);
    return sendError(res, 500, "Yakin ilanlar alinamadi", "nearby_error");
  }
}

// GET /:id - Detay
export async function getReport(req, res) {
  try {
    const doc = await LostFoundPet.findById(req.params.id).populate("userId", "name avatarUrl email").lean();
    if (!doc) return sendError(res, 404, "Ilan bulunamadi", "not_found");

    return sendOk(res, 200, {
      report: {
        ...doc,
        id: doc._id,
        userName: doc.userId?.name,
        userAvatar: doc.userId?.avatarUrl,
        userEmail: doc.userId?.email,
      },
    });
  } catch (err) {
    console.error("[LostFound] get error:", err.message);
    return sendError(res, 500, "Ilan alinamadi", "get_error");
  }
}

// PUT /:id - Guncelle (sahibi)
export async function updateReport(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await LostFoundPet.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Ilan bulunamadi", "not_found");
    if (String(doc.userId) !== userId) {
      return sendError(res, 403, "Bu ilani duzenleme yetkiniz yok", "forbidden");
    }

    const allowed = [
      "petName", "species", "breed", "gender", "color", "ageApprox",
      "description", "photos", "lastSeenDate", "lastSeenAddress",
      "contactPhone", "contactNote", "reward",
    ];
    for (const key of allowed) {
      if (req.body[key] !== undefined) doc[key] = req.body[key];
    }

    if (req.body.location) {
      const loc = buildLocation(req.body.location);
      if (loc) doc.location = loc;
    }

    await doc.save();
    return sendOk(res, 200, { report: doc });
  } catch (err) {
    console.error("[LostFound] update error:", err.message);
    return sendError(res, 500, "Ilan guncellenemedi", "update_error");
  }
}

// PATCH /:id/status - Durum guncelle
export async function updateStatus(req, res) {
  try {
    const userId = req.user.sub;
    const { status } = req.body;

    if (!["reunited", "cancelled"].includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "invalid_status");
    }

    const doc = await LostFoundPet.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Ilan bulunamadi", "not_found");
    if (String(doc.userId) !== userId) {
      return sendError(res, 403, "Bu ilani duzenleme yetkiniz yok", "forbidden");
    }

    doc.status = status;
    if (status === "reunited") doc.resolvedAt = new Date();
    await doc.save();

    await recordAudit("lostfound.status_update", {
      userId,
      entityType: "LostFoundPet",
      entityId: doc.id,
      metadata: { status },
    });

    return sendOk(res, 200, { report: doc });
  } catch (err) {
    console.error("[LostFound] status error:", err.message);
    return sendError(res, 500, "Durum guncellenemedi", "status_error");
  }
}

// DELETE /:id
export async function deleteReport(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await LostFoundPet.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Ilan bulunamadi", "not_found");
    if (String(doc.userId) !== userId) {
      return sendError(res, 403, "Bu ilani silme yetkiniz yok", "forbidden");
    }

    await doc.deleteOne();

    await recordAudit("lostfound.delete", {
      userId,
      entityType: "LostFoundPet",
      entityId: req.params.id,
    });

    return sendOk(res, 200, { message: "Ilan silindi" });
  } catch (err) {
    console.error("[LostFound] delete error:", err.message);
    return sendError(res, 500, "Ilan silinemedi", "delete_error");
  }
}

// GET /me - Kendi ilanlarim
export async function myReports(req, res) {
  try {
    const userId = req.user.sub;
    const reports = await LostFoundPet.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    const mapped = reports.map((r) => ({ ...r, id: r._id }));
    return sendOk(res, 200, { reports: mapped });
  } catch (err) {
    console.error("[LostFound] myReports error:", err.message);
    return sendError(res, 500, "Ilanlar alinamadi", "my_reports_error");
  }
}
