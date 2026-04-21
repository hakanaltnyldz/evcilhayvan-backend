import SellerApplication from "../models/SellerApplication.js";
import SellerProfile from "../models/SellerProfile.js";
import Store from "../models/Store.js";
import User from "../models/User.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

export async function applySeller(req, res) {
  try {
    const userId = req.user?.sub;
    if (!userId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");

    // Zaten seller rolündeyse başvuru gerekmez
    const user = await User.findById(userId).select("role isSeller");
    if (user?.role === "seller" || user?.isSeller) {
      return sendError(res, 400, "Zaten satici rolundesiniz", "already_seller");
    }

    // Zaten bekleyen veya onaylı başvuru var mı?
    const existing = await SellerApplication.findOne({
      user: userId,
      status: { $in: ["pending", "approved"] },
    });
    if (existing) {
      return sendError(res, 400, "Aktif bir basvurunuz zaten mevcut", "application_exists", { application: existing });
    }

    // Zorunlu alan validasyonu (model required ama net hata vermesi için)
    const required = ["companyName", "companyTitle", "taxNumber", "taxOffice", "address", "contactInfo", "iban"];
    const missing = required.filter((f) => !req.body?.[f]?.toString().trim());
    if (missing.length) {
      return sendError(res, 400, `Eksik alanlar: ${missing.join(", ")}`, "validation_error");
    }

    if (!req.body.kvkkAccepted || !req.body.contractAccepted) {
      return sendError(res, 400, "KVKK ve sozlesme kabul edilmeli", "validation_error");
    }

    // Uzunluk sınırları
    if (req.body.companyName?.length > 120) {
      return sendError(res, 400, "Sirket adi en fazla 120 karakter olabilir", "validation_error");
    }

    const application = await SellerApplication.create({
      user: userId,
      ...req.body,
      status: "pending",
    });

    await recordAudit("seller_application.create", {
      userId,
      entityType: "seller_application",
      entityId: application._id.toString(),
    });

    return sendOk(res, 201, { application });
  } catch (err) {
    console.error("[applySeller] error", err);
    return sendError(res, 500, "Basvuru olusturulamadi", "internal_error", err.message);
  }
}

// GET /api/stores/application/status — kullanıcının kendi başvuru durumu
export async function getMyApplicationStatus(req, res) {
  try {
    const userId = req.user?.sub;
    const application = await SellerApplication.findOne({ user: userId })
      .sort({ createdAt: -1 });
    return sendOk(res, 200, { application: application || null });
  } catch (err) {
    return sendError(res, 500, "Basvuru durumu alinamadi", "internal_error", err.message);
  }
}

export async function listSellerApplications(_req, res) {
  try {
    const apps = await SellerApplication.find().populate("user", "name email role");
    return sendOk(res, 200, { applications: apps });
  } catch (err) {
    console.error("[listSellerApplications] error", err);
    return sendError(res, 500, "Basvurular getirilemedi", "internal_error", err.message);
  }
}

async function updateApplicationStatus(req, res, status) {
  try {
    const { id } = req.params;
    const rejectionReason = req.body?.rejectionReason?.trim();
    const application = await SellerApplication.findById(id);
    if (!application) return sendError(res, 404, "Basvuru bulunamadi", "application_not_found");

    if (status === "rejected" && !rejectionReason) {
      return sendError(res, 400, "Reddetme nedeni zorunlu", "validation_error");
    }

    application.status = status;
    application.rejectionReason = status === "rejected" ? rejectionReason : undefined;
    await application.save();

    if (status === "approved") {
      const user = await User.findById(application.user);
      if (user) {
        user.role = "seller";
        user.isSeller = true;
        await user.save();
      }

      // Mağaza henüz yoksa oluştur
      const existingStore = await Store.findOne({ owner: application.user });
      if (!existingStore) {
        await Store.create({
          name: application.companyName,
          description: "",
          owner: application.user,
        });
      }

      await SellerProfile.findOneAndUpdate(
        { user: application.user },
        {
          storeName: application.companyName,
          storeDescription: "",
          storeLogo: "",
        },
        { upsert: true, new: true }
      );
    }

    await recordAudit("seller_application.update", {
      userId: req.user?.sub,
      entityType: "seller_application",
      entityId: id,
      metadata: { status },
    });

    return sendOk(res, 200, { application });
  } catch (err) {
    console.error("[updateApplicationStatus] error", err);
    return sendError(res, 500, "Islem basarisiz", "internal_error", err.message);
  }
}

export function approveApplication(req, res) {
  return updateApplicationStatus(req, res, "approved");
}

export function rejectApplication(req, res) {
  return updateApplicationStatus(req, res, "rejected");
}
