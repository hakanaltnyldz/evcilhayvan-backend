import { Router } from "express";
import { body, param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import { handleValidation } from "../middlewares/validate.js";
import {
  createOrder,
  getMyOrders,
  getOrderById,
  cancelOrder,
  getSellerOrders,
  updateOrderStatus,
  getSellerOrderStats,
  getSellerRevenueChart,
} from "../controllers/orderController.js";

const router = Router();

// === CUSTOMER ENDPOINTS ===
// Sipariş oluştur
router.post(
  "/orders",
  authRequired(),
  [
    body("items").isArray({ min: 1 }).withMessage("En az 1 ürün gerekli"),
    body("items.*.productId").notEmpty().isMongoId().withMessage("Geçersiz ürün ID"),
    body("items.*.quantity").isInt({ min: 1, max: 100 }).withMessage("Miktar 1-100 arasında olmalı"),
  ],
  handleValidation,
  createOrder,
);

// Siparişlerimi getir
router.get("/orders/my", authRequired(), getMyOrders);

// Sipariş detayı
router.get("/orders/:id", authRequired(), getOrderById);

// Siparişi iptal et
router.patch("/orders/:id/cancel", authRequired(), cancelOrder);

// === SELLER ENDPOINTS ===
// Satıcı siparişleri
router.get("/seller/orders", authRequired(["seller", "admin"]), getSellerOrders);

// Sipariş durumu güncelle
router.patch("/seller/orders/:id/status", authRequired(["seller", "admin"]), updateOrderStatus);

// Satıcı sipariş istatistikleri
router.get("/seller/orders/stats", authRequired(["seller", "admin"]), getSellerOrderStats);

// Satıcı aylık gelir grafiği (son 6 ay)
router.get("/seller/orders/chart", authRequired(["seller", "admin"]), getSellerRevenueChart);

export default router;