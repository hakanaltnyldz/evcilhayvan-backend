import mongoose from "mongoose";
import Veterinary from "../models/Veterinary.js";
import User from "../models/User.js";
import Conversation from "../models/Conversation.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import {
  searchNearbyVets as googleSearch,
  mapGoogleResultToVet,
} from "../services/googlePlacesService.js";

// GET /api/veterinaries
export async function listVets(req, res) {
  try {
    const { lat, lng, radiusKm = 10, q, species, page = 1, limit = 20 } = req.query;
    const filter = { isActive: true };

    if (species) {
      filter.speciesServed = species;
    }

    let query;
    if (lat && lng) {
      // $near ve $text aynı anda kullanılamaz, geo öncelikli
      filter.location = {
        $near: {
          $geometry: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          $maxDistance: Number(radiusKm) * 1000,
        },
      };
      // q varsa name'e regex ile filtrele
      if (q) {
        filter.name = { $regex: String(q), $options: "i" };
      }
      query = Veterinary.find(filter);
    } else {
      if (q) {
        filter.$text = { $search: String(q) };
      }
      query = Veterinary.find(filter).sort(q ? { score: { $meta: "textScore" } } : { createdAt: -1 });
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      query.skip(skip).limit(Number(limit)),
      Veterinary.countDocuments(filter),
    ]);

    return sendOk(res, 200, {
      vets: items,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + items.length < total,
    });
  } catch (err) {
    console.error("[listVets]", err);
    return sendError(res, 500, "Veterinerler yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/veterinaries/nearby
export async function getNearbyVets(req, res) {
  try {
    const { lat, lng, radiusKm = 5, limit = 50 } = req.query;
    if (!lat || !lng) {
      return sendError(res, 400, "lat ve lng gerekli", "validation_error");
    }

    const vets = await Veterinary.find({
      isActive: true,
      location: {
        $near: {
          $geometry: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          $maxDistance: Number(radiusKm) * 1000,
        },
      },
    }).limit(Number(limit));

    return sendOk(res, 200, { vets });
  } catch (err) {
    console.error("[getNearbyVets]", err);
    return sendError(res, 500, "Yakin veterinerler yuklenemedi", "internal_error", err.message);
  }
}

// GET /api/veterinaries/google-search
export async function googleSearchVets(req, res) {
  try {
    const { lat, lng, radiusKm = 5 } = req.query;
    if (!lat || !lng) {
      return sendError(res, 400, "lat ve lng gerekli", "validation_error");
    }

    const radiusMeters = Number(radiusKm) * 1000;
    const googleResults = await googleSearch(Number(lat), Number(lng), radiusMeters);

    // Google sonuclarini DB'ye upsert et
    const upsertedIds = [];
    for (const result of googleResults) {
      if (!result.place_id) continue;
      const mapped = mapGoogleResultToVet(result);
      const vet = await Veterinary.findOneAndUpdate(
        { googlePlaceId: result.place_id },
        { $set: mapped },
        { upsert: true, new: true }
      );
      upsertedIds.push(vet._id);
    }

    // Hem Google hem de manuel kayitlari getir
    const vets = await Veterinary.find({
      isActive: true,
      location: {
        $near: {
          $geometry: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          $maxDistance: radiusMeters,
        },
      },
    }).limit(100);

    return sendOk(res, 200, { vets, googleResultCount: googleResults.length });
  } catch (err) {
    console.error("[googleSearchVets]", err);
    return sendError(res, 500, "Google arama basarisiz", "internal_error", err.message);
  }
}

// GET /api/veterinaries/:id
export async function getVet(req, res) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const vet = await Veterinary.findById(id);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    return sendOk(res, 200, { vet });
  } catch (err) {
    console.error("[getVet]", err);
    return sendError(res, 500, "Veteriner detayi alinamadi", "internal_error", err.message);
  }
}

// POST /api/veterinaries
export async function createVet(req, res) {
  try {
    const userId = req.user.sub;
    const {
      name, address, phone, email, website, description, photos,
      services, speciesServed, acceptsOnlineAppointments,
      appointmentSlotMinutes, workingHours, location,
    } = req.body;

    if (!name || !name.trim()) {
      return sendError(res, 400, "Veteriner adi gerekli", "validation_error");
    }

    const vetData = {
      name: name.trim(),
      address, phone, email, website, description, photos,
      services: services || [],
      speciesServed: speciesServed || ["dog", "cat", "bird", "fish", "rodent", "other"],
      acceptsOnlineAppointments: acceptsOnlineAppointments || false,
      appointmentSlotMinutes: appointmentSlotMinutes || 30,
      workingHours: workingHours || [],
      source: "manual",
      registeredBy: userId,
      isVerified: false,
      isActive: true,
    };

    if (location?.coordinates?.length === 2) {
      vetData.location = {
        type: "Point",
        coordinates: location.coordinates.map(Number),
      };
    }

    const vet = await Veterinary.create(vetData);

    await recordAudit("veterinary.create", {
      userId,
      entityType: "veterinary",
      entityId: vet._id.toString(),
    });

    return sendOk(res, 201, { vet });
  } catch (err) {
    console.error("[createVet]", err);
    return sendError(res, 500, "Veteriner olusturulamadi", "internal_error", err.message);
  }
}

// PUT /api/veterinaries/:id
export async function updateVet(req, res) {
  try {
    const { id } = req.params;
    const userId = req.user.sub;
    const isAdmin = req.user.role === "admin";

    const vet = await Veterinary.findById(id);
    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");

    if (!isAdmin && String(vet.registeredBy) !== String(userId)) {
      return sendError(res, 403, "Bu veterineri guncelleme yetkiniz yok", "forbidden");
    }

    const update = { ...req.body };
    if (update.location?.coordinates?.length === 2) {
      update.location = {
        type: "Point",
        coordinates: update.location.coordinates.map(Number),
      };
    }

    Object.assign(vet, update);
    await vet.save();

    await recordAudit("veterinary.update", {
      userId,
      entityType: "veterinary",
      entityId: id,
    });

    return sendOk(res, 200, { vet });
  } catch (err) {
    console.error("[updateVet]", err);
    return sendError(res, 500, "Veteriner guncellenemedi", "internal_error", err.message);
  }
}

// DELETE /api/veterinaries/:id (admin only)
export async function deleteVet(req, res) {
  try {
    const { id } = req.params;
    const vet = await Veterinary.findById(id);
    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");

    vet.isActive = false;
    await vet.save();

    await recordAudit("veterinary.delete", {
      userId: req.user.sub,
      entityType: "veterinary",
      entityId: id,
    });

    return sendOk(res, 200, { deleted: true });
  } catch (err) {
    console.error("[deleteVet]", err);
    return sendError(res, 500, "Veteriner silinemedi", "internal_error", err.message);
  }
}

// PATCH /api/veterinaries/:id/verify (admin only)
export async function verifyVet(req, res) {
  try {
    const { id } = req.params;
    const vet = await Veterinary.findById(id);
    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");

    vet.isVerified = true;
    await vet.save();

    await recordAudit("veterinary.verify", {
      userId: req.user.sub,
      entityType: "veterinary",
      entityId: id,
    });

    return sendOk(res, 200, { vet });
  } catch (err) {
    console.error("[verifyVet]", err);
    return sendError(res, 500, "Dogrulama basarisiz", "internal_error", err.message);
  }
}

// POST /api/veterinaries/:id/claim
// Kullanici kendi hesabini vet profiliyle eslestiriyor → role = vet, userId set
export async function claimVetProfile(req, res) {
  try {
    const { id } = req.params;
    const userId = req.user.sub;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const vet = await Veterinary.findById(id);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    // Baska biri zaten sahiplenmiş mi?
    if (vet.userId && String(vet.userId) !== String(userId)) {
      return sendError(res, 409, "Bu profil zaten baska bir hesaba bagli", "already_claimed");
    }

    // Vet profiline userId bağla
    vet.userId = userId;
    await vet.save();

    // Kullanici rolünü vet yap
    const user = await User.findById(userId);
    if (user && user.role === "user") {
      user.role = "vet";
      await user.save();
    }

    await recordAudit("veterinary.claim", {
      userId,
      entityType: "veterinary",
      entityId: id,
    });

    return sendOk(res, 200, { vet, message: "Profil basariyla sahiplenildi" });
  } catch (err) {
    console.error("[claimVetProfile]", err);
    return sendError(res, 500, "Profil sahiplenme basarisiz", "internal_error", err.message);
  }
}

// POST /api/veterinaries/:id/conversation
// Vet'e mesaj gönderebilmek için conversation oluştur veya mevcut olanı getir
export async function startVetConversation(req, res) {
  try {
    const { id } = req.params;
    const userId = req.user.sub;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const vet = await Veterinary.findById(id);
    if (!vet || !vet.isActive) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    if (!vet.userId) {
      return sendError(res, 400, "Bu veteriner henuz sisteme kayitli degil", "vet_not_registered");
    }

    const vetUserId = String(vet.userId);
    const myUserId = String(userId);

    if (vetUserId === myUserId) {
      return sendError(res, 400, "Kendinize mesaj atamazsiniz", "self_message");
    }

    // Mevcut conversation var mı?
    let conversation = await Conversation.findOne({
      participants: { $all: [myUserId, vetUserId], $size: 2 },
      contextType: "vet",
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [myUserId, vetUserId],
        contextType: "vet",
        contextId: vet._id,
        lastMessage: "",
        lastMessageAt: new Date(),
      });
    }

    const populated = await conversation.populate("participants", "name avatarUrl email");

    return sendOk(res, 200, { conversation: populated });
  } catch (err) {
    console.error("[startVetConversation]", err);
    return sendError(res, 500, "Sohbet baslatila madi", "internal_error", err.message);
  }
}
