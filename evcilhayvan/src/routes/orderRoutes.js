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
  createReturnRequest,
  getMyReturnRequests,
  resolveReturnRequest,
} from "../controllers/orderController.js";
import Order from "../models/Order.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

const router = Router();

// === PUBLIC ENDPOINTS (auth gerekmez) ===
// Takip numarasıyla sipariş sorgula
router.get("/orders/track/:trackingNumber", async (req, res) => {
  try {
    const order = await Order.findOne({ trackingNumber: req.params.trackingNumber })
      .select('status trackingNumber carrier estimatedDelivery statusHistory createdAt totalAmount guestInfo.name');
    if (!order) return sendError(res, 404, "Sipariş bulunamadı", "order_not_found");
    return sendOk(res, 200, { order });
  } catch (err) {
    return sendError(res, 500, "Sipariş sorgulanamadı", "internal_error", err.message);
  }
});

// === CUSTOMER ENDPOINTS ===
// Sipariş oluştur (kayıtlı veya misafir)
router.post(
  "/orders",
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

// İade talebi oluştur
router.post("/orders/:id/return-request", authRequired(), createReturnRequest);

// İade taleplerim
router.get("/orders/returns/my", authRequired(), getMyReturnRequests);

// === SELLER ENDPOINTS ===
// Satıcı siparişleri
router.get("/seller/orders", authRequired(["seller", "admin"]), getSellerOrders);

// Sipariş durumu güncelle
router.patch("/seller/orders/:id/status", authRequired(["seller", "admin"]), updateOrderStatus);
router.patch("/seller/orders/:id/return-status", authRequired(["seller", "admin"]), resolveReturnRequest);

// Satıcı sipariş istatistikleri
router.get("/seller/orders/stats", authRequired(["seller", "admin"]), getSellerOrderStats);

// Satıcı aylık gelir grafiği (son 6 ay)
router.get("/seller/orders/chart", authRequired(["seller", "admin"]), getSellerRevenueChart);

export default router;
