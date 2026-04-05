import mongoose from "mongoose";
import Veterinary from "../models/Veterinary.js";
import User from "../models/User.js";
import Conversation from "../models/Conversation.js";
import VetClaimRequest from "../models/VetClaimRequest.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

// OpenStreetMap Overpass API ile yakın veteriner kliniği ara (ücretsiz)
async function osmSearchVets(lat, lng, radiusMeters = 5000) {
  const query = `[out:json][timeout:10];
(
  node["amenity"="veterinary"](around:${radiusMeters},${lat},${lng});
  way["amenity"="veterinary"](around:${radiusMeters},${lat},${lng});
);
out center body;`;
  const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(12000) });
  if (!res.ok) throw new Error("Overpass API hatası: " + res.status);
  const data = await res.json();
  return data.elements || [];
}

function mapOsmResultToVet(el, lat, lng) {
  const tags = el.tags || {};
  const elLat = el.lat ?? el.center?.lat ?? lat;
  const elLng = el.lon ?? el.center?.lon ?? lng;
  return {
    name: tags.name || tags["name:tr"] || "Veteriner Kliniği",
    address: [tags["addr:street"], tags["addr:housenumber"], tags["addr:city"]]
      .filter(Boolean).join(", ") || tags["addr:full"] || null,
    phone: tags.phone || tags["contact:phone"] || null,
    website: tags.website || tags["contact:website"] || null,
    location: { type: "Point", coordinates: [elLng, elLat] },
    source: "osm",
    isActive: true,
  };
}

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

// GET /api/veterinaries/google-search  (artık OSM Overpass kullanıyor)
export async function googleSearchVets(req, res) {
  try {
    const { lat, lng, radiusKm = 5 } = req.query;
    if (!lat || !lng) {
      return sendError(res, 400, "lat ve lng gerekli", "validation_error");
    }

    const radiusMeters = Number(radiusKm) * 1000;
    const osmResults = await osmSearchVets(Number(lat), Number(lng), radiusMeters);

    // OSM sonuçlarını DB'ye upsert et (osmId benzersiz anahtar)
    for (const el of osmResults) {
      if (!el.id) continue;
      const osmId = String(el.id);
      const mapped = mapOsmResultToVet(el, Number(lat), Number(lng));
      await Veterinary.findOneAndUpdate(
        { googlePlaceId: `osm_${osmId}` },
        { $set: { ...mapped, googlePlaceId: `osm_${osmId}` } },
        { upsert: true }
      );
    }

    // Tüm yakın kayıtları döndür
    const vets = await Veterinary.find({
      isActive: true,
      location: {
        $near: {
          $geometry: { type: "Point", coordinates: [Number(lng), Number(lat)] },
          $maxDistance: radiusMeters,
        },
      },
    }).limit(100);

    return sendOk(res, 200, { vets, osmResultCount: osmResults.length });
  } catch (err) {
    console.error("[googleSearchVets/OSM]", err);
    // Fallback: sadece DB'deki kayıtları döndür
    try {
      const vets = await Veterinary.find({ isActive: true }).limit(50);
      return sendOk(res, 200, { vets, osmResultCount: 0 });
    } catch {
      return sendError(res, 500, "Veteriner arama basarisiz", "internal_error", err.message);
    }
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
// Kullanici sahiplenme talebi oluşturur → admin onayı bekler
// Body: { fullName, phone, role, note }
export async function claimVetProfile(req, res) {
  try {
    const { id } = req.params;
    const userId = req.user.sub;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const { fullName, phone, role: claimRole, note } = req.body;
    if (!fullName || !phone || !claimRole) {
      return sendError(res, 400, "Ad, telefon ve rol bilgisi gerekli", "validation_error");
    }

    const vet = await Veterinary.findById(id);
    if (!vet || vet.isActive === false) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    // Zaten sahiplenilmiş mi?
    if (vet.userId && String(vet.userId) !== String(userId)) {
      return sendError(res, 409, "Bu profil zaten baska bir hesaba bagli", "already_claimed");
    }

    // Zaten bekleyen bir talep var mı?
    const existing = await VetClaimRequest.findOne({ vetId: id, userId, status: "pending" });
    if (existing) {
      return sendError(res, 409, "Bu klinik icin zaten bekleyen bir talebiniz var", "request_exists");
    }

    const claimReq = await VetClaimRequest.create({
      vetId: id,
      userId,
      fullName,
      phone,
      role: claimRole,
      note: note || "",
    });

    await recordAudit("veterinary.claim_request", {
      userId,
      entityType: "veterinary",
      entityId: id,
      metadata: { claimId: claimReq._id.toString() },
    });

    return sendOk(res, 201, {
      claimRequest: claimReq,
      message: "Sahiplenme talebiniz alindi. Admin onayinin ardından profilinize atanacak.",
    });
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 409, "Bu klinik icin zaten bir talebiniz bulunuyor", "request_exists");
    }
    console.error("[claimVetProfile]", err);
    return sendError(res, 500, "Profil sahiplenme basarisiz", "internal_error", err.message);
  }
}

// GET /api/veterinaries/:id/claim-status
// Kullanicinin bu klinik icin talebi var mi ve durumu nedir?
export async function getVetClaimStatus(req, res) {
  try {
    const { id } = req.params;
    const userId = req.user.sub;
    const claimReq = await VetClaimRequest.findOne({ vetId: id, userId }).sort({ createdAt: -1 });
    return sendOk(res, 200, { claimRequest: claimReq || null });
  } catch (err) {
    return sendError(res, 500, "Talep durumu alinamadi", "internal_error", err.message);
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

// POST /api/veterinaries/:id/fetch-photos
// Google Places API'dan fotoğrafları çekip vet.photos dizisine ekler
export async function fetchVetPhotosFromGoogle(req, res) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const vet = await Veterinary.findById(id);
    if (!vet || vet.isActive === false) {
      return sendError(res, 404, "Veteriner bulunamadi", "vet_not_found");
    }

    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    if (!apiKey) {
      return sendError(res, 503, "Google Places API anahtarı tanımlı değil", "config_error");
    }

    // placeId yoksa Places API ile ara
    let placeId = vet.googlePlaceId;
    if (!placeId && vet.name) {
      const query = encodeURIComponent(`${vet.name} ${vet.address || ""}`);
      const searchUrl = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${query}&inputtype=textquery&fields=place_id&key=${apiKey}`;
      const searchRes = await fetch(searchUrl, { signal: AbortSignal.timeout(8000) });
      const searchData = await searchRes.json();
      placeId = searchData.candidates?.[0]?.place_id;
      if (placeId) {
        vet.googlePlaceId = placeId;
      }
    }

    if (!placeId) {
      return sendError(res, 404, "Google Places ID bulunamadı", "place_not_found");
    }

    // Place Details → photos dizisi
    const detailUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=photos,rating,user_ratings_total&key=${apiKey}`;
    const detailRes = await fetch(detailUrl, { signal: AbortSignal.timeout(8000) });
    const detailData = await detailRes.json();

    if (detailData.status !== "OK") {
      return sendError(res, 502, `Google Places hatası: ${detailData.status}`, "places_error");
    }

    const placePhotos = detailData.result?.photos || [];
    // Her fotoğraf için Photo URL oluştur (max 800px genişlik)
    const photoUrls = placePhotos.slice(0, 8).map(
      (p) => `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${p.photo_reference}&key=${apiKey}`
    );

    // Mevcut fotoğraflarla birleştir, tekrarları at
    const merged = [...new Set([...photoUrls, ...vet.photos])];
    vet.photos = merged.slice(0, 10); // max 10 fotoğraf

    // Google rating güncelle
    if (detailData.result?.rating) vet.googleRating = detailData.result.rating;
    if (detailData.result?.user_ratings_total) vet.googleReviewCount = detailData.result.user_ratings_total;

    await vet.save();

    return sendOk(res, 200, {
      message: `${photoUrls.length} fotoğraf eklendi`,
      photos: vet.photos,
      googleRating: vet.googleRating,
      googleReviewCount: vet.googleReviewCount,
    });
  } catch (err) {
    console.error("[fetchVetPhotosFromGoogle]", err);
    return sendError(res, 500, "Fotoğraflar alınamadı", "internal_error", err.message);
  }
}
