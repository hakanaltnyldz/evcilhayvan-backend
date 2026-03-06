import { Router } from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { authRequired } from "../middlewares/auth.js";
import { applySeller } from "../controllers/sellerApplicationController.js";
import {
  createSellerProduct,
  createSellerProductWithImages,
  deleteSellerProduct,
  getSellerProducts,
  updateSellerProduct,
  uploadProductImages,
  updateStock,
  toggleProductActive,
  getSellerStats,
  seedDemoProducts,
} from "../controllers/sellerProductController.js";

const router = Router();

// Multer config for product images
const productStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = "uploads/products";
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, "product-" + unique + ext);
  },
});

const productUpload = multer({
  storage: productStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
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

router.post("/seller/apply", authRequired(), applySeller);

// Product routes
router.post("/seller/products", authRequired(["seller", "admin"]), createSellerProduct);
router.post("/seller/products/with-images", authRequired(["seller", "admin"]), productUpload.array("images", 5), createSellerProductWithImages);
router.post("/seller/products/:id/images", authRequired(["seller", "admin"]), productUpload.array("images", 5), uploadProductImages);
router.get("/seller/products", authRequired(["seller", "admin"]), getSellerProducts);
router.patch("/seller/products/:id", authRequired(["seller", "admin"]), updateSellerProduct);
router.delete("/seller/products/:id", authRequired(["seller", "admin"]), deleteSellerProduct);

// Stock & Status management
router.patch("/seller/products/:id/stock", authRequired(["seller", "admin"]), updateStock);
router.patch("/seller/products/:id/toggle-active", authRequired(["seller", "admin"]), toggleProductActive);

// Seller stats
router.get("/seller/stats", authRequired(["seller", "admin"]), getSellerStats);

// Demo products seed
router.post("/seller/seed-demo-products", authRequired(["seller", "admin"]), seedDemoProducts);

export default router;
