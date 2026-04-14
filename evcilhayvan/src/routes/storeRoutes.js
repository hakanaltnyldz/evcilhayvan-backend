import fs from "fs";
import multer from "multer";
import path from "path";
import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  addProduct,
  applySeller,
  discoverStores,
  getMyProducts,
  getMyStore,
  getStore,
  getStoreProducts,
  productFeed,
} from "../controllers/storeController.js";
import Store from "../models/Store.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

const router = Router();

const storeStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = "uploads/stores";
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, `store-${unique}${path.extname(file.originalname)}`);
  },
});

const storeUpload = multer({
  storage: storeStorage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp|gif/;
    const ext = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mime = allowedTypes.test(file.mimetype);
    if (ext && mime) {
      cb(null, true);
    } else {
      cb(new Error("Sadece resim dosyalari yuklenebilir"));
    }
  },
});

router.get("/discover", discoverStores);
router.get("/feed", productFeed);
router.get("/me", authRequired(["seller", "admin"]), getMyStore);
router.get("/me/products", authRequired(["seller", "admin"]), getMyProducts);
router.post("/apply", authRequired(), applySeller);
router.post("/create", authRequired(), applySeller);
router.post("/", authRequired(), applySeller);
router.post("/products", authRequired(["seller", "admin"]), addProduct);
router.post("/me/products", authRequired(["seller", "admin"]), addProduct);
router.get("/:storeId/products", getStoreProducts);
router.get("/:storeId", getStore);

router.patch(
  "/me/profile",
  authRequired(["seller", "admin"]),
  storeUpload.fields([
    { name: "logo", maxCount: 1 },
    { name: "banner", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const sellerId = req.user.sub;
      const allowed = ["name", "description", "bannerUrl", "phone", "website", "instagram", "twitter", "facebook", "workingHours"];
      const update = {};

      for (const key of allowed) {
        if (req.body[key] !== undefined) update[key] = req.body[key];
      }

      if (typeof update.workingHours === "string") {
        try {
          update.workingHours = JSON.parse(update.workingHours);
        } catch {
          // ignore malformed working hours payloads
        }
      }

      if (req.files?.logo?.[0]) {
        update.logoUrl = `/uploads/stores/${req.files.logo[0].filename}`;
      }

      if (req.files?.banner?.[0]) {
        update.bannerUrl = `/uploads/stores/${req.files.banner[0].filename}`;
      }

      const store = await Store.findOneAndUpdate({ owner: sellerId }, update, { new: true });
      if (!store) return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
      return sendOk(res, 200, { store });
    } catch (err) {
      return sendError(res, 500, "Magaza guncellenemedi", "internal_error", err.message);
    }
  }
);

export default router;
