// src/routes/sitterRequestRoutes.js
import { Router } from "express";
import mongoose from "mongoose";
import { authRequired } from "../middlewares/auth.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import SitterRequest from "../models/SitterRequest.js";
import Conversation from "../models/Conversation.js";

const router = Router();

// POST /api/sitter-requests — Evcil hayvan sahibi bakıcı ilanı açar
router.post("/", authRequired(), async (req, res) => {
  try {
    const userId = req.user.sub;
    const { petTypes, serviceType, startDate, endDate, location, description } = req.body;

    if (!serviceType) return sendError(res, 400, "serviceType zorunlu", "validation_error");
    if (!startDate || !endDate) return sendError(res, 400, "startDate ve endDate zorunlu", "validation_error");
    if (new Date(startDate) > new Date(endDate)) {
      return sendError(res, 400, "startDate endDate'den büyük olamaz", "validation_error");
    }

    const request = await SitterRequest.create({
      owner: userId,
      petTypes: petTypes || ["dog"],
      serviceType,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      location: location || undefined,
      description: description || "",
    });

    const populated = await SitterRequest.findById(request._id).populate("owner", "name avatarUrl");

    return sendOk(res, 201, { request: populated });
  } catch (err) {
    return sendError(res, 500, "İlan oluşturulamadı", "internal_error", err.message);
  }
});

// GET /api/sitter-requests — Açık ilanları listele (bakıcılar için)
// Query: lat, lng, radiusKm, serviceType, petType, page
router.get("/", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;

    const filter = { status: "open" };
    if (req.query.serviceType) filter.serviceType = req.query.serviceType;
    if (req.query.petType) filter.petTypes = req.query.petType;

    let query;

    // Konum filtresi
    if (req.query.lat && req.query.lng) {
      const radiusKm = Math.min(Number(req.query.radiusKm) || 50, 200);
      query = SitterRequest.find({
        ...filter,
        location: {
          $near: {
            $geometry: { type: "Point", coordinates: [Number(req.query.lng), Number(req.query.lat)] },
            $maxDistance: radiusKm * 1000,
          },
        },
      });
    } else {
      query = SitterRequest.find(filter).sort({ createdAt: -1 });
    }

    const [requests, total] = await Promise.all([
      query.skip(skip).limit(limit).populate("owner", "name avatarUrl"),
      SitterRequest.countDocuments(filter),
    ]);

    return sendOk(res, 200, { requests, total, page });
  } catch (err) {
    return sendError(res, 500, "İlanlar getirilemedi", "internal_error", err.message);
  }
});

// GET /api/sitter-requests/me — Kendi ilanlarım
router.get("/me", authRequired(), async (req, res) => {
  try {
    const userId = req.user.sub;
    const requests = await SitterRequest.find({ owner: userId }).sort({ createdAt: -1 }).populate("owner", "name avatarUrl");
    return sendOk(res, 200, { requests });
  } catch (err) {
    return sendError(res, 500, "İlanlarınız getirilemedi", "internal_error", err.message);
  }
});

// GET /api/sitter-requests/:id — Tek ilan detayı
router.get("/:id", async (req, res) => {
  try {
    const request = await SitterRequest.findById(req.params.id).populate("owner", "name avatarUrl");
    if (!request) return sendError(res, 404, "İlan bulunamadı", "not_found");
    return sendOk(res, 200, { request });
  } catch (err) {
    return sendError(res, 500, "İlan getirilemedi", "internal_error", err.message);
  }
});

// PATCH /api/sitter-requests/:id/status — İlanı kapat/aç (sadece ilan sahibi)
router.patch("/:id/status", authRequired(), async (req, res) => {
  try {
    const userId = req.user.sub;
    const { status } = req.body;

    if (!["open", "closed"].includes(status)) {
      return sendError(res, 400, "status 'open' veya 'closed' olmalı", "validation_error");
    }

    const request = await SitterRequest.findOne({ _id: req.params.id, owner: userId });
    if (!request) return sendError(res, 404, "İlan bulunamadı veya yetkiniz yok", "not_found");

    request.status = status;
    await request.save();

    return sendOk(res, 200, { request });
  } catch (err) {
    return sendError(res, 500, "Güncellenemedi", "internal_error", err.message);
  }
});

// POST /api/sitter-requests/:id/contact — Bakıcı ilana başvurur (konuşma başlatır)
router.post("/:id/contact", authRequired(), async (req, res) => {
  try {
    const sitterUserId = req.user.sub;

    const request = await SitterRequest.findById(req.params.id).populate("owner", "_id name");
    if (!request) return sendError(res, 404, "İlan bulunamadı", "not_found");
    if (request.status !== "open") return sendError(res, 400, "Bu ilan artık aktif değil", "request_closed");
    if (request.owner._id.toString() === sitterUserId) {
      return sendError(res, 400, "Kendi ilanınıza başvuramazsınız", "validation_error");
    }

    const ownerObjectId = new mongoose.Types.ObjectId(request.owner._id);
    const sitterObjectId = new mongoose.Types.ObjectId(sitterUserId);

    // Mevcut konuşma var mı? Yoksa oluştur
    let conversation = await Conversation.findOne({
      participants: { $all: [ownerObjectId, sitterObjectId] },
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [ownerObjectId, sitterObjectId],
        lastMessage: "",
        lastMessageAt: null,
      });
    }

    const populated = await Conversation.findById(conversation._id).populate("participants", "name avatarUrl");

    // Bakıcıya konuşma başlatıldığını bildir (socket)
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${request.owner._id}`).emit("sitter:request_contact", {
        conversationId: conversation._id,
        sitterUserId,
        requestId: request._id,
        serviceType: request.serviceType,
      });
    }

    return sendOk(res, 200, { conversation: populated, conversationId: conversation._id });
  } catch (err) {
    return sendError(res, 500, "Konuşma başlatılamadı", "internal_error", err.message);
  }
});

export default router;
