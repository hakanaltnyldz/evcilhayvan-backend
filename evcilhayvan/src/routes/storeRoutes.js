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

router.get("/discover", discoverStores);
router.get("/feed", productFeed);
router.get("/me", authRequired(["seller", "admin"]), getMyStore);
router.get("/me/products", authRequired(["seller", "admin"]), getMyProducts);
router.post("/apply", authRequired(), applySeller); // legacy
router.post("/create", authRequired(), applySeller);
router.post("/", authRequired(), applySeller); // alias to meet /api/store
router.post("/products", authRequired(["seller", "admin"]), addProduct);
router.post("/me/products", authRequired(["seller", "admin"]), addProduct);
router.get("/:storeId/products", getStoreProducts);
router.get("/:storeId", getStore);

// Mağaza profili güncelleme (satıcı)
router.patch("/me/profile", authRequired(["seller", "admin"]), async (req, res) => {
  try {
    const sellerId = req.user.sub;
    const allowed = ["name","description","bannerUrl","phone","website","instagram","twitter","facebook","workingHours"];
    const update = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) update[key] = req.body[key];
    }
    const store = await Store.findOneAndUpdate({ owner: sellerId }, update, { new: true });
    if (!store) return sendError(res, 404, "Mağaza bulunamadı", "store_not_found");
    return sendOk(res, 200, { store });
  } catch (err) {
    return sendError(res, 500, "Mağaza güncellenemedi", "internal_error", err.message);
  }
});

export default router;
