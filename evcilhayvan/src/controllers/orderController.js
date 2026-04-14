import mongoose from "mongoose";
import Order from "../models/Order.js";
import Product from "../models/Product.js";
import Coupon from "../models/Coupon.js";
import CouponUsage from "../models/CouponUsage.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";
import { encrypt } from "../utils/fieldCrypto.js";
import { sendEmail } from "../utils/mail.js";

function generateTrackingNumber() {
  return 'PAT' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).slice(2, 5).toUpperCase();
}

async function sendOrderConfirmationEmail(toEmail, trackingNumber, items, totalAmount) {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  const itemRows = items.map(i => `<tr><td>${i.name || 'Ürün'}</td><td>${i.quantity}</td><td>${i.price.toFixed(2)} ₺</td></tr>`).join('');
  const html = `
    <div style="font-family:sans-serif;max-width:500px;margin:auto;padding:24px;border:1px solid #e0e0e0;border-radius:8px">
      <h2 style="color:#1B4332">Siparişiniz Alındı! 🐾</h2>
      <p>Merhaba,</p>
      <p>Siparişiniz başarıyla oluşturuldu. Takip numaranız: <strong>${trackingNumber}</strong></p>
      <table style="width:100%;border-collapse:collapse;margin:16px 0">
        <thead><tr style="background:#f5f5f5"><th style="text-align:left;padding:8px">Ürün</th><th style="padding:8px">Adet</th><th style="padding:8px">Fiyat</th></tr></thead>
        <tbody>${itemRows}</tbody>
      </table>
      <p><strong>Toplam: ${totalAmount.toFixed(2)} ₺</strong></p>
      <p>
        <a href="${appUrl}/orders/track/${trackingNumber}" style="display:inline-block;padding:12px 24px;background:#2D6A4F;color:#fff;border-radius:8px;text-decoration:none">
          Siparişimi Takip Et
        </a>
      </p>
      <p style="color:#888;font-size:12px">Pati Arkadaşı — Evcil Hayvan Platformu</p>
    </div>
  `;
  try {
    await sendEmail(toEmail, `Siparişiniz Alındı — ${trackingNumber}`, html);
  } catch (err) {
    console.error('[createOrder] email error (non-critical)', err.message);
  }
}

// Sipariş oluştur (stok kontrolü ve düşümü ile — kayıtlı + misafir kullanıcı desteği)
export async function createOrder(req, res) {
  try {
    const userId = req.user?.sub || null;  // misafir = null

    const { items, shippingAddress, paymentMethod, notes, couponCode, guestInfo } = req.body || {};

    // Misafir siparişi zorunlu alan kontrolü
    if (!userId) {
      if (!guestInfo?.name || !guestInfo?.phone || !guestInfo?.email) {
        return sendError(res, 400, "Misafir sipariş için ad, telefon ve email zorunludur", "guest_info_required");
      }
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
      return sendError(res, 400, "Siparis öğeleri gereklidir", "validation_error");
    }

    // Ürünleri ve stokları kontrol et
    const productIds = items.map(item => item.productId);
    const products = await Product.find({ _id: { $in: productIds } });

    if (products.length !== productIds.length) {
      return sendError(res, 400, "Bazı ürünler bulunamadı", "products_not_found");
    }

    const orderItems = [];
    let totalAmount = 0;

    for (const item of items) {
      const product = products.find(p => p._id.toString() === item.productId);

      if (!product) {
        return sendError(res, 400, `Ürün bulunamadı: ${item.productId}`, "product_not_found");
      }

      if (!product.isActive) {
        return sendError(res, 400, `Ürün aktif değil: ${product.name || product.title}`, "product_inactive");
      }

      // Kendi ürününü satın almayı engelle (sadece kayıtlı kullanıcılar için)
      if (userId && product.seller && product.seller.toString() === userId) {
        return sendError(res, 400, `Kendi urunlerinizi satin alamazsiniz: ${product.name || product.title}`, "self_purchase_denied");
      }

      // Variant validasyonu
      let itemPrice = product.price;
      if (item.variantName && item.variantLabel) {
        const variant = product.variants?.find((v) => v.name === item.variantName);
        const option = variant?.options?.find((o) => o.label === item.variantLabel);
        if (!variant || !option) {
          return sendError(res, 400, `Gecersiz variant: ${item.variantName}/${item.variantLabel}`, "invalid_variant");
        }
        if (option.stock < item.quantity) {
          return sendError(res, 400, `Variant stok yetersiz: ${option.label} (Mevcut: ${option.stock})`, "insufficient_stock");
        }
        itemPrice = product.price + (option.priceDiff || 0);
      } else if (product.variants?.length > 0) {
        return sendError(res, 400, `${product.name || product.title} icin variant secimi zorunludur`, "variant_required");
      } else {
        if (product.stock < item.quantity) {
          return sendError(
            res,
            400,
            `Yetersiz stok: ${product.name || product.title} (Mevcut: ${product.stock}, İstenen: ${item.quantity})`,
            "insufficient_stock"
          );
        }
      }

      const itemTotal = itemPrice * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        product: product._id,
        quantity: item.quantity,
        price: itemPrice,
        name: product.name || product.title,
        image: product.images?.[0] || product.photos?.[0] || null,
        variantName: item.variantName || null,
        variantLabel: item.variantLabel || null,
      });
    }

    // ── Kupon uygulama ──────────────────────────────────────────────────────
    const originalAmount = totalAmount;
    let discountAmount = 0;
    let appliedCoupon = null;

    if (couponCode && userId) {
      const coupon = await Coupon.findOne({ code: couponCode.toUpperCase(), isActive: true });
      if (coupon) {
        const validity = coupon.isValid();
        if (validity.valid) {
          // Kişi başı limit: bileşik index ile O(log n) sorgu
          const userUsageCount = await CouponUsage.countDocuments({ couponId: coupon._id, userId });
          const belowPerUserLimit = userUsageCount < (coupon.perUserLimit || 1);

          // İlk sipariş kontrolü: sadece ücretli sipariş var mı bak
          let passesFirstOrderCheck = true;
          if (coupon.firstOrderOnly) {
            const paidOrders = await Order.countDocuments({ user: userId, paymentStatus: 'paid' });
            passesFirstOrderCheck = paidOrders === 0;
          }

          if (belowPerUserLimit && passesFirstOrderCheck) {
            const calc = coupon.calculateDiscount(originalAmount);
            if (!calc.error) {
              discountAmount = calc.discount;
              appliedCoupon = coupon;
            }
          }
        }
      }
    }

    const finalAmount = originalAmount - discountAmount;

    // ── Stok düşümü + Sipariş oluşturma + Kupon kaydı — MongoDB transaction (atomik) ────
    const session = await mongoose.startSession();
    session.startTransaction();
    let order;
    try {
      // Stokları atomik olarak düş (race condition koruması)
      for (const item of items) {
        if (item.variantName && item.variantLabel) {
          // Variant stok düşümü
          const updated = await Product.findOneAndUpdate(
            {
              _id: item.productId,
              "variants.name": item.variantName,
              "variants.options": { $elemMatch: { label: item.variantLabel, stock: { $gte: item.quantity } } },
            },
            { $inc: { "variants.$[v].options.$[o].stock": -item.quantity } },
            { arrayFilters: [{ "v.name": item.variantName }, { "o.label": item.variantLabel }], new: true, session }
          );
          if (!updated) {
            await session.abortTransaction();
            return sendError(res, 400, `Variant stok yetersiz: ${item.variantLabel}`, "insufficient_stock");
          }
        } else {
          // Normal stok düşümü
          const updated = await Product.findOneAndUpdate(
            { _id: item.productId, stock: { $gte: item.quantity } },
            { $inc: { stock: -item.quantity } },
            { new: true, session }
          );
          if (!updated) {
            const product = products.find(p => p._id.toString() === item.productId);
            await session.abortTransaction();
            return sendError(res, 400, `Stok yetersiz: ${product?.name || product?.title || item.productId}`, "insufficient_stock");
          }
        }
      }

      // Misafir TC'sini şifrele
      let encryptedGuestInfo;
      if (!userId && guestInfo) {
        encryptedGuestInfo = {
          name: guestInfo.name,
          phone: guestInfo.phone,
          email: guestInfo.email,
          nationalId: guestInfo.nationalId ? encrypt(guestInfo.nationalId) : undefined,
          address: guestInfo.address || {},
        };
      }

      const trackingNumber = generateTrackingNumber();

      [order] = await Order.create([{
        user: userId || undefined,
        guestInfo: encryptedGuestInfo,
        items: orderItems,
        totalAmount: finalAmount,
        originalAmount,
        discountAmount,
        couponCode: appliedCoupon ? appliedCoupon.code : undefined,
        shippingAddress: shippingAddress || (encryptedGuestInfo?.address ? {
          street: encryptedGuestInfo.address.street,
          city: encryptedGuestInfo.address.city,
          state: encryptedGuestInfo.address.district,
        } : {}),
        paymentMethod: paymentMethod || "credit_card",
        notes,
        trackingNumber,
        status: "pending",
        paymentStatus: "pending",
        statusHistory: [{ status: "pending", note: "Sipariş oluşturuldu", updatedAt: new Date() }],
      }], { session });

      // Kupon kullanımını transaction içinde kaydet (race condition önleme)
      if (appliedCoupon) {
        const usageDoc = await CouponUsage.findOneAndUpdate(
          { couponId: appliedCoupon._id, userId },
          { $inc: { count: 1 }, $setOnInsert: { orderId: order._id, discountAmount, originalAmount, finalAmount } },
          { upsert: true, new: true, session }
        );
        if (usageDoc.count > (appliedCoupon.perUserLimit || 1)) {
          await session.abortTransaction();
          return sendError(res, 400, "Kupon kullanim limitiniz doldu", "usage_limit_exceeded");
        }
        await Coupon.findByIdAndUpdate(appliedCoupon._id, { $inc: { usageCount: 1 } }, { session });
      }

      await session.commitTransaction();
    } catch (txErr) {
      await session.abortTransaction();
      throw txErr;
    } finally {
      session.endSession();
    }
    // ── Transaction sonu ──────────────────────────────────────────────────

    // Audit log
    try {
      await recordAudit("order.create", {
        userId: userId || 'guest',
        entityType: "order",
        entityId: order._id.toString(),
        metadata: {
          itemCount: orderItems.length,
          totalAmount: finalAmount,
          isGuest: !userId,
        },
      });
    } catch (auditErr) {
      console.error("[createOrder] audit error (non-critical)", auditErr.message);
    }

    // Sipariş onay emaili gönder (kayıtlı veya misafir)
    const recipientEmail = guestInfo?.email || null;
    if (recipientEmail || userId) {
      let toEmail = recipientEmail;
      if (!toEmail && userId) {
        try {
          const User = (await import("../models/User.js")).default;
          const user = await User.findById(userId).select('email');
          toEmail = user?.email;
        } catch (_) {}
      }
      if (toEmail) {
        await sendOrderConfirmationEmail(toEmail, order.trackingNumber, orderItems, finalAmount);
      }
    }

    // Populate product details with seller info
    await order.populate({
      path: "items.product",
      select: "name title images photos price seller",
      populate: { path: "seller", select: "name logoUrl" },
    });

    return sendOk(res, 201, { order });
  } catch (err) {
    console.error("[createOrder] error", err);
    return sendError(res, 500, "Siparis olusturulamadi", "internal_error", err.message);
  }
}

// Kullanıcının siparişlerini getir
export async function getMyOrders(req, res) {
  try {
    const userId = req.user?.sub;
    if (!userId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");

    const orders = await Order.find({ user: userId })
      .sort({ createdAt: -1 })
      .populate({
        path: "items.product",
        select: "name title images photos price seller",
        populate: { path: "seller", select: "name logoUrl" },
      })
      .lean();

    // Kullanıcının tüm review'larını çek
    const Review = (await import("../models/Review.js")).default;
    const userReviews = await Review.find({ user: userId });

    // Review'ları productId'ye göre map'le
    const reviewMap = {};
    userReviews.forEach(review => {
      reviewMap[review.product.toString()] = {
        id: review._id.toString(),
        rating: review.rating,
        comment: review.comment,
      };
    });

    // Her siparişteki her ürüne review bilgisini ekle (.lean() ile zaten plain object)
    const ordersWithReviews = orders.map(order => ({
      ...order,
      items: order.items.map(item => {
        const productId = item.product?._id?.toString() || item.product?.toString();
        return { ...item, myReview: reviewMap[productId] || null };
      }),
    }));

    return sendOk(res, 200, { orders: ordersWithReviews });
  } catch (err) {
    console.error("[getMyOrders] error", err);
    return sendError(res, 500, "Siparisler getirilemedi", "internal_error", err.message);
  }
}

// Sipariş detayı
export async function getOrderById(req, res) {
  try {
    const userId = req.user?.sub;
    const { id } = req.params;

    const order = await Order.findOne({ _id: id, user: userId }).populate(
      "items.product",
      "name title images photos seller"
    );

    if (!order) {
      return sendError(res, 404, "Siparis bulunamadi", "order_not_found");
    }

    return sendOk(res, 200, { order });
  } catch (err) {
    console.error("[getOrderById] error", err);
    return sendError(res, 500, "Siparis getirilemedi", "internal_error", err.message);
  }
}

// Siparişi iptal et (stok geri yükle)
export async function cancelOrder(req, res) {
  try {
    const userId = req.user?.sub;
    const { id } = req.params;

    const order = await Order.findOne({ _id: id, user: userId });

    if (!order) {
      return sendError(res, 404, "Siparis bulunamadi", "order_not_found");
    }

    if (order.status === "cancelled") {
      return sendError(res, 400, "Siparis zaten iptal edilmis", "already_cancelled");
    }

    if (order.status === "delivered") {
      return sendError(res, 400, "Teslim edilen siparis iptal edilemez", "cannot_cancel_delivered");
    }

    // Stokları geri yükle + sipariş güncelle (transaction ile atomik)
    const cancelSession = await mongoose.startSession();
    cancelSession.startTransaction();
    try {
      for (const item of order.items) {
        await Product.findByIdAndUpdate(
          item.product,
          { $inc: { stock: item.quantity } },
          { session: cancelSession }
        );
      }
      order.status = "cancelled";
      order.paymentStatus = order.paymentStatus === "paid" ? "refunded" : "failed";
      await order.save({ session: cancelSession });
      await cancelSession.commitTransaction();
    } catch (txErr) {
      await cancelSession.abortTransaction();
      throw txErr;
    } finally {
      cancelSession.endSession();
    }

    try {
      await recordAudit("order.cancel", {
        userId,
        entityType: "order",
        entityId: order._id.toString(),
      });
    } catch (auditErr) {
      console.error("[cancelOrder] audit error (non-critical)", auditErr.message);
    }

    return sendOk(res, 200, { order, message: "Siparis iptal edildi" });
  } catch (err) {
    console.error("[cancelOrder] error", err);
    return sendError(res, 500, "Siparis iptal edilemedi", "internal_error", err.message);
  }
}

// === SELLER ENDPOINTS ===

// Satıcının siparişlerini getir (kendi ürünlerini içeren)
export async function getSellerOrders(req, res) {
  try {
    const sellerId = req.user?.sub;
    if (!sellerId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 100));

    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    const orderQuery = Order.find({
      "items.product": { $in: productIds },
    })
      .sort({ createdAt: -1 })
      .populate("user", "name email avatarUrl")
      .populate({
        path: "items.product",
        select: "name title images photos price seller",
        populate: { path: "seller", select: "name logoUrl" },
      })
      .lean();

    if (Number.isFinite(limit)) {
      orderQuery.limit(limit);
    }

    const orders = await orderQuery;

    const filteredOrders = orders.map(order => {
      const items = order.items.filter(item =>
        productIds.some(pid => pid.toString() === item.product?._id?.toString())
      );
      return {
        ...order,
        items,
        sellerTotal: items.reduce((sum, item) => sum + item.price * item.quantity, 0),
      };
    });

    return sendOk(res, 200, { orders: filteredOrders });
  } catch (err) {
    console.error("[getSellerOrders] error", err);
    return sendError(res, 500, "Siparisler getirilemedi", "internal_error", err.message);
  }
}

// Sipariş durumunu güncelle (seller)
export async function updateOrderStatus(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;
    const { status, trackingNumber, carrier, estimatedDelivery } = req.body;

    const validStatuses = ["processing", "shipped", "delivered"];
    if (!validStatuses.includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "invalid_status");
    }

    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    const order = await Order.findOne({
      _id: id,
      "items.product": { $in: productIds },
    });

    if (!order) {
      return sendError(res, 404, "Siparis bulunamadi", "order_not_found");
    }

    if (order.status === "cancelled") {
      return sendError(res, 400, "Iptal edilen siparis güncellenemez", "order_cancelled");
    }

    const validTransitions = {
      pending: ["processing"],
      processing: ["shipped"],
      shipped: ["delivered"],
    };
    const allowed = validTransitions[order.status] || [];
    if (!allowed.includes(status)) {
      return sendError(res, 400, `'${order.status}' durumundan '${status}' durumuna gecilemez`, "invalid_transition");
    }

    order.status = status;
    if (trackingNumber !== undefined) order.trackingNumber = trackingNumber;
    if (carrier !== undefined) order.carrier = carrier;
    if (estimatedDelivery !== undefined) {
      order.estimatedDelivery = estimatedDelivery ? new Date(estimatedDelivery) : undefined;
    }

    order.statusHistory = order.statusHistory || [];
    order.statusHistory.push({
      status,
      note: trackingNumber
        ? `${carrier || "Kargo"} - Takip No: ${trackingNumber}`
        : `Durum guncellendi: ${status}`,
      updatedAt: new Date(),
    });

    if (status === "delivered") {
      order.paymentStatus = "paid";
    }
    await order.save();

    await recordAudit("order.status_update", {
      userId: sellerId,
      entityType: "order",
      entityId: order._id.toString(),
      metadata: { newStatus: status },
    });

    return sendOk(res, 200, { order });
  } catch (err) {
    console.error("[updateOrderStatus] error", err);
    return sendError(res, 500, "Siparis durumu guncellenemedi", "internal_error", err.message);
  }
}

// Satıcı sipariş istatistikleri
export async function getSellerOrderStats(req, res) {
  try {
    const sellerId = req.user?.sub;

    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    const orders = await Order.find({
      "items.product": { $in: productIds },
    }).populate("items.product", "name title");

    let totalRevenue = 0;
    let pendingOrders = 0;
    let processingOrders = 0;
    let shippedOrders = 0;
    let deliveredOrders = 0;
    let cancelledOrders = 0;
    let totalItemsSold = 0;
    let revenueThisMonth = 0;
    let ordersThisMonth = 0;
    let completedOrderCount = 0;
    const topProductMap = new Map();
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    for (const order of orders) {
      const sellerItems = order.items.filter(item =>
        productIds.some(pid => pid.toString() === item.product?._id?.toString() || pid.toString() === item.product?.toString())
      );

      const sellerTotal = sellerItems.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      if (order.status !== "cancelled") {
        totalRevenue += sellerTotal;
        totalItemsSold += sellerItems.reduce((sum, item) => sum + item.quantity, 0);
        completedOrderCount += 1;
        if (order.createdAt >= monthStart) {
          revenueThisMonth += sellerTotal;
          ordersThisMonth += 1;
        }

        for (const item of sellerItems) {
          const productId = item.product?._id?.toString() || item.product?.toString() || item.name;
          const existing = topProductMap.get(productId) || {
            _id: productId,
            name: item.product?.name || item.product?.title || item.name || "Urun",
            totalSold: 0,
            revenue: 0,
          };
          existing.totalSold += item.quantity || 0;
          existing.revenue += (item.price || 0) * (item.quantity || 0);
          topProductMap.set(productId, existing);
        }
      }

      switch (order.status) {
        case "pending":
          pendingOrders++;
          break;
        case "processing":
          processingOrders++;
          break;
        case "shipped":
          shippedOrders++;
          break;
        case "delivered":
          deliveredOrders++;
          break;
        case "cancelled":
          cancelledOrders++;
          break;
      }
    }

    const averageOrderValue = completedOrderCount > 0
      ? Math.round((totalRevenue / completedOrderCount) * 100) / 100
      : 0;

    const topProducts = Array.from(topProductMap.values())
      .sort((a, b) => b.totalSold - a.totalSold)
      .slice(0, 5)
      .map((item) => ({
        ...item,
        revenue: Math.round(item.revenue * 100) / 100,
      }));

    const stats = {
      totalOrders: orders.length,
      pendingOrders,
      processingOrders,
      shippedOrders,
      deliveredOrders,
      cancelledOrders,
      pending: pendingOrders,
      processing: processingOrders,
      shipped: shippedOrders,
      delivered: deliveredOrders,
      cancelled: cancelledOrders,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      totalItemsSold,
      revenueThisMonth: Math.round(revenueThisMonth * 100) / 100,
      ordersThisMonth,
      averageOrderValue,
      topProducts,
    };

    return sendOk(res, 200, {
      ...stats,
      stats,
    });
  } catch (err) {
    console.error("[getSellerOrderStats] error", err);
    return sendError(res, 500, "Istatistikler alinamadi", "internal_error", err.message);
  }
}

// Son 6 ayın aylık gelir + sipariş grafiği  GET /api/seller/orders/chart
export async function getSellerRevenueChart(req, res) {
  try {
    const sellerId = req.user?.sub;
    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    const now = new Date();
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

    const orders = await Order.find({
      "items.product": { $in: productIds },
      createdAt: { $gte: sixMonthsAgo },
      status: { $ne: "cancelled" },
    }).select("items createdAt status");

    // Build map: "YYYY-MM" → { revenue, count }
    const monthMap = {};
    for (let i = 0; i < 6; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - 5 + i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
      monthMap[key] = { revenue: 0, orders: 0 };
    }

    for (const order of orders) {
      const key = `${order.createdAt.getFullYear()}-${String(order.createdAt.getMonth() + 1).padStart(2, "0")}`;
      if (!monthMap[key]) continue;
      const sellerItems = order.items.filter(item =>
        productIds.some(pid => pid.toString() === item.product?.toString())
      );
      const sellerTotal = sellerItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
      monthMap[key].revenue += sellerTotal;
      monthMap[key].orders += 1;
    }

    const chart = Object.entries(monthMap).map(([month, data]) => ({
      month,
      revenue: Math.round(data.revenue * 100) / 100,
      orders: data.orders,
    }));

    return sendOk(res, 200, { chart, data: chart });
  } catch (err) {
    console.error("[getSellerRevenueChart] error", err);
    return sendError(res, 500, "Grafik verisi alinamadi", "internal_error", err.message);
  }
}
