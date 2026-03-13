import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  createOrder,
  getMyOrders,
  getOrderById,
  cancelOrder,
  getSellerOrders,
  updateOrderStatus,
  getSellerOrderStats,
} from "../controllers/orderController.js";

const router = Router();

// === CUSTOMER ENDPOINTS ===
// Sipariş oluştur
router.post("/orders", authRequired(), createOrder);

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

export default router;