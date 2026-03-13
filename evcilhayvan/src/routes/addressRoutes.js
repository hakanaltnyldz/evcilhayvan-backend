// src/routes/addressRoutes.js

import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  getAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
  getDefaultAddress,
} from "../controllers/addressController.js";

const router = Router();

// Tüm adresleri getir
router.get("/addresses", authRequired(), getAddresses);

// Varsayılan adresi getir
router.get("/addresses/default", authRequired(), getDefaultAddress);

// Adres ekle
router.post("/addresses", authRequired(), addAddress);

// Adres güncelle
router.patch("/addresses/:id", authRequired(), updateAddress);

// Adres sil
router.delete("/addresses/:id", authRequired(), deleteAddress);

// Varsayılan adres yap
router.patch("/addresses/:id/default", authRequired(), setDefaultAddress);

export default router;