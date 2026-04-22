// src/routes/adminRoutes.js
import { Router } from "express";
import { param, query } from "express-validator";
import mongoose from "mongoose";
import rateLimit from "express-rate-limit";
import { authRequired } from "../middlewares/auth.js";
import { config as appConfig } from "../config/config.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import User from "../models/User.js";
import Pet from "../models/Pet.js";
import Order from "../models/Order.js";
import Post from "../models/Post.js";
import UserReport from "../models/UserReport.js";
import Coupon from "../models/Coupon.js";
import CouponUsage from "../models/CouponUsage.js";
import SupportTicket from "../models/SupportTicket.js";
import PlatformConfig from "../models/PlatformConfig.js";
import PetSitter from "../models/PetSitter.js";
import Appointment from "../models/Appointment.js";
import VetClaimRequest from "../models/VetClaimRequest.js";
import Veterinary from "../models/Veterinary.js";
import VetReview from "../models/VetReview.js";
import WalkUpdate from "../models/WalkUpdate.js";
import CareReport from "../models/CareReport.js";
import SitterBooking from "../models/SitterBooking.js";
import SellerApplication from "../models/SellerApplication.js";
import Store from "../models/Store.js";
import { sendPush } from "../utils/fcm.js";
import { recordAudit } from "../utils/audit.js";
import { decrypt, maskNationalId } from "../utils/fieldCrypto.js";

const router = Router();

// Hassas PII endpoint'leri için rate limiter (15 dakikada 10 istek)
const sensitiveDataLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: "Çok fazla istek. Lütfen 15 dakika sonra tekrar deneyin." },
  standardHeaders: true,
  legacyHeaders: false,
});

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE = 1000;
const MAX_PAGE_SIZE = 100;

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function getPagination(req, res, { defaultLimit = DEFAULT_PAGE_SIZE, maxLimit = MAX_PAGE_SIZE } = {}) {
  const rawPage = req.query.page;
  const rawLimit = req.query.limit;

  const page = rawPage === undefined ? 1 : Number(rawPage);
  const limit = rawLimit === undefined ? defaultLimit : Number(rawLimit);

  if (!Number.isInteger(page) || page < 1 || page > MAX_PAGE) {
    sendError(res, 400, `page 1 ile ${MAX_PAGE} arasinda olmali`, "validation_error");
    return null;
  }

  if (!Number.isInteger(limit) || limit < 1 || limit > maxLimit) {
    sendError(res, 400, `limit 1 ile ${maxLimit} arasinda olmali`, "validation_error");
    return null;
  }

  return { page, limit, skip: (page - 1) * limit };
}

function parseDateOnly(value, { endOfDay = false } = {}) {
  if (!value) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(value))) return null;
  const date = new Date(endOfDay ? `${value}T23:59:59.999Z` : `${value}T00:00:00.000Z`);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatTimelineLabel(date, granularity) {
  return new Intl.DateTimeFormat("tr-TR", granularity === "day"
    ? { day: "2-digit", month: "short", timeZone: "UTC" }
    : { month: "short", year: "2-digit", timeZone: "UTC" }).format(date);
}

function buildTimelineBuckets({ fromDate, toDate, now = new Date() }) {
  const endDate = toDate || now;
  const explicitRangeDays = fromDate && toDate
    ? Math.max(1, Math.ceil((toDate.getTime() - fromDate.getTime()) / 86400000) + 1)
    : null;
  const granularity = explicitRangeDays && explicitRangeDays <= 45 ? "day" : "month";

  const buckets = [];
  if (granularity === "day") {
    const startDate = new Date(Date.UTC(fromDate.getUTCFullYear(), fromDate.getUTCMonth(), fromDate.getUTCDate()));
    const finalDate = new Date(Date.UTC(toDate.getUTCFullYear(), toDate.getUTCMonth(), toDate.getUTCDate(), 23, 59, 59, 999));
    for (let cursor = new Date(startDate); cursor <= finalDate; cursor.setUTCDate(cursor.getUTCDate() + 1)) {
      const point = new Date(cursor);
      buckets.push({
        key: point.toISOString().slice(0, 10),
        label: formatTimelineLabel(point, "day"),
      });
    }
    return {
      granularity,
      mongoFormat: "%Y-%m-%d",
      startDate,
      endDate: finalDate,
      buckets,
    };
  }

  const seedDate = fromDate || new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 5, 1));
  const startDate = new Date(Date.UTC(seedDate.getUTCFullYear(), seedDate.getUTCMonth(), 1));
  const finalMonth = new Date(Date.UTC(endDate.getUTCFullYear(), endDate.getUTCMonth(), 1));

  for (let cursor = new Date(startDate); cursor <= finalMonth; cursor.setUTCMonth(cursor.getUTCMonth() + 1)) {
    const point = new Date(cursor);
    buckets.push({
      key: `${point.getUTCFullYear()}-${String(point.getUTCMonth() + 1).padStart(2, "0")}`,
      label: formatTimelineLabel(point, "month"),
    });
  }

  return {
    granularity,
    mongoFormat: "%Y-%m",
    startDate,
    endDate,
    buckets,
  };
}

const PLATFORM_CONFIG_KEY = "default";

function toNumberSetting(value, { field, min = 0, max = Number.MAX_SAFE_INTEGER } = {}) {
  const numericValue = Number(value);
  if (!Number.isFinite(numericValue)) {
    throw new Error(`${field} sayi olmali`);
  }
  if (numericValue < min || numericValue > max) {
    throw new Error(`${field} ${min} ile ${max} arasinda olmali`);
  }
  return numericValue;
}

function toBooleanSetting(value, { field } = {}) {
  if (typeof value !== "boolean") {
    throw new Error(`${field} true/false olmali`);
  }
  return value;
}

function toTrimmedString(value, { field, maxLength = 255, allowEmpty = true } = {}) {
  if (typeof value !== "string") {
    throw new Error(`${field} metin olmali`);
  }
  const trimmed = value.trim();
  if (!allowEmpty && !trimmed) {
    throw new Error(`${field} bos birakilamaz`);
  }
  if (trimmed.length > maxLength) {
    throw new Error(`${field} en fazla ${maxLength} karakter olabilir`);
  }
  return trimmed;
}

function normalizePlatformConfig(doc) {
  if (!doc) return null;
  return {
    id: doc.id || doc._id?.toString(),
    fees: {
      storeCommissionRate: Number(doc.fees?.storeCommissionRate ?? 12),
      sitterCommissionRate: Number(doc.fees?.sitterCommissionRate ?? 10),
      vetCommissionRate: Number(doc.fees?.vetCommissionRate ?? 8),
      payoutReserveDays: Number(doc.fees?.payoutReserveDays ?? 7),
      returnWindowDays: Number(doc.fees?.returnWindowDays ?? 14),
      freeShippingThreshold: Number(doc.fees?.freeShippingThreshold ?? 750),
    },
    features: {
      storeEnabled: Boolean(doc.features?.storeEnabled ?? true),
      sitterMatchingEnabled: Boolean(doc.features?.sitterMatchingEnabled ?? true),
      vetAppointmentsEnabled: Boolean(doc.features?.vetAppointmentsEnabled ?? true),
      socialFeedEnabled: Boolean(doc.features?.socialFeedEnabled ?? true),
      maintenanceMode: Boolean(doc.features?.maintenanceMode ?? false),
    },
    moderation: {
      autoHideReportThreshold: Number(doc.moderation?.autoHideReportThreshold ?? 3),
      reviewSlaHours: Number(doc.moderation?.reviewSlaHours ?? 24),
      careReportReviewWindowHours: Number(doc.moderation?.careReportReviewWindowHours ?? 48),
      escalateUserComplaintThreshold: Number(doc.moderation?.escalateUserComplaintThreshold ?? 5),
    },
    contact: {
      supportEmail: doc.contact?.supportEmail || "",
      supportPhone: doc.contact?.supportPhone || "",
      supportWhatsapp: doc.contact?.supportWhatsapp || "",
    },
    announcement: {
      enabled: Boolean(doc.announcement?.enabled ?? false),
      tone: doc.announcement?.tone || "info",
      message: doc.announcement?.message || "",
    },
    updatedAt: doc.updatedAt || null,
    updatedBy: doc.updatedBy
      ? {
          id: doc.updatedBy._id?.toString?.() || doc.updatedBy.id || doc.updatedBy.toString?.(),
          name: doc.updatedBy.name || "",
          email: doc.updatedBy.email || "",
        }
      : null,
  };
}

async function ensurePlatformConfig() {
  const doc = await PlatformConfig.findOneAndUpdate(
    { key: PLATFORM_CONFIG_KEY },
    { $setOnInsert: { key: PLATFORM_CONFIG_KEY } },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  ).populate("updatedBy", "name email");
  return doc;
}

function getModerationBadge(item) {
  if (item.source === "report") return item.reasonLabel;
  if (item.source === "support") return item.categoryLabel;
  if (item.source === "post") return item.isActive ? "Yayinda" : "Gizli";
  if (item.source === "care_report") return `${item.day}. gun`;
  return item.source;
}

function getModerationPriority(value, fallback = "medium") {
  if (["high", "medium", "low"].includes(value)) return value;
  return fallback;
}

function buildModerationItem(item) {
  const common = {
    queueId: `${item.source}:${item.entityId}`,
    source: item.source,
    entityId: item.entityId,
    createdAt: item.createdAt,
    status: item.status,
    priority: getModerationPriority(item.priority),
    badge: getModerationBadge(item),
  };

  if (item.source === "report") {
    return {
      ...common,
      title: `${item.reportedName || "Kullanici"} hakkinda sikayet`,
      subtitle: `Sikayet eden: ${item.reporterName || "Bilinmiyor"}`,
      excerpt: item.description || item.reasonLabel || "Aciklama eklenmemis.",
      media: null,
      metrics: [
        { label: "Sebep", value: item.reasonLabel || item.reason },
        { label: "Durum", value: item.statusLabel },
      ],
      actions: item.status === "pending" ? ["reviewed", "dismissed"] : [],
    };
  }

  if (item.source === "support") {
    return {
      ...common,
      title: `${item.categoryLabel || "Destek"} bildirimi`,
      subtitle: item.userName || item.userEmail || "Kullanici bilgisi yok",
      excerpt: item.message || "Mesaj yok",
      media: null,
      metrics: [
        { label: "Kategori", value: item.categoryLabel || item.category },
        { label: "Durum", value: item.statusLabel },
      ],
      actions: item.status === "closed" ? ["open"] : ["reviewing", "closed"],
      adminNote: item.adminNote || "",
    };
  }

  if (item.source === "post") {
    return {
      ...common,
      title: item.userName ? `${item.userName} gonderisi` : "Kullanici gonderisi",
      subtitle: `${item.photoCount} foto • ${item.commentCount} yorum • ${item.likeCount} begeni`,
      excerpt: item.content || "Sadece fotograf iceren gonderi",
      media: item.photoUrl || null,
      metrics: [
        { label: "Gorunurluk", value: item.isActive ? "Yayinda" : "Gizli" },
        { label: "Etkilesim", value: `${item.likeCount}❤ / ${item.commentCount}💬` },
      ],
      actions: item.isActive ? ["hide", "delete"] : ["unhide", "delete"],
    };
  }

  return {
    ...common,
    title: `${item.petOwnerName || "Musteri"} icin bakim raporu`,
    subtitle: item.serviceLabel || "Bakim raporu",
    excerpt: item.notes || "Bu raporda not bulunmuyor.",
    media: item.photoUrl || null,
    metrics: [
      { label: "Pet", value: item.petName || "Bilinmiyor" },
      { label: "Paylasim", value: item.sharedWithOwnerAt ? "Gonderildi" : "Taslak" },
    ],
    actions: ["delete"],
  };
}

// Tüm admin endpointleri admin rolü gerektirir
router.use(authRequired(["admin"]));

// GET /api/admin/platform-config
router.get("/platform-config", async (req, res) => {
  try {
    const configDoc = await ensurePlatformConfig();
    return sendOk(res, 200, {
      config: normalizePlatformConfig(configDoc),
      runtime: {
        env: appConfig.env,
        hasGooglePlacesApiKey: Boolean(appConfig.googlePlacesApiKey),
        hasMailerConfig: Boolean(appConfig.sendgridKey && appConfig.senderEmail),
        hasAnthropicKey: Boolean(appConfig.anthropicApiKey),
        uploadDirConfigured: Boolean(appConfig.uploadDir),
      },
    });
  } catch (err) {
    return sendError(res, 500, "Platform ayarlari alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/platform-config
router.patch("/platform-config", async (req, res) => {
  try {
    const payload = req.body || {};
    const update = {};

    if (payload.fees) {
      const fees = payload.fees;
      if ("storeCommissionRate" in fees) update["fees.storeCommissionRate"] = toNumberSetting(fees.storeCommissionRate, { field: "Store komisyonu", min: 0, max: 100 });
      if ("sitterCommissionRate" in fees) update["fees.sitterCommissionRate"] = toNumberSetting(fees.sitterCommissionRate, { field: "Bakici komisyonu", min: 0, max: 100 });
      if ("vetCommissionRate" in fees) update["fees.vetCommissionRate"] = toNumberSetting(fees.vetCommissionRate, { field: "Veteriner komisyonu", min: 0, max: 100 });
      if ("payoutReserveDays" in fees) update["fees.payoutReserveDays"] = toNumberSetting(fees.payoutReserveDays, { field: "Payout bekleme gunu", min: 0, max: 90 });
      if ("returnWindowDays" in fees) update["fees.returnWindowDays"] = toNumberSetting(fees.returnWindowDays, { field: "Iade suresi", min: 0, max: 60 });
      if ("freeShippingThreshold" in fees) update["fees.freeShippingThreshold"] = toNumberSetting(fees.freeShippingThreshold, { field: "Ucretsiz kargo esigi", min: 0, max: 1000000 });
    }

    if (payload.features) {
      const features = payload.features;
      if ("storeEnabled" in features) update["features.storeEnabled"] = toBooleanSetting(features.storeEnabled, { field: "Magaza aktifligi" });
      if ("sitterMatchingEnabled" in features) update["features.sitterMatchingEnabled"] = toBooleanSetting(features.sitterMatchingEnabled, { field: "Bakici eslestirme" });
      if ("vetAppointmentsEnabled" in features) update["features.vetAppointmentsEnabled"] = toBooleanSetting(features.vetAppointmentsEnabled, { field: "Veteriner randevulari" });
      if ("socialFeedEnabled" in features) update["features.socialFeedEnabled"] = toBooleanSetting(features.socialFeedEnabled, { field: "Sosyal akis" });
      if ("maintenanceMode" in features) update["features.maintenanceMode"] = toBooleanSetting(features.maintenanceMode, { field: "Bakim modu" });
    }

    if (payload.moderation) {
      const moderation = payload.moderation;
      if ("autoHideReportThreshold" in moderation) update["moderation.autoHideReportThreshold"] = toNumberSetting(moderation.autoHideReportThreshold, { field: "Auto-hide esigi", min: 1, max: 50 });
      if ("reviewSlaHours" in moderation) update["moderation.reviewSlaHours"] = toNumberSetting(moderation.reviewSlaHours, { field: "Moderasyon SLA", min: 1, max: 168 });
      if ("careReportReviewWindowHours" in moderation) update["moderation.careReportReviewWindowHours"] = toNumberSetting(moderation.careReportReviewWindowHours, { field: "Bakim raporu inceleme penceresi", min: 1, max: 168 });
      if ("escalateUserComplaintThreshold" in moderation) update["moderation.escalateUserComplaintThreshold"] = toNumberSetting(moderation.escalateUserComplaintThreshold, { field: "Kullanici sikayet escalation esigi", min: 1, max: 50 });
    }

    if (payload.contact) {
      const contact = payload.contact;
      if ("supportEmail" in contact) update["contact.supportEmail"] = toTrimmedString(contact.supportEmail, { field: "Destek email", maxLength: 200 });
      if ("supportPhone" in contact) update["contact.supportPhone"] = toTrimmedString(contact.supportPhone, { field: "Destek telefonu", maxLength: 40 });
      if ("supportWhatsapp" in contact) update["contact.supportWhatsapp"] = toTrimmedString(contact.supportWhatsapp, { field: "WhatsApp hatti", maxLength: 40 });
    }

    if (payload.announcement) {
      const announcement = payload.announcement;
      if ("enabled" in announcement) update["announcement.enabled"] = toBooleanSetting(announcement.enabled, { field: "Duyuru aktifligi" });
      if ("tone" in announcement) {
        if (!["info", "warning", "success"].includes(String(announcement.tone))) {
          return sendError(res, 400, "Duyuru tonu gecersiz", "validation_error");
        }
        update["announcement.tone"] = String(announcement.tone);
      }
      if ("message" in announcement) update["announcement.message"] = toTrimmedString(announcement.message, { field: "Duyuru mesaji", maxLength: 240 });
    }

    if (!Object.keys(update).length) {
      return sendError(res, 400, "Guncellenecek alan bulunamadi", "validation_error");
    }

    update.updatedBy = req.user.sub;

    const configDoc = await PlatformConfig.findOneAndUpdate(
      { key: PLATFORM_CONFIG_KEY },
      {
        $set: update,
        $setOnInsert: { key: PLATFORM_CONFIG_KEY },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).populate("updatedBy", "name email");

    await recordAudit("admin.platform_config.update", {
      userId: req.user.sub,
      entityType: "PlatformConfig",
      entityId: configDoc._id.toString(),
      metadata: Object.keys(update),
    });

    return sendOk(res, 200, {
      message: "Platform ayarlari guncellendi",
      config: normalizePlatformConfig(configDoc),
    });
  } catch (err) {
    return sendError(res, 400, err.message || "Platform ayarlari kaydedilemedi", "validation_error");
  }
});

// GET /api/admin/moderation/queue?page=1&status=open|resolved|all&source=all|reports|support|posts|care_reports
router.get("/moderation/queue", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 30 });
    if (!pagination) return;
    const { page, limit } = pagination;
    const source = ["all", "reports", "support", "posts", "care_reports"].includes(String(req.query.source))
      ? String(req.query.source)
      : "all";
    const status = ["open", "resolved", "all"].includes(String(req.query.status))
      ? String(req.query.status)
      : "open";
    const search = String(req.query.search || "").trim();
    const fetchLimit = page * limit;
    const configDoc = await ensurePlatformConfig();
    const reviewWindowHours = normalizePlatformConfig(configDoc)?.moderation?.careReportReviewWindowHours ?? 48;
    const reviewWindowDate = new Date(Date.now() - reviewWindowHours * 60 * 60 * 1000);

    const reportReasons = {
      spam: "Spam",
      harassment: "Taciz",
      inappropriate_content: "Uygunsuz Icerik",
      fake_profile: "Sahte Profil",
      other: "Diger",
    };
    const supportCategories = {
      content_complaint: "Icerik Sikayeti",
      user_complaint: "Kullanici Sikayeti",
    };
    const supportStatuses = {
      open: "Acik",
      reviewing: "Inceleniyor",
      closed: "Kapali",
    };

    const shouldInclude = (key) => source === "all" || source === key;
    const reportFilter = {};
    if (status === "open") reportFilter.status = "pending";
    if (status === "resolved") reportFilter.status = { $in: ["reviewed", "dismissed"] };
    if (search) {
      const regex = new RegExp(escapeRegex(search), "i");
      reportFilter.$or = [{ description: regex }];
    }

    const supportFilter = {
      category: { $in: ["content_complaint", "user_complaint"] },
    };
    if (status === "open") supportFilter.status = { $in: ["open", "reviewing"] };
    if (status === "resolved") supportFilter.status = "closed";
    if (search) {
      const regex = new RegExp(escapeRegex(search), "i");
      supportFilter.$or = [{ message: regex }, { adminNote: regex }];
    }

    const postFilter = {};
    if (status === "open") postFilter.isActive = false;
    if (status === "resolved") postFilter.isActive = true;
    if (search) {
      const regex = new RegExp(escapeRegex(search), "i");
      postFilter.$or = [{ content: regex }, { userName: regex }, { petName: regex }];
    }

    const careReportFilter = {};
    if (status === "open") careReportFilter.timestamp = { $gte: reviewWindowDate };
    if (status === "resolved") careReportFilter.timestamp = { $lt: reviewWindowDate };
    if (search) {
      const regex = new RegExp(escapeRegex(search), "i");
      careReportFilter.$or = [{ notes: regex }];
    }

    const [
      reportsResult,
      supportResult,
      postsResult,
      careReportsResult,
      hiddenPostsCount,
      openReportsCount,
      openSupportCount,
      recentCareReportsCount,
    ] = await Promise.all([
      shouldInclude("reports")
        ? Promise.all([
            UserReport.find(reportFilter)
              .populate("reporterId", "name email")
              .populate("reportedId", "name email")
              .sort({ createdAt: -1 })
              .limit(fetchLimit)
              .lean(),
            UserReport.countDocuments(reportFilter),
          ])
        : Promise.resolve([[], 0]),
      shouldInclude("support")
        ? Promise.all([
            SupportTicket.find(supportFilter)
              .populate("userId", "name email")
              .sort({ createdAt: -1 })
              .limit(fetchLimit)
              .lean(),
            SupportTicket.countDocuments(supportFilter),
          ])
        : Promise.resolve([[], 0]),
      shouldInclude("posts")
        ? Promise.all([
            Post.find(postFilter)
              .populate("userId", "name avatarUrl")
              .select("userId userName content photos likes comments isActive createdAt petName")
              .sort({ createdAt: -1 })
              .limit(fetchLimit)
              .lean(),
            Post.countDocuments(postFilter),
          ])
        : Promise.resolve([[], 0]),
      shouldInclude("care_reports")
        ? Promise.all([
            CareReport.find(careReportFilter)
              .populate({
                path: "bookingId",
                select: "serviceType petOwnerId petId",
                populate: [
                  { path: "petOwnerId", select: "name email" },
                  { path: "petId", select: "name" },
                ],
              })
              .sort({ timestamp: -1 })
              .limit(fetchLimit)
              .lean(),
            CareReport.countDocuments(careReportFilter),
          ])
        : Promise.resolve([[], 0]),
      Post.countDocuments({ isActive: false }),
      UserReport.countDocuments({ status: "pending" }),
      SupportTicket.countDocuments({
        category: { $in: ["content_complaint", "user_complaint"] },
        status: { $in: ["open", "reviewing"] },
      }),
      CareReport.countDocuments({ timestamp: { $gte: reviewWindowDate } }),
    ]);

    const [reports, reportsTotal] = reportsResult;
    const [supportTickets, supportTotal] = supportResult;
    const [posts, postsTotal] = postsResult;
    const [careReports, careReportsTotal] = careReportsResult;

    const items = [
      ...reports.map((report) =>
        buildModerationItem({
          source: "report",
          entityId: report._id.toString(),
          createdAt: report.createdAt,
          status: report.status,
          statusLabel: report.status === "pending" ? "Bekliyor" : report.status === "dismissed" ? "Reddedildi" : "Incelendi",
          reason: report.reason,
          reasonLabel: reportReasons[report.reason] || report.reason,
          reporterName: report.reporterId?.name || report.reporterId?.email || "",
          reportedName: report.reportedId?.name || report.reportedId?.email || "",
          description: report.description || "",
          priority: ["harassment", "fake_profile"].includes(report.reason) ? "high" : "medium",
        })
      ),
      ...supportTickets.map((ticket) =>
        buildModerationItem({
          source: "support",
          entityId: ticket._id.toString(),
          createdAt: ticket.createdAt,
          status: ticket.status,
          statusLabel: supportStatuses[ticket.status] || ticket.status,
          categoryLabel: supportCategories[ticket.category] || ticket.category,
          userName: ticket.userId?.name || "",
          userEmail: ticket.userId?.email || "",
          message: ticket.message || "",
          adminNote: ticket.adminNote || "",
          priority: ticket.category === "content_complaint" ? "high" : "medium",
        })
      ),
      ...posts.map((post) =>
        buildModerationItem({
          source: "post",
          entityId: post._id.toString(),
          createdAt: post.createdAt,
          status: post.isActive ? "active" : "hidden",
          isActive: Boolean(post.isActive),
          userName: post.userId?.name || post.userName || "",
          content: post.content || "",
          photoCount: Array.isArray(post.photos) ? post.photos.length : 0,
          likeCount: Array.isArray(post.likes) ? post.likes.length : 0,
          commentCount: Array.isArray(post.comments) ? post.comments.length : 0,
          photoUrl: Array.isArray(post.photos) && post.photos[0] ? post.photos[0] : null,
          priority: post.isActive ? "low" : "medium",
        })
      ),
      ...careReports.map((report) =>
        buildModerationItem({
          source: "care_report",
          entityId: report._id.toString(),
          createdAt: report.timestamp,
          status: report.timestamp >= reviewWindowDate ? "open" : "resolved",
          notes: report.notes || "",
          day: report.day || 1,
          photoUrl: Array.isArray(report.photos) && report.photos[0] ? report.photos[0] : null,
          petOwnerName: report.bookingId?.petOwnerId?.name || report.bookingId?.petOwnerId?.email || "",
          petName: report.bookingId?.petId?.name || "",
          serviceLabel: report.bookingId?.serviceType || "Bakim",
          sharedWithOwnerAt: report.sharedWithOwnerAt || null,
          priority: report.timestamp >= reviewWindowDate ? "medium" : "low",
        })
      ),
    ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    const total = reportsTotal + supportTotal + postsTotal + careReportsTotal;
    const pagedItems = items.slice((page - 1) * limit, page * limit);

    return sendOk(res, 200, {
      items: pagedItems,
      total,
      page,
      hasMore: page * limit < total,
      summary: {
        openReports: openReportsCount,
        openSupportTickets: openSupportCount,
        hiddenPosts: hiddenPostsCount,
        recentCareReports: recentCareReportsCount,
        totalOpenItems: openReportsCount + openSupportCount + hiddenPostsCount + recentCareReportsCount,
      },
    });
  } catch (err) {
    return sendError(res, 500, "Moderasyon kuyrugu alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/moderation/queue/:source/:id
router.patch("/moderation/queue/:source/:id", async (req, res) => {
  try {
    const { source, id } = req.params;
    const { action, adminNote } = req.body || {};

    if (!action) {
      return sendError(res, 400, "action alani zorunlu", "validation_error");
    }

    if (source === "report") {
      if (!["reviewed", "dismissed"].includes(action)) {
        return sendError(res, 400, "Rapor aksiyonu gecersiz", "validation_error");
      }
      const report = await UserReport.findByIdAndUpdate(id, { status: action }, { new: true });
      if (!report) return sendError(res, 404, "Sikayet bulunamadi", "not_found");
      await recordAudit("admin.moderation.report", {
        userId: req.user.sub,
        entityType: "UserReport",
        entityId: id,
        metadata: { action },
      });
      return sendOk(res, 200, { item: { source, id, status: report.status } });
    }

    if (source === "support") {
      if (!["open", "reviewing", "closed"].includes(action)) {
        return sendError(res, 400, "Support aksiyonu gecersiz", "validation_error");
      }
      const update = { status: action };
      if (adminNote !== undefined) update.adminNote = String(adminNote || "").trim();
      const ticket = await SupportTicket.findByIdAndUpdate(id, update, { new: true });
      if (!ticket) return sendError(res, 404, "Ticket bulunamadi", "not_found");
      await recordAudit("admin.moderation.support", {
        userId: req.user.sub,
        entityType: "SupportTicket",
        entityId: id,
        metadata: { action },
      });
      return sendOk(res, 200, { item: { source, id, status: ticket.status } });
    }

    if (source === "post") {
      if (!["hide", "unhide", "delete"].includes(action)) {
        return sendError(res, 400, "Post aksiyonu gecersiz", "validation_error");
      }
      if (action === "delete") {
        const post = await Post.findByIdAndDelete(id);
        if (!post) return sendError(res, 404, "Gonderi bulunamadi", "not_found");
        await recordAudit("admin.moderation.post_delete", {
          userId: req.user.sub,
          entityType: "Post",
          entityId: id,
          metadata: { action },
        });
        return sendOk(res, 200, { deleted: true, source, id });
      }
      const post = await Post.findById(id);
      if (!post) return sendError(res, 404, "Gonderi bulunamadi", "not_found");
      post.isActive = action === "unhide";
      await post.save();
      await recordAudit("admin.moderation.post_visibility", {
        userId: req.user.sub,
        entityType: "Post",
        entityId: id,
        metadata: { action, isActive: post.isActive },
      });
      return sendOk(res, 200, { item: { source, id, status: post.isActive ? "active" : "hidden" } });
    }

    if (source === "care_report") {
      if (action !== "delete") {
        return sendError(res, 400, "Bakim raporu aksiyonu gecersiz", "validation_error");
      }
      const report = await CareReport.findByIdAndDelete(id);
      if (!report) return sendError(res, 404, "Bakim raporu bulunamadi", "not_found");
      await recordAudit("admin.moderation.care_report_delete", {
        userId: req.user.sub,
        entityType: "CareReport",
        entityId: id,
        metadata: { action },
      });
      return sendOk(res, 200, { deleted: true, source, id });
    }

    return sendError(res, 400, "Kaynak tipi gecersiz", "validation_error");
  } catch (err) {
    return sendError(res, 500, "Moderasyon aksiyonu uygulanamadi", "internal_error", err.message);
  }
});

// GET /api/admin/stats?from=YYYY-MM-DD&to=YYYY-MM-DD
router.get("/stats", async (req, res) => {
  try {
    const now = new Date();
    // Tarih filtresi — from/to verilmezse all-time
    const hasFrom = req.query.from !== undefined;
    const hasTo = req.query.to !== undefined;
    const fromDate = hasFrom ? parseDateOnly(req.query.from) : null;
    const toDate = hasTo ? parseDateOnly(req.query.to, { endOfDay: true }) : null;
    if ((hasFrom && !fromDate) || (hasTo && !toDate)) {
      return sendError(res, 400, "from/to YYYY-MM-DD formatinda olmali", "validation_error");
    }
    if (fromDate && toDate && fromDate > toDate) {
      return sendError(res, 400, "from tarihi to tarihinden sonra olamaz", "validation_error");
    }
    const dateFilter = {};
    if (fromDate) dateFilter.$gte = fromDate;
    if (toDate) dateFilter.$lte = toDate;
    const hasDateFilter = fromDate || toDate;
    const timeline = buildTimelineBuckets({ fromDate, toDate, now });

    const commerceFilter = {
      status: { $ne: "cancelled" },
      paymentStatus: { $ne: "failed" },
    };
    if (hasDateFilter) {
      commerceFilter.createdAt = dateFilter;
    }

    const returnsDateFilter = {};
    if (fromDate) returnsDateFilter.$gte = fromDate;
    if (toDate) returnsDateFilter.$lte = toDate;
    const hasReturnsDateFilter = Object.keys(returnsDateFilter).length > 0;

    const [
      allTimeUsers,
      totalUsers,
      allTimeOrders,
      newUsersThisMonth,
      newUsersInRange,
      totalPets,
      activePets,
      totalOrders,
      ordersInRange,
      pendingReports,
      totalActiveCoupons,
      openSupportTickets,
      pendingSellerApplications,
      pendingReturns,
      approvedReturns,
      rejectedReturns,
      revenueSummaryRaw,
      revenueTrendRaw,
      userGrowthRaw,
      topProductsRaw,
    ] = await Promise.all([
      User.countDocuments({}),
      User.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}),
      Order.countDocuments({}).catch(() => 0),
      User.countDocuments({
        createdAt: { $gte: new Date(new Date().setDate(1)) },
      }),
      hasDateFilter ? User.countDocuments({ createdAt: dateFilter }) : Promise.resolve(null),
      Pet.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}),
      Pet.countDocuments({ isActive: true }),
      Order.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}).catch(() => 0),
      hasDateFilter ? Order.countDocuments({ createdAt: dateFilter }).catch(() => 0) : Promise.resolve(null),
      UserReport.countDocuments({ status: "pending" }),
      Coupon.countDocuments({ isActive: true, validUntil: { $gte: now } }).catch(() => 0),
      SupportTicket.countDocuments({ status: "open" }).catch(() => 0),
      SellerApplication.countDocuments({ status: "pending" }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "pending",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "approved",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "rejected",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.aggregate([
        { $match: commerceFilter },
        {
          $group: {
            _id: null,
            grossRevenue: { $sum: "$totalAmount" },
            averageOrderValue: { $avg: "$totalAmount" },
            deliveredOrders: {
              $sum: { $cond: [{ $eq: ["$status", "delivered"] }, 1, 0] },
            },
          },
        },
      ]).catch(() => []),
      Order.aggregate([
        {
          $match: {
            status: { $ne: "cancelled" },
            paymentStatus: { $ne: "failed" },
            createdAt: {
              $gte: timeline.startDate,
              $lte: timeline.endDate,
            },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format: timeline.mongoFormat,
                date: "$createdAt",
                timezone: "UTC",
              },
            },
            revenue: { $sum: "$totalAmount" },
            orders: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]).catch(() => []),
      User.aggregate([
        {
          $match: {
            createdAt: {
              $gte: timeline.startDate,
              $lte: timeline.endDate,
            },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format: timeline.mongoFormat,
                date: "$createdAt",
                timezone: "UTC",
              },
            },
            users: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]).catch(() => []),
      Order.aggregate([
        { $match: commerceFilter },
        { $unwind: "$items" },
        {
          $group: {
            _id: {
              productId: "$items.product",
              name: { $ifNull: ["$items.name", "Urun"] },
            },
            totalSold: { $sum: "$items.quantity" },
            revenue: {
              $sum: { $multiply: ["$items.price", "$items.quantity"] },
            },
          },
        },
        { $sort: { totalSold: -1, revenue: -1 } },
        { $limit: 6 },
      ]).catch(() => []),
    ]);

    const revenueSummary = revenueSummaryRaw?.[0] || {};
    const revenueTrendMap = new Map(
      (revenueTrendRaw || []).map((item) => [
        item._id,
        {
          revenue: Math.round((item.revenue || 0) * 100) / 100,
          orders: item.orders || 0,
        },
      ])
    );
    const userGrowthMap = new Map(
      (userGrowthRaw || []).map((item) => [item._id, item.users || 0])
    );
    const revenueTrend = timeline.buckets.map((bucket) => ({
      key: bucket.key,
      label: bucket.label,
      revenue: revenueTrendMap.get(bucket.key)?.revenue || 0,
      orders: revenueTrendMap.get(bucket.key)?.orders || 0,
    }));
    const userGrowthTrend = timeline.buckets.map((bucket) => ({
      key: bucket.key,
      label: bucket.label,
      users: userGrowthMap.get(bucket.key) || 0,
    }));
    const topProducts = (topProductsRaw || []).map((item) => ({
      _id: item._id?.productId?.toString() || null,
      name: item._id?.name || "Urun",
      totalSold: item.totalSold || 0,
      revenue: Math.round((item.revenue || 0) * 100) / 100,
    }));

    return sendOk(res, 200, {
      stats: {
        allTimeUsers,
        totalUsers,
        allTimeOrders,
        newUsersThisMonth,
        ...(hasDateFilter && { newUsersInRange }),
        totalPets,
        activePets,
        totalOrders,
        ...(hasDateFilter && { ordersInRange }),
        pendingReports,
        totalActiveCoupons,
        openSupportTickets,
        pendingSellerApplications,
        pendingReturns,
        approvedReturns,
        rejectedReturns,
        grossRevenue: Math.round((revenueSummary.grossRevenue || 0) * 100) / 100,
        averageOrderValue: Math.round((revenueSummary.averageOrderValue || 0) * 100) / 100,
        deliveredOrders: revenueSummary.deliveredOrders || 0,
        revenueTrend,
        userGrowthTrend,
        topProducts,
        trendGranularity: timeline.granularity,
        dateFilter: hasDateFilter ? { from: req.query.from, to: req.query.to } : null,
      },
    });
  } catch (err) {
    return sendError(res, 500, "İstatistikler alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/users?page=1&q=
router.get("/users", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const q = req.query.q?.trim();

    const filter = q
      ? {
          $or: [
            { name: { $regex: escapeRegex(q), $options: "i" } },
            { email: { $regex: escapeRegex(q), $options: "i" } },
          ],
        }
      : {};

    const [users, total] = await Promise.all([
      User.find(filter)
        .select("name email role city avatarUrl isSeller isVerified createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter),
    ]);

    return sendOk(res, 200, { users, total, page, hasMore: skip + users.length < total });
  } catch (err) {
    return sendError(res, 500, "Kullanıcılar alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/users/:id/ban
router.patch(
  "/users/:id/ban",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "user_not_found");
      if (user.role === "admin") return sendError(res, 403, "Admin banlanamaz", "forbidden");

      // role: 'user' ↔ 'banned' toggle
      user.role = user.role === "banned" ? "user" : "banned";
      await user.save();

      await recordAudit("admin.user.ban", {
        userId: req.user.sub,
        entityType: "User",
        entityId: user._id.toString(),
        metadata: { newRole: user.role },
      });

      return sendOk(res, 200, {
        message: user.role === "banned" ? "Kullanıcı banlandı" : "Ban kaldırıldı",
        user: { id: user._id, name: user.name, role: user.role },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// DELETE /api/admin/users/:id
router.delete(
  "/users/:id",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "user_not_found");
      if (user.role === "admin") return sendError(res, 403, "Admin silinemez", "forbidden");
      // Kullanicinin aktif ilanlarini pasifleştir (orphan önleme)
      await Pet.updateMany({ ownerId: user._id }, { isActive: false });
      await user.deleteOne();
      await recordAudit("admin.user.delete", {
        userId: req.user.sub,
        entityType: "User",
        entityId: req.params.id,
        metadata: { name: user.name, email: user.email },
      });
      return sendOk(res, 200, { deleted: true, id: req.params.id });
    } catch (err) {
      return sendError(res, 500, "Silme başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/pets?page=1&type=adoption|mating|all
router.get("/pets", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const type = req.query.type;

    const filter = {};
    if (type && ["adoption", "mating"].includes(type)) filter.advertType = type;
    if (req.query.q) {
      const escaped = req.query.q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      filter.$or = [
        { name: { $regex: escaped, $options: "i" } },
      ];
    }

    // Sahip adı/emailine göre arama — q varsa ownerId listesi çek
    let ownerFilter = null;
    if (req.query.q) {
      const escaped = req.query.q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const matchingOwners = await (await import("../models/User.js")).default
        .find({ $or: [{ name: { $regex: escaped, $options: "i" } }, { email: { $regex: escaped, $options: "i" } }] })
        .select("_id");
      const ownerIds = matchingOwners.map(u => u._id);
      if (ownerIds.length) {
        filter.$or = [...(filter.$or || []), { ownerId: { $in: ownerIds } }];
      }
    }

    const [pets, total] = await Promise.all([
      Pet.find(filter)
        .select("name species breed gender ageMonths advertType isActive photos createdAt")
        .populate("ownerId", "name email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Pet.countDocuments(filter),
    ]);

    return sendOk(res, 200, { pets, total, page, hasMore: skip + pets.length < total });
  } catch (err) {
    return sendError(res, 500, "İlanlar alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/pets/:id — Alan güncelleme (name, description, species, breed, gender, ageMonths, isActive)
router.patch(
  "/pets/:id",
  [param("id").isMongoId().withMessage("Geçersiz ilan ID")],
  async (req, res) => {
    try {
      const allowed = ["name", "description", "species", "breed", "gender", "ageMonths", "isActive"];
      const update = {};
      for (const key of allowed) {
        if (req.body[key] !== undefined) update[key] = req.body[key];
      }
      if (Object.keys(update).length === 0) {
        return sendError(res, 400, "Güncellenecek alan yok", "no_fields");
      }
      const pet = await Pet.findByIdAndUpdate(req.params.id, { $set: update }, { new: true })
        .select("name species breed gender ageMonths advertType isActive createdAt")
        .populate("ownerId", "name email");
      if (!pet) return sendError(res, 404, "İlan bulunamadı", "pet_not_found");
      return sendOk(res, 200, { pet, message: "İlan güncellendi" });
    } catch (err) {
      return sendError(res, 500, "Güncelleme başarısız", "internal_error", err.message);
    }
  }
);

// PATCH /api/admin/pets/:id/toggle
router.patch(
  "/pets/:id/toggle",
  [param("id").isMongoId().withMessage("Geçersiz ilan ID")],
  async (req, res) => {
    try {
      const pet = await Pet.findById(req.params.id);
      if (!pet) return sendError(res, 404, "İlan bulunamadı", "pet_not_found");

      pet.isActive = !pet.isActive;
      await pet.save();

      return sendOk(res, 200, {
        message: pet.isActive ? "İlan aktifleştirildi" : "İlan devre dışı bırakıldı",
        pet: { id: pet._id, name: pet.name, isActive: pet.isActive },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/reports?page=1&status=pending|reviewed|all&reason=spam|harassment|...
router.get("/reports", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const status = req.query.status;
    const reason = req.query.reason;

    const filter = {};
    if (status && ["pending", "reviewed", "dismissed"].includes(status)) filter.status = status;
    else filter.status = "pending"; // default: only pending
    if (reason && ["spam", "harassment", "inappropriate_content", "fake_profile", "other"].includes(reason)) {
      filter.reason = reason;
    }

    const [reports, total] = await Promise.all([
      UserReport.find(filter)
        .populate("reporterId", "name email avatarUrl")
        .populate("reportedId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      UserReport.countDocuments(filter),
    ]);

    return sendOk(res, 200, { reports, total, page, hasMore: skip + reports.length < total });
  } catch (err) {
    return sendError(res, 500, "Şikayetler alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/reports/:id/resolve
router.patch(
  "/reports/:id/resolve",
  [param("id").isMongoId().withMessage("Geçersiz şikayet ID")],
  async (req, res) => {
    try {
      const { action } = req.body; // 'reviewed' | 'dismissed'
      const status = action === "dismissed" ? "dismissed" : "reviewed";

      const report = await UserReport.findByIdAndUpdate(
        req.params.id,
        { status },
        { new: true }
      );
      if (!report) return sendError(res, 404, "Şikayet bulunamadı", "report_not_found");

      return sendOk(res, 200, { message: "Şikayet güncellendi", report });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/orders/export?status=&format=csv
router.get("/orders/export", async (req, res) => {
  try {
    const status = req.query.status;
    const filter = {};
    const validStatuses = ["pending", "processing", "shipped", "delivered", "cancelled"];
    if (status && validStatuses.includes(status)) filter.status = status;

    const orders = await Order.find(filter)
      .populate("user", "name email")
      .select("user totalAmount status paymentStatus trackingNumber carrier createdAt guestInfo")
      .sort({ createdAt: -1 })
      .limit(5000);

    const rows = orders.map((o) => {
      const userName = o.user?.name || o.guestInfo?.name || "—";
      const userEmail = o.user?.email || o.guestInfo?.email || "—";
      const date = new Date(o.createdAt).toLocaleDateString("tr-TR");
      return [
        `"${o._id}"`,
        `"${userName.replace(/"/g, '""')}"`,
        `"${userEmail.replace(/"/g, '""')}"`,
        `"${o.totalAmount ?? 0}"`,
        `"${o.status}"`,
        `"${o.paymentStatus || "—"}"`,
        `"${o.trackingNumber || "—"}"`,
        `"${o.carrier || "—"}"`,
        `"${date}"`,
      ].join(",");
    });

    const csv = [
      "Sipariş ID,Müşteri,Email,Tutar,Durum,Ödeme,Takip No,Kargo,Tarih",
      ...rows,
    ].join("\n");

    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader("Content-Disposition", `attachment; filename="orders-${Date.now()}.csv"`);
    return res.send("\uFEFF" + csv); // BOM for Excel UTF-8
  } catch (err) {
    return sendError(res, 500, "Export başarısız", "internal_error", err.message);
  }
});

// GET /api/admin/orders?page=1&status=all|pending|processing|shipped|delivered|cancelled
router.get("/orders", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const status = req.query.status;

    const filter = {};
    const validStatuses = ["pending", "processing", "shipped", "delivered", "cancelled"];
    if (status && validStatuses.includes(status)) filter.status = status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate("user", "name email")
        .select("user guestInfo totalAmount status paymentStatus items trackingNumber carrier estimatedDelivery createdAt returnRequest")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);

    return sendOk(res, 200, { orders, total, page, hasMore: skip + orders.length < total });
  } catch (err) {
    return sendError(res, 500, "Siparişler alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/posts?page=1
router.get("/posts", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;

    const [posts, total] = await Promise.all([
      Post.find()
        .populate("userId", "name avatarUrl")
        .select("userId userName content photos likes comments isActive createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Post.countDocuments(),
    ]);

    return sendOk(res, 200, { posts, total, page, hasMore: skip + posts.length < total });
  } catch (err) {
    return sendError(res, 500, "Gönderiler alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/posts/:id/hide
router.patch(
  "/posts/:id/hide",
  [param("id").isMongoId().withMessage("Geçersiz gönderi ID")],
  async (req, res) => {
    try {
      const post = await Post.findById(req.params.id);
      if (!post) return sendError(res, 404, "Gönderi bulunamadı", "post_not_found");

      post.isActive = !post.isActive;
      await post.save();

      await recordAudit("admin.post.visibility", {
        userId: req.user.sub,
        entityType: "Post",
        entityId: post._id.toString(),
        metadata: { isActive: post.isActive },
      });

      return sendOk(res, 200, {
        message: post.isActive ? "Gönderi yayında" : "Gönderi gizlendi",
        post: { id: post._id, isActive: post.isActive },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// DELETE /api/admin/posts/:id
router.delete(
  "/posts/:id",
  [param("id").isMongoId().withMessage("Geçersiz gönderi ID")],
  async (req, res) => {
    try {
      const post = await Post.findByIdAndDelete(req.params.id);
      if (!post) return sendError(res, 404, "Gönderi bulunamadı", "post_not_found");
      await recordAudit("admin.post.delete", {
        userId: req.user.sub,
        entityType: "Post",
        entityId: req.params.id,
      });
      return sendOk(res, 200, { deleted: true, id: req.params.id });
    } catch (err) {
      return sendError(res, 500, "Silme başarısız", "internal_error", err.message);
    }
  }
);

// PATCH /api/admin/users/:id/role
router.patch(
  "/users/:id/role",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const { id } = req.params;
      const { role } = req.body;
      const allowed = ["user", "admin", "seller", "vet"];
      if (!role || !allowed.includes(role)) {
        return sendError(res, 400, `Geçersiz rol. İzin verilenler: ${allowed.join(", ")}`, "validation_error");
      }
      const user = await User.findByIdAndUpdate(
        id,
        { role },
        { new: true, select: "name email role" }
      );
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");
      await recordAudit("admin.user.role_change", {
        userId: req.user.sub,
        entityType: "User",
        entityId: id,
        metadata: { newRole: role },
      });
      return sendOk(res, 200, { user });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error");
    }
  }
);

// PATCH /api/admin/orders/:id/tracking
router.patch("/orders/:id/tracking", async (req, res) => {
  try {
    const { trackingNumber, carrier, estimatedDelivery } = req.body;
    const order = await Order.findById(req.params.id).populate("user", "_id");
    if (!order) return sendError(res, 404, "Sipariş bulunamadı.");

    const prevStatus = order.status;
    if (trackingNumber !== undefined) order.trackingNumber = trackingNumber;
    if (carrier !== undefined) order.carrier = carrier;
    if (estimatedDelivery !== undefined) order.estimatedDelivery = estimatedDelivery ? new Date(estimatedDelivery) : undefined;

    // Kargo bilgisi girilince processing → shipped otomatik geçiş
    if (trackingNumber && order.status === "processing") order.status = "shipped";

    // Durum geçmişine kayıt
    if (order.status !== prevStatus || trackingNumber) {
      order.statusHistory = order.statusHistory || [];
      order.statusHistory.push({
        status: order.status,
        note: trackingNumber
          ? `${carrier || 'Kargo'} - Takip No: ${trackingNumber}`
          : `Durum güncellendi: ${order.status}`,
        updatedAt: new Date(),
      });
    }

    await order.save();

    // Socket.io — uygulama açıkken anlık güncelleme
    const io = req.app.get("io");
    if (io && order.user?._id) {
      io.to(`user:${String(order.user._id)}`).emit("order:status_update", {
        orderId: String(order._id),
        status: order.status,
        trackingNumber: order.trackingNumber,
        carrier: order.carrier,
        estimatedDelivery: order.estimatedDelivery,
      });
    }

    // FCM push — uygulama kapalıyken bildirim
    if (order.user?._id && trackingNumber) {
      sendPush(order.user._id, {
        title: "Siparişiniz Kargoya Verildi",
        body: `${carrier || "Kargo"} - Takip No: ${trackingNumber}`,
        data: { type: "order_shipped", orderId: order._id.toString() },
      }).catch(() => {});
    }

    return sendOk(res, 200, { order });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
  }
});

// GET /api/admin/coupons?page=1&status=active|expired|all
router.get("/coupons", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (req.query.status === "active") filter.isActive = true;
    if (req.query.status === "expired") filter.validUntil = { $lt: new Date() };
    const [coupons, total] = await Promise.all([
      Coupon.find(filter)
        .populate("seller", "name email")
        .populate("store", "name")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Coupon.countDocuments(filter),
    ]);
    return sendOk(res, 200, { coupons, total, page, hasMore: skip + coupons.length < total });
  } catch (err) {
    return sendError(res, 500, "Kuponlar alınamadı", "internal_error", err.message);
  }
});

// POST /api/admin/coupons
router.post("/coupons", async (req, res) => {
  try {
    const {
      code, description, discountType, discountValue,
      minPurchaseAmount, maxDiscountAmount, validFrom, validUntil,
      usageLimit, perUserLimit, firstOrderOnly,
      store, applicableCategories,
    } = req.body;
    if (!code || !discountType || !discountValue || !validFrom || !validUntil)
      return sendError(res, 400, "Zorunlu alanlar eksik.");
    if (!["percentage", "fixed"].includes(discountType)) {
      return sendError(res, 400, "Gecersiz indirim tipi", "validation_error");
    }
    if (Number(discountValue) <= 0) {
      return sendError(res, 400, "Indirim degeri 0'dan buyuk olmali", "validation_error");
    }
    if (discountType === "percentage" && Number(discountValue) > 100) {
      return sendError(res, 400, "Yuzde indirimi 100'u gecemez", "validation_error");
    }
    if (minPurchaseAmount !== undefined && Number(minPurchaseAmount) < 0) {
      return sendError(res, 400, "Minimum tutar negatif olamaz", "validation_error");
    }
    if (maxDiscountAmount !== undefined && Number(maxDiscountAmount) < 0) {
      return sendError(res, 400, "Maksimum indirim negatif olamaz", "validation_error");
    }
    if (usageLimit !== undefined && Number(usageLimit) < 1) {
      return sendError(res, 400, "Kullanim limiti en az 1 olmali", "validation_error");
    }
    if (perUserLimit !== undefined && Number(perUserLimit) < 1) {
      return sendError(res, 400, "Kisi basi limit en az 1 olmali", "validation_error");
    }
    const fromDate = new Date(validFrom);
    const untilDate = new Date(validUntil);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(untilDate.getTime()) || untilDate < fromDate) {
      return sendError(res, 400, "Bitis tarihi baslangictan sonra olmali", "validation_error");
    }
    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      description,
      discountType,
      discountValue: Number(discountValue),
      minPurchaseAmount: minPurchaseAmount ? Number(minPurchaseAmount) : 0,
      maxDiscountAmount: maxDiscountAmount ? Number(maxDiscountAmount) : undefined,
      validFrom: fromDate,
      validUntil: (() => { const d = new Date(untilDate); d.setHours(23, 59, 59, 999); return d; })(),
      usageLimit: usageLimit ? Number(usageLimit) : undefined,
      perUserLimit: perUserLimit ? Number(perUserLimit) : 1,
      firstOrderOnly: firstOrderOnly || false,
      store: store || undefined,
      applicableCategories: Array.isArray(applicableCategories) && applicableCategories.length > 0
        ? applicableCategories : undefined,
    });
    return sendOk(res, 201, { coupon });
  } catch (err) {
    if (err.code === 11000) return sendError(res, 409, "Bu kupon kodu zaten kullanılıyor.");
    return sendError(res, 500, "Kupon oluşturulamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/coupons/:id  — kupon güncelleme
router.patch("/coupons/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (!id.match(/^[a-f\d]{24}$/i)) return sendError(res, 400, "Geçersiz kupon ID", "validation_error");
    const allowed = ["code", "description", "discountType", "discountValue",
      "minPurchaseAmount", "maxDiscountAmount", "validFrom", "validUntil",
      "usageLimit", "perUserLimit", "firstOrderOnly", "store", "applicableCategories"];
    const update = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) update[key] = req.body[key];
    }
    if (update.discountType && !["percentage", "fixed"].includes(update.discountType)) {
      return sendError(res, 400, "Gecersiz indirim tipi", "validation_error");
    }
    if (update.discountValue !== undefined && Number(update.discountValue) <= 0) {
      return sendError(res, 400, "Indirim degeri 0'dan buyuk olmali", "validation_error");
    }
    if (update.discountType === "percentage" && update.discountValue !== undefined && Number(update.discountValue) > 100) {
      return sendError(res, 400, "Yuzde indirimi 100'u gecemez", "validation_error");
    }
    if (update.minPurchaseAmount !== undefined && Number(update.minPurchaseAmount) < 0) {
      return sendError(res, 400, "Minimum tutar negatif olamaz", "validation_error");
    }
    if (update.maxDiscountAmount !== undefined && Number(update.maxDiscountAmount) < 0) {
      return sendError(res, 400, "Maksimum indirim negatif olamaz", "validation_error");
    }
    if (update.usageLimit !== undefined && Number(update.usageLimit) < 1) {
      return sendError(res, 400, "Kullanim limiti en az 1 olmali", "validation_error");
    }
    if (update.perUserLimit !== undefined && Number(update.perUserLimit) < 1) {
      return sendError(res, 400, "Kisi basi limit en az 1 olmali", "validation_error");
    }
    if (update.code) update.code = String(update.code).toUpperCase().trim();
    if (update.validUntil) { const d = new Date(update.validUntil); d.setHours(23, 59, 59, 999); update.validUntil = d; }
    if (update.validFrom && Number.isNaN(new Date(update.validFrom).getTime())) {
      return sendError(res, 400, "Gecersiz baslangic tarihi", "validation_error");
    }
    if (update.validUntil && Number.isNaN(new Date(update.validUntil).getTime())) {
      return sendError(res, 400, "Gecersiz bitis tarihi", "validation_error");
    }
    const coupon = await Coupon.findByIdAndUpdate(id, update, { new: true, runValidators: true });
    if (!coupon) return sendError(res, 404, "Kupon bulunamadı", "not_found");
    return sendOk(res, 200, { coupon });
  } catch (err) {
    return sendError(res, 500, "Kupon güncellenemedi", "internal_error");
  }
});

// PATCH /api/admin/coupons/:id/toggle
router.patch("/coupons/:id/toggle", async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");
    coupon.isActive = !coupon.isActive;
    await coupon.save();
    return sendOk(res, 200, { coupon });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
  }
});

// DELETE /api/admin/coupons/:id
router.delete("/coupons/:id", async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) return sendError(res, 404, "Kupon bulunamad?.");
    await recordAudit("admin.coupon.delete", {
      userId: req.user.sub,
      entityType: "Coupon",
      entityId: coupon._id.toString(),
      metadata: { code: coupon.code },
    });
    return sendOk(res, 200, { message: "Kupon silindi." });
  } catch (err) {
    return sendError(res, 500, "??lem ba?ar?s?z", "internal_error", err.message);
  }
});

// GET /api/admin/stores — kupon formu için tüm mağaza listesi
router.get("/stores", async (req, res) => {
  try {
    const stores = await Store.find({}).select("_id name").sort({ name: 1 }).limit(200);
    return sendOk(res, 200, { stores });
  } catch (err) {
    return sendError(res, 500, "Mağazalar alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/support?page=1&status=open|reviewing|closed
router.get("/support", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (["open", "reviewing", "closed"].includes(req.query.status)) filter.status = req.query.status;
    const [tickets, total] = await Promise.all([
      SupportTicket.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      SupportTicket.countDocuments(filter),
    ]);
    return sendOk(res, 200, { tickets, total, page });
  } catch (err) {
    return sendError(res, 500, "Destek ticketları alınamadı.", "internal_error", err.message);
  }
});

// PATCH /api/admin/support/:id
router.patch("/support/:id", async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    const allowed = ["open", "reviewing", "closed"];
    if (status && !allowed.includes(status)) return sendError(res, 400, "Ge?ersiz durum.");
    if (adminNote !== undefined && typeof adminNote !== "string") {
      return sendError(res, 400, "Admin notu metin olmali", "validation_error");
    }
    const trimmedAdminNote = typeof adminNote === "string" ? adminNote.trim() : adminNote;
    if (typeof trimmedAdminNote === "string" && trimmedAdminNote.length > 500) {
      return sendError(res, 400, "Admin notu en fazla 500 karakter olabilir", "validation_error");
    }
    const ticket = await SupportTicket.findById(req.params.id);
    if (!ticket) return sendError(res, 404, "Ticket bulunamad?.");
    if (status) ticket.status = status;
    if (trimmedAdminNote !== undefined) ticket.adminNote = trimmedAdminNote;
    await ticket.save();
    return sendOk(res, 200, { ticket });
  } catch (err) {
    return sendError(res, 500, "??lem ba?ar?s?z.", "internal_error", err.message);
  }
});

// GET /api/admin/coupons/:id/usage?page=1
// Bir kuponu kim, ne zaman, hangi sipariş üzerinden kullandı?
router.get("/coupons/:id/usage", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const couponId = req.params.id;

    const [usages, total, coupon] = await Promise.all([
      CouponUsage.find({ couponId })
        .populate("userId", "name email avatarUrl")
        .populate("orderId", "totalAmount originalAmount status createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      CouponUsage.aggregate([
        { $match: { couponId: new mongoose.Types.ObjectId(couponId) } },
        { $group: { _id: null, total: { $sum: "$count" } } },
      ]),
      Coupon.findById(couponId).select("code discountType discountValue usageCount usageLimit"),
    ]);

    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");
    await recordAudit("admin.coupon.delete", {
      userId: req.user.sub,
      entityType: "Coupon",
      entityId: coupon._id.toString(),
      metadata: { code: coupon.code },
    });

    // Toplam kazandırılan indirim tutarı
    const totalDiscount = await CouponUsage.aggregate([
      { $match: { couponId: coupon._id } },
      { $group: { _id: null, total: { $sum: "$discountAmount" } } },
    ]);

    return sendOk(res, 200, {
      coupon,
      usages,
      total: total[0]?.total ?? 0,
      page,
      totalDiscountGiven: totalDiscount[0]?.total ?? 0,
    });
  } catch (err) {
    return sendError(res, 500, "Kullanım geçmişi alınamadı", "internal_error", err.message);
  }
});

// === VETERİNER YÖNETİMİ ===

// GET /api/admin/vets?page=1
router.get("/vets", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [vets, total] = await Promise.all([
      Veterinary.find()
        .select("name address phone photos googlePlaceId googleRating googleReviewCount isVerified isActive userId source createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Veterinary.countDocuments(),
    ]);
    return sendOk(res, 200, { vets, total, page });
  } catch (err) {
    return sendError(res, 500, "Veterinerler alinamadi", "internal_error", err.message);
  }
});

router.get("/vets/:id/insights", async (req, res) => {
  try {
    const vetId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(vetId)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const [vet, reviewStatsRaw, recentReviews, appointmentStatsRaw, upcomingAppointments] =
      await Promise.all([
        Veterinary.findById(vetId).populate("userId", "name email avatarUrl"),
        VetReview.aggregate([
          { $match: { vet: new mongoose.Types.ObjectId(vetId) } },
          {
            $group: {
              _id: null,
              averageRating: { $avg: "$rating" },
              reviewCount: { $sum: 1 },
            },
          },
        ]),
        VetReview.find({ vet: vetId })
          .populate("user", "name email avatarUrl")
          .sort({ createdAt: -1 })
          .limit(5)
          .lean(),
        Appointment.aggregate([
          { $match: { veterinaryId: new mongoose.Types.ObjectId(vetId) } },
          {
            $group: {
              _id: "$status",
              count: { $sum: 1 },
            },
          },
        ]),
        Appointment.find({
          veterinaryId: vetId,
          date: { $gte: new Date() },
          status: { $in: ["pending", "confirmed"] },
        })
          .sort({ date: 1 })
          .limit(5)
          .populate("userId", "name email")
          .populate("petId", "name species")
          .lean(),
      ]);

    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "not_found");

    const reviewStats = reviewStatsRaw?.[0] || {};
    const appointmentStats = {
      total: 0,
      pending: 0,
      confirmed: 0,
      completed: 0,
      cancelled: 0,
      no_show: 0,
    };
    for (const item of appointmentStatsRaw || []) {
      appointmentStats[item._id] = item.count || 0;
      appointmentStats.total += item.count || 0;
    }

    return sendOk(res, 200, {
      vet,
      insights: {
        reviewStats: {
          averageRating: Math.round((reviewStats.averageRating || 0) * 10) / 10,
          reviewCount: reviewStats.reviewCount || 0,
        },
        recentReviews: recentReviews.map((review) => ({
          _id: review._id,
          rating: review.rating,
          comment: review.comment || "",
          createdAt: review.createdAt,
          user: review.user
            ? {
                name: review.user.name,
                email: review.user.email,
                avatarUrl: review.user.avatarUrl,
              }
            : null,
        })),
        appointmentStats,
        upcomingAppointments: upcomingAppointments.map((appointment) => ({
          _id: appointment._id,
          date: appointment.date,
          status: appointment.status,
          type: appointment.type,
          user: appointment.userId
            ? {
                name: appointment.userId.name,
                email: appointment.userId.email,
              }
            : null,
          pet: appointment.petId
            ? {
                name: appointment.petId.name,
                species: appointment.petId.species,
              }
            : null,
        })),
      },
    });
  } catch (err) {
    return sendError(res, 500, "Veteriner detaylari alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/vet-claims?page=1&status=pending|approved|rejected
router.get("/vet-claims", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (["pending", "approved", "rejected"].includes(req.query.status)) filter.status = req.query.status;
    else filter.status = "pending";
    const [claims, total] = await Promise.all([
      VetClaimRequest.find(filter)
        .populate("vetId", "name address phone isVerified")
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      VetClaimRequest.countDocuments(filter),
    ]);
    return sendOk(res, 200, { claims, total, page });
  } catch (err) {
    return sendError(res, 500, "Talepler alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/vet-claims/:id/review
// body: { action: "approved"|"rejected", adminNote? }
router.patch("/vet-claims/:id/review", async (req, res) => {
  try {
    const { action, adminNote } = req.body;
    if (!["approved", "rejected"].includes(action)) {
      return sendError(res, 400, "action 'approved' veya 'rejected' olmali", "validation_error");
    }
    const trimmedAdminNote = typeof adminNote === "string" ? adminNote.trim() : "";
    if (action === "rejected" && !trimmedAdminNote) {
      return sendError(res, 400, "Reddetme icin admin notu zorunlu", "validation_error");
    }
    const claim = await VetClaimRequest.findById(req.params.id);
    if (!claim) return sendError(res, 404, "Talep bulunamadi", "not_found");
    if (claim.status !== "pending") {
      return sendError(res, 409, "Bu talep zaten incelendi", "already_reviewed");
    }

    claim.status = action;
    claim.adminNote = trimmedAdminNote;
    claim.reviewedBy = req.user.sub;
    claim.reviewedAt = new Date();
    await claim.save();

    if (action === "approved") {
      // Vet profiline userId ata ve doğrula
      await Veterinary.findByIdAndUpdate(claim.vetId, {
        userId: claim.userId,
        isVerified: true,
      });
      // Admin kullaniciyi vet'e dusurme; diger hesaplar vet olabilir.
      const claimantUser = await User.findById(claim.userId).select("role");
      if (claimantUser && claimantUser.role !== "admin") {
        await User.findByIdAndUpdate(claim.userId, { role: "vet" });
      }
    }

    await recordAudit("admin.vet_claim.review", {
      userId: req.user.sub,
      entityType: "VetClaimRequest",
      entityId: claim._id.toString(),
      metadata: { action, vetId: claim.vetId?.toString() },
    });

    return sendOk(res, 200, { claim, message: action === "approved" ? "Talep onaylandi" : "Talep reddedildi" });
  } catch (err) {
    return sendError(res, 500, "Inceleme basarisiz", "internal_error", err.message);
  }
});

// === BAKICI YÖNETİMİ ===

// GET /api/admin/pet-sitters?page=1&verified=all|true|false
router.get("/pet-sitters", async (req, res) => {
  try {
    const { verified = "all" } = req.query;
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (verified === "true") filter.isVerified = true;
    if (verified === "false") filter.isVerified = false;
    const [sitters, total] = await Promise.all([
      PetSitter.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      PetSitter.countDocuments(filter),
    ]);
    return sendOk(res, 200, { sitters, total, page });
  } catch (err) {
    return sendError(res, 500, "Bakicilar alinamadi", "internal_error", err.message);
  }
});

router.get("/pet-sitters/:id/insights", async (req, res) => {
  try {
    const sitterId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(sitterId)) {
      return sendError(res, 400, "Gecersiz bakici ID", "validation_error");
    }

    const [sitter, statsRaw, serviceBreakdownRaw, recentReviews] = await Promise.all([
      PetSitter.findById(sitterId).populate("userId", "name email avatarUrl"),
      SitterBooking.aggregate([
        { $match: { sitterId: new mongoose.Types.ObjectId(sitterId) } },
        {
          $group: {
            _id: null,
            totalBookings: { $sum: 1 },
            pending: { $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] } },
            accepted: { $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] } },
            active: { $sum: { $cond: [{ $eq: ["$status", "active"] }, 1, 0] } },
            completed: { $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] } },
            cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
            rejected: { $sum: { $cond: [{ $eq: ["$status", "rejected"] }, 1, 0] } },
            totalRevenue: {
              $sum: {
                $cond: [
                  { $eq: ["$status", "completed"] },
                  { $ifNull: ["$earnings.payableAmount", "$totalPrice"] },
                  0,
                ],
              },
            },
          },
        },
      ]),
      SitterBooking.aggregate([
        { $match: { sitterId: new mongoose.Types.ObjectId(sitterId) } },
        {
          $group: {
            _id: "$serviceType",
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
      ]),
      SitterBooking.find({
        sitterId,
        "ownerReview.rating": { $exists: true },
      })
        .populate("petOwnerId", "name email avatarUrl")
        .sort({ updatedAt: -1 })
        .limit(5)
        .lean(),
    ]);

    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");

    const stats = statsRaw?.[0] || {};
    const monthlyRevenue = await SitterBooking.aggregate([
      {
        $match: {
          sitterId: new mongoose.Types.ObjectId(sitterId),
          status: "completed",
          completedAt: {
            $gte: new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1)),
          },
        },
      },
      {
        $group: {
          _id: null,
          total: {
            $sum: { $ifNull: ["$earnings.payableAmount", "$totalPrice"] },
          },
        },
      },
    ]);

    return sendOk(res, 200, {
      sitter,
      insights: {
        performance: {
          totalBookings: stats.totalBookings || 0,
          pending: stats.pending || 0,
          accepted: stats.accepted || 0,
          active: stats.active || 0,
          completed: stats.completed || 0,
          cancelled: stats.cancelled || 0,
          rejected: stats.rejected || 0,
          totalRevenue: Math.round((stats.totalRevenue || 0) * 100) / 100,
          monthlyRevenue: Math.round((monthlyRevenue?.[0]?.total || 0) * 100) / 100,
        },
        serviceBreakdown: (serviceBreakdownRaw || []).map((item) => ({
          serviceType: item._id,
          count: item.count || 0,
        })),
        recentReviews: recentReviews.map((booking) => ({
          _id: booking._id,
          rating: booking.ownerReview?.rating || 0,
          comment: booking.ownerReview?.comment || "",
          createdAt: booking.ownerReview?.createdAt || booking.updatedAt,
          owner: booking.petOwnerId
            ? {
                name: booking.petOwnerId.name,
                email: booking.petOwnerId.email,
                avatarUrl: booking.petOwnerId.avatarUrl,
              }
            : null,
          serviceType: booking.serviceType,
          totalPrice: booking.totalPrice || 0,
        })),
      },
    });
  } catch (err) {
    return sendError(res, 500, "Bakici detaylari alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/pet-sitters/:id/verify
router.patch("/pet-sitters/:id/verify", async (req, res) => {
  try {
    const { isVerified } = req.body;
    const sitter = await PetSitter.findByIdAndUpdate(
      req.params.id,
      { isVerified: Boolean(isVerified) },
      { new: true }
    ).populate("userId", "name email");
    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");
    return sendOk(res, 200, { sitter });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// PATCH /api/admin/vets/:id/verify — Veteriner onaylama/reddetme (KRİTİK: Admin paneli bunu çağırıyor)
router.patch("/vets/:id/verify", async (req, res) => {
  try {
    const { isVerified } = req.body;
    const vet = await Veterinary.findByIdAndUpdate(
      req.params.id,
      { isVerified: Boolean(isVerified) },
      { new: true }
    ).select("name address phone isVerified isActive userId");
    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "not_found");

    await recordAudit("admin.vet.verify", {
      userId: req.user.sub,
      entityType: "Veterinary",
      entityId: vet._id.toString(),
      metadata: { isVerified: Boolean(isVerified) },
    });

    return sendOk(res, 200, { vet });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// PATCH /api/admin/pet-sitters/:id/ban — Bakıcı banlama
router.patch("/pet-sitters/:id/ban", async (req, res) => {
  try {
    const { isBanned, reason } = req.body;
    // isBanned=true → isActive=false (hesabı devre dışı bırak)
    const sitter = await PetSitter.findByIdAndUpdate(
      req.params.id,
      { isActive: !Boolean(isBanned) },
      { new: true }
    ).populate("userId", "name email avatarUrl");
    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");

    await recordAudit("admin.sitter.ban", {
      userId: req.user.sub,
      entityType: "PetSitter",
      entityId: sitter._id.toString(),
      metadata: { isBanned: Boolean(isBanned), reason },
    });

    return sendOk(res, 200, { sitter });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// GET /api/admin/walk-updates?page=1 — Yürüyüş güncellemelerini listele
router.get("/walk-updates", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [updates, total] = await Promise.all([
      WalkUpdate.find()
        .populate({ path: "bookingId", select: "serviceType startDate status petOwnerId", populate: { path: "petOwnerId", select: "name email" } })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit),
      WalkUpdate.countDocuments(),
    ]);
    return sendOk(res, 200, { updates, total, page });
  } catch (err) {
    return sendError(res, 500, "Walk güncellemeleri alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/care-reports?page=1 — Bakım raporlarını listele
router.get("/care-reports", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [reports, total] = await Promise.all([
      CareReport.find()
        .populate({ path: "bookingId", select: "serviceType startDate status petOwnerId", populate: { path: "petOwnerId", select: "name email" } })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit),
      CareReport.countDocuments(),
    ]);
    return sendOk(res, 200, { reports, total, page });
  } catch (err) {
    return sendError(res, 500, "Bakim raporlari alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/sitter-bookings?page=1&status= — Rezervasyonları listele
router.get("/sitter-bookings", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    const [bookings, total] = await Promise.all([
      SitterBooking.find(filter)
        .populate("petOwnerId", "name email avatarUrl")
        .populate("sitterUserId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      SitterBooking.countDocuments(filter),
    ]);
    return sendOk(res, 200, { bookings, total, page });
  } catch (err) {
    return sendError(res, 500, "Rezervasyonlar alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/users/:id/sensitive — TC + telefon şifre ile açılır
router.get("/users/:id/sensitive", sensitiveDataLimiter, authRequired(["admin"]), async (req, res) => {
  try {
    const adminPass = req.headers["x-admin-data-password"];
    if (!adminPass || adminPass !== process.env.ADMIN_DATA_PASSWORD) {
      return sendError(res, 403, "Ek yetki gerekli", "extra_auth_required");
    }
    const user = await User.findById(req.params.id).select("+nationalId +phone");
    if (!user) return sendError(res, 404, "Kullanici bulunamadi", "not_found");
    return sendOk(res, 200, {
      phone: user.phone || null,
      nationalId: user.nationalId ? decrypt(user.nationalId) : null,
    });
  } catch (err) {
    return sendError(res, 500, "Veriler alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/orders/:id/guest-sensitive — misafir TC şifre ile açılır
router.get("/orders/:id/guest-sensitive", sensitiveDataLimiter, authRequired(["admin"]), async (req, res) => {
  try {
    const adminPass = req.headers["x-admin-data-password"];
    if (!adminPass || adminPass !== process.env.ADMIN_DATA_PASSWORD) {
      return sendError(res, 403, "Ek yetki gerekli", "extra_auth_required");
    }
    const order = await Order.findById(req.params.id).select("guestInfo");
    if (!order) return sendError(res, 404, "Siparis bulunamadi", "not_found");
    return sendOk(res, 200, {
      name: order.guestInfo?.name,
      phone: order.guestInfo?.phone,
      email: order.guestInfo?.email,
      nationalId: order.guestInfo?.nationalId ? decrypt(order.guestInfo.nationalId) : null,
    });
  } catch (err) {
    return sendError(res, 500, "Veriler alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/orders/:id/return-status
// body: { status: "approved"|"rejected", note? }
import { resolveReturnRequest } from "../controllers/orderController.js";
router.patch("/orders/:id/return-status", async (req, res) => {
  return resolveReturnRequest(req, res);
});

// GET /api/admin/orders/returns  — İade talep listesi (admin)
router.get("/orders/returns", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const statusFilter = req.query.status;
    const filter = { 'returnRequest': { $exists: true, $ne: null } };
    if (statusFilter && ['pending', 'approved', 'rejected'].includes(statusFilter)) {
      filter['returnRequest.status'] = statusFilter;
    }
    const [returns, total] = await Promise.all([
      Order.find(filter)
        .populate('user', 'name email avatarUrl')
        .select('_id user guestInfo items totalAmount createdAt returnRequest status')
        .sort({ 'returnRequest.requestedAt': -1 })
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);
    return sendOk(res, 200, { returns, total, page });
  } catch (err) {
    return sendError(res, 500, 'İade talepleri alınamadı', 'internal_error', err.message);
  }
});

export default router;
