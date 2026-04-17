import { validationResult } from "express-validator";
import mongoose from "mongoose";
import Pet from "../models/Pet.js";
import Interaction from "../models/Interaction.js";
import MatchRequest from "../models/MatchRequest.js";
import Conversation from "../models/Conversation.js";
import HealthRecord from "../models/HealthRecord.js";
import Appointment from "../models/Appointment.js";
import SitterBooking from "../models/SitterBooking.js";
import VaccinationRecord from "../models/VaccinationRecord.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import { storageService } from "../services/storageService.js";

function buildLocation(bodyLocation) {
  if (bodyLocation?.coordinates?.length === 2) {
    return {
      type: "Point",
      coordinates: bodyLocation.coordinates.map(Number),
    };
  }
  return undefined;
}

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function buildHealthTimelineEvent(record) {
  switch (record.type) {
    case "weight":
      return {
        type: "health",
        title: `Kilo kaydi${record.weightKg ? `: ${record.weightKg} kg` : ""}`,
        icon: "monitor_weight",
      };
    case "medication":
      return {
        type: "health",
        title: record.medicationName
          ? `Ilac: ${record.medicationName}`
          : "Ilac takibi",
        icon: "medication",
      };
    case "vet_visit":
      return {
        type: "health",
        title: record.vetName ? `Veteriner: ${record.vetName}` : "Veteriner ziyareti",
        icon: "medical_services",
      };
    default:
      return {
        type: "health",
        title: "Saglik notu",
        icon: "notes",
      };
  }
}

function buildDaysUntilLabel(days) {
  if (days <= 0) return "bugün";
  if (days === 1) return "yarın";
  return `${days} gün sonra`;
}

// GET /api/pets/feed
export async function getPetFeed(req, res) {
  try {
    const userId = req.user.sub;
    const { page = 1, limit = 10 } = req.query;

    const interactions = await Interaction.find({ fromUser: userId }).select("toPet");
    const interactedPetIds = interactions.map((interaction) => interaction.toPet);

    const filter = {
      isActive: true,
      ownerId: { $ne: userId },
      _id: { $nin: interactedPetIds },
    };

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Pet.find(filter)
        .populate("ownerId", "name avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Pet.countDocuments(filter),
    ]);

    return sendOk(res, 200, {
      items,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + items.length < total,
    });
  } catch (err) {
    console.error("[getPetFeed]", err);
    return sendError(res, 500, "Akis yuklenemedi", "internal_error", err.message);
  }
}

// POST /api/pets
export async function createPet(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());
    }

    const ownerId = req.user.sub;
    const body = { ...req.body, ownerId };
    const location = buildLocation(body.location);
    if (location) {
      body.location = location;
    } else {
      delete body.location;
    }

    if (Array.isArray(body.images) && !body.photos) {
      body.photos = body.images;
    }
    if (body.advertType) {
      const normalizedType = String(body.advertType).toLowerCase();
      if (["adoption", "mating"].includes(normalizedType)) {
        body.advertType = normalizedType;
      }
    }
    if (!body.advertType) {
      body.advertType = "adoption";
    }

    body.isActive = true;

    let pet = await Pet.create(body);
    pet = await pet.populate("ownerId", "name avatarUrl");

    await recordAudit("pet.create", {
      userId: ownerId,
      entityType: "pet",
      entityId: pet.id || pet._id,
    }).catch((e) => console.error("[createPet] audit error", e.message));

    return sendOk(res, 201, { pet });
  } catch (err) {
    console.error("[createPet]", err);
    return sendError(res, 500, "Evcil hayvan olusturulamadi", "internal_error");
  }
}

// GET /api/pets/me
export async function myPets(req, res) {
  try {
    if (!req.user?.sub) {
      return sendError(res, 401, "Gecersiz token", "auth_required");
    }
    const ownerId = req.user.sub;
    if (!mongoose.Types.ObjectId.isValid(ownerId)) {
      return sendError(res, 400, "Gecersiz kullanici ID", "validation_error");
    }
    const pets = await Pet.find({ ownerId })
      .populate("ownerId", "name avatarUrl")
      .sort({ createdAt: -1 });
    return sendOk(res, 200, { pets });
  } catch (err) {
    console.error("[myPets]", err);
    return sendError(res, 500, "Ilanlar alinirken hata olustu", "internal_error", err.message);
  }
}

// GET /api/my-adverts
export async function myAdverts(req, res) {
  try {
    if (!req.user?.sub) {
      return sendError(res, 401, "Gecersiz token", "auth_required");
    }
    const ownerId = req.user.sub;
    if (!mongoose.Types.ObjectId.isValid(ownerId)) {
      return sendError(res, 400, "Gecersiz kullanici ID", "validation_error");
    }
    const { type } = req.query;
    const filter = { ownerId, isActive: true };
    if (type) {
      const normalizedType = String(type).toLowerCase();
      if (["adoption", "mating"].includes(normalizedType)) {
        filter.advertType = normalizedType;
      }
    }
    const pets = await Pet.find(filter)
      .populate("ownerId", "name avatarUrl")
      .sort({ createdAt: -1 });
    return sendOk(res, 200, { result: pets, pets, count: pets.length });
  } catch (err) {
    console.error("[myAdverts]", err);
    return sendError(res, 500, "Ilanlar alinirken hata olustu", "internal_error", err.message);
  }
}

// PUT /api/pets/:id
export async function updatePet(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());
    }
    const { id } = req.params;
    const isAdmin = req.user.role === "admin";
    const pet = await Pet.findById(id);
    if (!pet) {
      return sendError(res, 404, "Pet bulunamadi", "pet_not_found");
    }
    if (!isAdmin && String(pet.ownerId) !== String(req.user.sub)) {
      return sendError(res, 403, "Bu ilan size ait degil", "forbidden");
    }

    const update = { ...req.body };
    const location = buildLocation(update.location);
    if (location) {
      update.location = location;
    } else if (update.location) {
      delete update.location;
    }

    if (Array.isArray(update.images) && !update.photos) {
      update.photos = update.images;
    }
    if (update.advertType) {
      const normalizedType = String(update.advertType).toLowerCase();
      if (["adoption", "mating"].includes(normalizedType)) {
        update.advertType = normalizedType;
      } else {
        delete update.advertType;
      }
    }

    Object.assign(pet, update);
    const saved = await pet.save();
    await saved.populate("ownerId", "name avatarUrl");

    await recordAudit("pet.update", {
      userId: req.user.sub,
      entityType: "pet",
      entityId: saved.id || saved._id,
    });

    return sendOk(res, 200, { pet: saved });
  } catch (err) {
    console.error("[updatePet]", err);
    return sendError(res, 500, "Ilan guncellenemedi", "internal_error", err.message);
  }
}

// GET /api/pets
export async function listPets(req, res) {
  try {
    const {
      species,
      breed,
      gender,
      vaccinated,
      q,
      startsWith,
      minAgeMonths,
      maxAgeMonths,
      page = 1,
      limit = 10,
      type,
      lat,
      lng,
      radiusKm,
    } = req.query;
    const filter = { isActive: true };
    if (species) filter.species = species;
    if (breed) filter.breed = { $regex: new RegExp(`^${escapeRegex(breed)}$`, "i") };
    if (gender && ["male", "female", "unknown"].includes(String(gender))) {
      filter.gender = String(gender);
    }
    if (type) {
      const normalizedType = String(type).toLowerCase();
      if (["adoption", "mating"].includes(normalizedType)) {
        filter.advertType = normalizedType;
      }
    }
    if (typeof vaccinated !== "undefined") filter.vaccinated = vaccinated === "true";
    const minAge = Number(minAgeMonths);
    const maxAge = Number(maxAgeMonths);
    if (!Number.isNaN(minAge) || !Number.isNaN(maxAge)) {
      filter.ageMonths = {};
      if (!Number.isNaN(minAge)) filter.ageMonths.$gte = minAge;
      if (!Number.isNaN(maxAge)) filter.ageMonths.$lte = maxAge;
    }
    if (startsWith) {
      filter.name = { $regex: new RegExp(`^${escapeRegex(startsWith)}`, "i") };
    }
    if (q) {
      filter.$text = { $search: String(q) };
    }
    if (lat && lng) {
      const radius = Number(radiusKm) || 25;
      filter.location = {
        $nearSphere: {
          $geometry: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          $maxDistance: radius * 1000,
        },
      };
    }
    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Pet.find(filter)
        .populate("ownerId", "name avatarUrl")
        .sort(q ? { score: { $meta: "textScore" } } : { createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      Pet.countDocuments(filter),
    ]);
    return sendOk(res, 200, {
      items,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + items.length < total,
    });
  } catch (err) {
    return sendError(res, 500, "Ilanlar yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/pets/:id
export async function getPet(req, res) {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz ilan ID", "validation_error");
    }

    const pet = await Pet.findById(id).populate("ownerId", "name avatarUrl");
    if (!pet || !pet.isActive) {
      return sendError(res, 404, "Ilan bulunamadi", "pet_not_found");
    }
    await Pet.findByIdAndUpdate(id, { $inc: { viewCount: 1 } });

    return sendOk(res, 200, { pet });
  } catch (err) {
    console.error("[getPet]", err);
    return sendError(res, 500, "Ilan detayi alinamadi", "internal_error", err.message);
  }
}

// GET /api/pets/:id/timeline
export async function getPetTimeline(req, res) {
  try {
    const { id } = req.params;
    const ownerId = req.user.sub;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz ilan ID", "validation_error");
    }

    const pet = await Pet.findOne({ _id: id, ownerId }).select("name");
    if (!pet) {
      return sendError(res, 404, "Pet bulunamadi veya size ait degil", "not_found");
    }

    const [healthRecords, appointments, bookings] = await Promise.all([
      HealthRecord.find({ petId: id }).sort({ date: -1 }).limit(20).lean(),
      Appointment.find({ petId: id }).sort({ date: -1 }).limit(10).lean(),
      SitterBooking.find({ petId: id }).sort({ startDate: -1 }).limit(10).lean(),
    ]);

    const timeline = [
      ...healthRecords.map((record) => {
        const event = buildHealthTimelineEvent(record);
        return {
          id: String(record._id),
          ...event,
          date: record.date,
          subtitle: record.notes || record.diagnosis || record.frequency || null,
        };
      }),
      ...appointments.map((appointment) => ({
        id: String(appointment._id),
        type: "appointment",
        title: appointment.reason?.trim()
          ? `Randevu: ${appointment.reason.trim()}`
          : "Veteriner randevusu",
        date: appointment.date,
        subtitle: appointment.notes || appointment.status || null,
        icon: "event_available",
      })),
      ...bookings.map((booking) => ({
        id: String(booking._id),
        type: "booking",
        title: `Bakici rezervasyonu: ${booking.serviceType}`,
        date: booking.startDate,
        subtitle: booking.status || null,
        icon: "pets",
      })),
    ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    return sendOk(res, 200, {
      petName: pet.name,
      timeline,
    });
  } catch (err) {
    console.error("[getPetTimeline]", err);
    return sendError(res, 500, "Zaman cizelgesi alinamadi", "internal_error", err.message);
  }
}

// GET /api/pets/health-summary
export async function getPetHealthSummary(req, res) {
  try {
    const ownerId = req.user.sub;
    const now = new Date();
    const thirtyDaysLater = new Date(now);
    thirtyDaysLater.setDate(thirtyDaysLater.getDate() + 30);

    const pets = await Pet.find({ ownerId, isActive: true })
      .select("name photos images")
      .sort({ createdAt: -1 })
      .lean();

    const summary = await Promise.all(
      pets.map(async (pet) => {
        const [vaccinations, nextAppointment, lastWeight] = await Promise.all([
          VaccinationRecord.find({
            petId: pet._id,
            nextDueDate: { $gte: now, $lte: thirtyDaysLater },
          })
            .sort({ nextDueDate: 1 })
            .limit(3)
            .lean(),
          Appointment.find({
            petId: pet._id,
            date: { $gte: now },
            status: { $in: ["pending", "confirmed"] },
          })
            .sort({ date: 1 })
            .limit(1)
            .lean(),
          HealthRecord.findOne({
            petId: pet._id,
            type: "weight",
            weightKg: { $ne: null },
          })
            .sort({ date: -1 })
            .lean(),
        ]);

        const alerts = [];
        let healthStatus = "iyi";

        vaccinations.forEach((record) => {
          const daysUntil = Math.ceil(
            (new Date(record.nextDueDate).getTime() - now.getTime()) /
              (1000 * 60 * 60 * 24)
          );
          if (daysUntil <= 7) {
            healthStatus = "acil";
          } else if (healthStatus !== "acil") {
            healthStatus = "dikkat";
          }
          alerts.push({
            type: "vaccination",
            text: `${record.vaccineName} aşısı ${buildDaysUntilLabel(daysUntil)}`,
            date: record.nextDueDate,
          });
        });

        if (nextAppointment) {
          const appointmentDays = Math.ceil(
            (new Date(nextAppointment.date).getTime() - now.getTime()) /
              (1000 * 60 * 60 * 24)
          );
          if (healthStatus === "iyi" && appointmentDays <= 2) {
            healthStatus = "dikkat";
          }
          alerts.push({
            type: "appointment",
            text: `Randevu ${buildDaysUntilLabel(appointmentDays)}`,
            date: nextAppointment.date,
          });
        }

        return {
          petId: String(pet._id),
          petName: pet.name,
          photo: pet.photos?.[0] || pet.images?.[0] || null,
          healthStatus,
          alerts,
          weightKg: lastWeight?.weightKg ?? null,
        };
      })
    );

    return sendOk(res, 200, { summary });
  } catch (err) {
    console.error("[getPetHealthSummary]", err);
    return sendError(
      res,
      500,
      "Saglik ozeti alinamadi",
      "internal_error",
      err.message
    );
  }
}

// DELETE /api/pets/:id
export async function deletePet(req, res) {
  try {
    const { id } = req.params;
    const filter = { _id: id };
    if (req.user.role !== "admin") {
      filter.ownerId = req.user.sub;
    }

    const pet = await Pet.findOne(filter);
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya yetkiniz yok", "pet_not_found");

    // Soft delete: ilanı pasife al
    pet.isActive = false;
    await pet.save();

    // İlişkili pending MatchRequest'leri iptal et
    await MatchRequest.updateMany(
      {
        $or: [{ advertId: id }, { fromAdvertId: id }],
        status: "pending",
      },
      { $set: { status: "cancelled" } }
    );

    // Conversation'lardaki relatedPet referansını temizle (conversation silinmez, sadece referans kaldırılır)
    await Conversation.updateMany(
      { $or: [{ relatedPet: id }, { contextId: id }] },
      { $set: { relatedPet: null, contextId: null } }
    );

    // İlişkili interaction'ları temizle
    await Interaction.deleteMany({ toPet: id });

    await recordAudit("pet.delete", {
      userId: req.user.sub,
      entityType: "pet",
      entityId: id,
    });

    return sendOk(res, 200, { deleted: true });
  } catch (err) {
    console.error("[deletePet]", err);
    return sendError(res, 500, "Ilan silinemedi", "internal_error", err.message);
  }
}

// POST /api/pets/:id/images
export async function uploadPetImage(req, res) {
  try {
    const { id } = req.params;
    const filter = { _id: id };
    if (req.user.role !== "admin") {
      filter.ownerId = req.user.sub;
    }
    const pet = await Pet.findOne(filter);
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya yetkiniz yok", "pet_not_found");
    if (!req.file) return sendError(res, 400, "Dosya gerekli", "file_required");
    const publicPath = await storageService.save(req.file);
    pet.images = [...(pet.images || []), publicPath];
    if (!pet.photos) pet.photos = [];
    pet.photos = [...pet.photos, publicPath];
    await pet.save();

    await recordAudit("pet.media.upload", {
      userId: req.user.sub,
      entityType: "pet",
      entityId: id,
      metadata: { type: "image", url: publicPath },
    });

    return sendOk(res, 201, { url: publicPath, images: pet.images, photos: pet.photos });
  } catch (err) {
    console.error("[uploadPetImage]", err);
    return sendError(res, 500, "Resim yuklenemedi", "internal_error", err.message);
  }
}

// POST /api/pets/:id/videos
export async function uploadPetVideo(req, res) {
  try {
    const { id } = req.params;
    const filter = { _id: id };
    if (req.user.role !== "admin") {
      filter.ownerId = req.user.sub;
    }
    const pet = await Pet.findOne(filter);
    if (!pet) return sendError(res, 404, "Pet bulunamadi veya yetkiniz yok", "pet_not_found");
    if (!req.file) return sendError(res, 400, "Dosya gerekli", "file_required");
    const publicPath = await storageService.save(req.file);
    pet.videos = [...(pet.videos || []), publicPath];
    await pet.save();

    await recordAudit("pet.media.upload", {
      userId: req.user.sub,
      entityType: "pet",
      entityId: id,
      metadata: { type: "video", url: publicPath },
    });

    return sendOk(res, 201, { url: publicPath, videos: pet.videos });
  } catch (err) {
    console.error("[uploadPetVideo]", err);
    return sendError(res, 500, "Video yuklenemedi", "internal_error", err.message);
  }
}
