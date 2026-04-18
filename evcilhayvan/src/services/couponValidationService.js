import CartItem from "../models/CartItem.js";
import Coupon from "../models/Coupon.js";
import CouponUsage from "../models/CouponUsage.js";
import Order from "../models/Order.js";
import { resolveProductVariantSelection } from "../utils/variantSelection.js";

function createCouponError(statusCode, code, message, details = undefined) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  error.details = details;
  return error;
}

export async function getCouponUsageCount(couponId, userId) {
  if (!couponId || !userId) return 0;
  const usage = await CouponUsage.findOne({ couponId, userId }).select("count").lean();
  return Number(usage?.count || 0);
}

function isCouponApplicableToItem(coupon, item) {
  const storeId = item.storeId ? String(item.storeId) : null;
  const productId = item.productId ? String(item.productId) : null;
  const categoryId = item.categoryId ? String(item.categoryId) : null;

  if (coupon.store && storeId !== coupon.store.toString()) return false;

  if (Array.isArray(coupon.applicableProducts) && coupon.applicableProducts.length > 0) {
    const allowedProductIds = coupon.applicableProducts.map((id) => id.toString());
    if (!productId || !allowedProductIds.includes(productId)) return false;
  }

  if (Array.isArray(coupon.applicableCategories) && coupon.applicableCategories.length > 0) {
    const allowedCategoryIds = coupon.applicableCategories.map((id) => id.toString());
    if (!categoryId || !allowedCategoryIds.includes(categoryId)) return false;
  }

  return true;
}

export function buildCouponItemsFromOrder(products, orderItems) {
  return orderItems
    .map((item) => {
      const product = products.find((candidate) => candidate._id.toString() === item.product.toString());
      if (!product) return null;
      return {
        productId: product._id.toString(),
        storeId: product.store?.toString() || null,
        categoryId: product.category?.toString() || null,
        quantity: item.quantity,
        unitPrice: Number(item.price || 0),
        lineTotal: Number(item.price || 0) * Number(item.quantity || 0),
      };
    })
    .filter(Boolean);
}

export async function buildCouponContextFromUserCart(userId) {
  if (!userId) {
    return { items: [], totalAmount: 0 };
  }

  const cartItems = await CartItem.find({ user: userId }).populate("product");
  const items = [];
  let totalAmount = 0;

  for (const cartItem of cartItems) {
    if (!cartItem.product || cartItem.product.isActive === false) continue;

    try {
      const variantSelection = resolveProductVariantSelection(
        cartItem.product,
        { selectedVariants: cartItem.selectedVariants },
        cartItem.quantity,
        { skipStockCheck: true }
      );
      const unitPrice = Number(variantSelection.unitPrice || 0);
      const lineTotal = unitPrice * Number(cartItem.quantity || 0);
      totalAmount += lineTotal;
      items.push({
        productId: cartItem.product._id.toString(),
        storeId: cartItem.product.store?.toString() || null,
        categoryId: cartItem.product.category?.toString() || null,
        quantity: cartItem.quantity,
        unitPrice,
        lineTotal,
      });
    } catch (_) {
      continue;
    }
  }

  return { items, totalAmount };
}

export async function evaluateCouponByCode({
  code,
  userId = null,
  totalAmount,
  items = [],
  storeId = null,
}) {
  const normalizedCode = String(code || "").trim().toUpperCase();
  if (!normalizedCode) {
    throw createCouponError(400, "validation_error", "Kupon kodu gerekli");
  }

  const coupon = await Coupon.findOne({ code: normalizedCode, isActive: true });
  if (!coupon) {
    throw createCouponError(404, "not_found", "Kupon bulunamadi veya aktif degil");
  }

  return evaluateCouponDocument({
    coupon,
    userId,
    totalAmount,
    items,
    storeId,
  });
}

export async function evaluateCouponDocument({
  coupon,
  userId = null,
  totalAmount,
  items = [],
  storeId = null,
}) {
  const now = new Date();
  const normalizedTotal = Number(totalAmount || 0);

  if (!coupon?.isActive) {
    throw createCouponError(404, "not_found", "Kupon bulunamadi veya aktif degil");
  }
  if (coupon.validFrom > now || coupon.validUntil < now) {
    throw createCouponError(410, "coupon_expired", "Kuponun gecerlilik suresi dolmus");
  }
  if (coupon.usageLimit && coupon.usageCount >= coupon.usageLimit) {
    throw createCouponError(409, "usage_limit_exceeded", "Kupon kullanim limiti dolmus");
  }

  let usedCount = 0;
  if (userId && coupon.perUserLimit) {
    usedCount = await getCouponUsageCount(coupon._id, userId);
    if (usedCount >= coupon.perUserLimit) {
      throw createCouponError(
        409,
        "usage_limit_exceeded",
        `Bu kuponu en fazla ${coupon.perUserLimit} kez kullanabilirsiniz`
      );
    }
  }

  if (coupon.firstOrderOnly && userId) {
    const priorOrders = await Order.countDocuments({
      user: userId,
      status: { $ne: "cancelled" },
    });
    if (priorOrders > 0) {
      throw createCouponError(400, "first_order_only", "Bu kupon sadece ilk siparis icin gecerlidir");
    }
  }

  const normalizedItems = Array.isArray(items) ? items : [];
  let eligibleItems = normalizedItems;
  let eligibleSubtotal = normalizedTotal;

  const hasItemRestrictions =
    !!coupon.store ||
    (Array.isArray(coupon.applicableProducts) && coupon.applicableProducts.length > 0) ||
    (Array.isArray(coupon.applicableCategories) && coupon.applicableCategories.length > 0);

  if (normalizedItems.length > 0) {
    eligibleItems = normalizedItems.filter((item) => isCouponApplicableToItem(coupon, item));
    eligibleSubtotal = eligibleItems.reduce(
      (sum, item) => sum + Number(item.lineTotal || 0),
      0
    );
  } else if (coupon.store && storeId && coupon.store.toString() !== String(storeId)) {
    throw createCouponError(400, "store_mismatch", "Bu kupon bu magaza icin gecerli degil");
  } else if (hasItemRestrictions) {
    throw createCouponError(400, "coupon_context_required", "Kupon uygunlugu icin sepet baglami gerekli");
  }

  if (hasItemRestrictions && eligibleSubtotal <= 0) {
    throw createCouponError(400, "coupon_not_applicable", "Bu kupon sepetteki urunlere uygulanamiyor");
  }

  if (coupon.minPurchaseAmount && eligibleSubtotal < coupon.minPurchaseAmount) {
    throw createCouponError(
      400,
      "min_amount_required",
      `Minimum ${coupon.minPurchaseAmount} TL alisveris gereklidir`
    );
  }

  const calculation = coupon.calculateDiscount(eligibleSubtotal);
  if (calculation.error) {
    throw createCouponError(400, "discount_error", calculation.error);
  }

  const discountAmount = Number(calculation.discount || 0);

  return {
    coupon,
    items: eligibleItems,
    eligibleSubtotal,
    totalAmount: normalizedTotal || eligibleSubtotal,
    discountAmount,
    finalAmount: Math.max(0, (normalizedTotal || eligibleSubtotal) - discountAmount),
    remainingUses: userId && coupon.perUserLimit
      ? Math.max(0, coupon.perUserLimit - usedCount)
      : null,
    usedCount,
  };
}
