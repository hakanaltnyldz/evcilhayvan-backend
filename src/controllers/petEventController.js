import { validationResult } from "express-validator";
import PetEvent from "../models/PetEvent.js";
import EventAttendance from "../models/EventAttendance.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

function buildLocation(bodyLocation) {
  if (bodyLocation?.coordinates?.length === 2) {
    return { type: "Point", coordinates: bodyLocation.coordinates.map(Number) };
  }
  return undefined;
}

// POST / - Etkinlik olustur
export async function createEvent(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());

  try {
    const organizerId = req.user.sub;
    const body = { ...req.body, organizerId };

    const location = buildLocation(body.location);
    if (location) body.location = location; else delete body.location;

    let doc = await PetEvent.create(body);
    doc = await doc.populate("organizerId", "name avatarUrl");

    await recordAudit("event.create", { userId: organizerId, entityType: "PetEvent", entityId: doc.id });
    return sendOk(res, 201, { event: doc });
  } catch (err) {
    console.error("[PetEvent] create error:", err.message);
    return sendError(res, 500, "Etkinlik olusturulamadi", "create_error");
  }
}

// GET / - Liste
export async function listEvents(req, res) {
  try {
    const { lat, lng, radiusKm = 50, category, upcoming = "true", page = 1, limit = 20 } = req.query;
    const skip = (Number(page) - 1) * Number(limit);
    const now = new Date();

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

      const match = { isActive: true, isCancelled: false };
      if (upcoming === "true") match.startDate = { $gte: now };
      if (category) match.category = category;
      pipeline.push({ $match: match });
      pipeline.push({ $sort: { startDate: 1 } });
      pipeline.push({ $skip: skip });
      pipeline.push({ $limit: Number(limit) });
      pipeline.push({ $lookup: { from: "users", localField: "organizerId", foreignField: "_id", as: "organizer" } });
      pipeline.push({ $unwind: { path: "$organizer", preserveNullAndEmptyArrays: true } });
      pipeline.push({
        $addFields: {
          id: "$_id",
          organizerName: "$organizer.name",
          organizerAvatar: "$organizer.avatarUrl",
          distanceKm: { $round: [{ $divide: ["$distanceMeters", 1000] }, 2] },
        },
      });
      pipeline.push({ $project: { organizer: 0, __v: 0 } });

      const events = await PetEvent.aggregate(pipeline);
      return sendOk(res, 200, { events });
    }

    const filter = { isActive: true, isCancelled: false };
    if (upcoming === "true") filter.startDate = { $gte: now };
    if (category) filter.category = category;

    const events = await PetEvent.find(filter)
      .sort({ startDate: 1 })
      .skip(skip)
      .limit(Number(limit))
      .populate("organizerId", "name avatarUrl")
      .lean();

    return sendOk(res, 200, { events: events.map(e => ({ ...e, id: e._id })) });
  } catch (err) {
    console.error("[PetEvent] list error:", err.message);
    return sendError(res, 500, "Etkinlikler listelenemedi", "list_error");
  }
}

// GET /:id - Detay
export async function getEvent(req, res) {
  try {
    const event = await PetEvent.findById(req.params.id)
      .populate("organizerId", "name avatarUrl")
      .lean();
    if (!event) return sendError(res, 404, "Etkinlik bulunamadi", "not_found");

    // Katilimcilar
    const attendees = await EventAttendance.find({ eventId: event._id, status: "going" })
      .populate("userId", "name avatarUrl")
      .limit(20)
      .lean();

    return sendOk(res, 200, {
      event: { ...event, id: event._id },
      attendees: attendees.map(a => ({ userId: a.userId, id: a._id })),
    });
  } catch (err) {
    return sendError(res, 500, "Etkinlik alinamadi", "get_error");
  }
}

// PUT /:id - Guncelle (organizer)
export async function updateEvent(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await PetEvent.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Etkinlik bulunamadi", "not_found");
    if (String(doc.organizerId) !== userId) return sendError(res, 403, "Yetkiniz yok", "forbidden");

    const allowed = ["title", "description", "category", "photos", "coverPhoto", "address", "venueName",
      "startDate", "endDate", "maxAttendees", "isFree", "price", "speciesAllowed", "tags", "externalLink"];
    for (const key of allowed) {
      if (req.body[key] !== undefined) doc[key] = req.body[key];
    }
    if (req.body.location) {
      const loc = buildLocation(req.body.location);
      if (loc) doc.location = loc;
    }

    await doc.save();
    return sendOk(res, 200, { event: doc });
  } catch (err) {
    return sendError(res, 500, "Etkinlik guncellenemedi", "update_error");
  }
}

// PATCH /:id/cancel - Iptal
export async function cancelEvent(req, res) {
  try {
    const userId = req.user.sub;
    const doc = await PetEvent.findById(req.params.id);
    if (!doc) return sendError(res, 404, "Etkinlik bulunamadi", "not_found");
    if (String(doc.organizerId) !== userId) return sendError(res, 403, "Yetkiniz yok", "forbidden");

    doc.isCancelled = true;
    await doc.save();
    return sendOk(res, 200, { message: "Etkinlik iptal edildi" });
  } catch (err) {
    return sendError(res, 500, "Iptal basarisiz", "cancel_error");
  }
}

// POST /:id/attend - Katilim
export async function attendEvent(req, res) {
  try {
    const userId = req.user.sub;
    const { status = "going", petIds = [], note } = req.body;

    const event = await PetEvent.findById(req.params.id);
    if (!event) return sendError(res, 404, "Etkinlik bulunamadi", "not_found");
    if (event.isCancelled) return sendError(res, 400, "Etkinlik iptal edildi", "cancelled");

    // Kapasite kontrol
    if (status === "going" && event.maxAttendees) {
      const goingCount = await EventAttendance.countDocuments({ eventId: event._id, status: "going" });
      if (goingCount >= event.maxAttendees) {
        return sendError(res, 400, "Etkinlik kapasitesi doldu", "full");
      }
    }

    const existing = await EventAttendance.findOne({ eventId: event._id, userId });
    let attendance;

    if (existing) {
      const wasGoing = existing.status === "going";
      existing.status = status;
      existing.petIds = petIds;
      existing.note = note;
      await existing.save();
      attendance = existing;

      // Sayaci guncelle
      if (wasGoing && status !== "going") await PetEvent.findByIdAndUpdate(event._id, { $inc: { attendeeCount: -1 } });
      if (!wasGoing && status === "going") await PetEvent.findByIdAndUpdate(event._id, { $inc: { attendeeCount: 1 } });
    } else {
      attendance = await EventAttendance.create({ eventId: event._id, userId, status, petIds, note });
      if (status === "going") await PetEvent.findByIdAndUpdate(event._id, { $inc: { attendeeCount: 1 } });
    }

    return sendOk(res, 200, { attendance });
  } catch (err) {
    if (err.code === 11000) {
      // Unique index ihlali - guncelle
      return sendError(res, 409, "Katilim zaten mevcut", "conflict");
    }
    console.error("[PetEvent] attend error:", err.message);
    return sendError(res, 500, "Katilim basarisiz", "attend_error");
  }
}

// GET /:id/attendance - Katilimcim var mi?
export async function myAttendance(req, res) {
  try {
    const userId = req.user.sub;
    const attendance = await EventAttendance.findOne({ eventId: req.params.id, userId }).lean();
    return sendOk(res, 200, { attendance: attendance ? { ...attendance, id: attendance._id } : null });
  } catch (err) {
    return sendError(res, 500, "Katilim bilgisi alinamadi", "get_error");
  }
}

// GET /me/attending - Katildigim etkinlikler
export async function myAttendingEvents(req, res) {
  try {
    const userId = req.user.sub;
    const attendances = await EventAttendance.find({ userId, status: "going" })
      .populate({ path: "eventId", populate: { path: "organizerId", select: "name avatarUrl" } })
      .lean();

    const events = attendances
      .filter(a => a.eventId)
      .map(a => ({ ...a.eventId, id: a.eventId._id }));

    return sendOk(res, 200, { events });
  } catch (err) {
    return sendError(res, 500, "Etkinlikler alinamadi", "list_error");
  }
}

// GET /me/organized - Organize ettigim etkinlikler
export async function myOrganizedEvents(req, res) {
  try {
    const organizerId = req.user.sub;
    const events = await PetEvent.find({ organizerId }).sort({ startDate: -1 }).lean();
    return sendOk(res, 200, { events: events.map(e => ({ ...e, id: e._id })) });
  } catch (err) {
    return sendError(res, 500, "Etkinlikler alinamadi", "list_error");
  }
}
