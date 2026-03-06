import Order from "../models/Order.js";
import Product from "../models/Product.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

// Sipariş oluştur (stok kontrolü ve düşümü ile)
export async function createOrder(req, res) {
  try {
    const userId = req.user?.sub;
    if (!userId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");

    const { items, shippingAddress, paymentMethod, notes } = req.body || {};

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

      // Kendi ürününü satın almayı engelle
      if (product.seller && product.seller.toString() === userId) {
        return sendError(res, 400, `Kendi urunlerinizi satin alamazsiniz: ${product.name || product.title}`, "self_purchase_denied");
      }

      if (product.stock < item.quantity) {
        return sendError(
          res,
          400,
          `Yetersiz stok: ${product.name || product.title} (Mevcut: ${product.stock}, İstenen: ${item.quantity})`,
          "insufficient_stock"
        );
      }

      const itemTotal = product.price * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        product: product._id,
        quantity: item.quantity,
        price: product.price,
        name: product.name || product.title,
        image: product.images?.[0] || product.photos?.[0] || null,
      });
    }

    // Stokları atomik olarak güncelle (race condition önleme)
    for (const item of items) {
      const updated = await Product.findOneAndUpdate(
        { _id: item.productId, stock: { $gte: item.quantity } },
        { $inc: { stock: -item.quantity } },
        { new: true }
      );
      if (!updated) {
        // Stok yetersiz - önceki stok düşümlerini geri al
        for (const prevItem of items) {
          if (prevItem.productId === item.productId) break;
          await Product.findByIdAndUpdate(
            prevItem.productId,
            { $inc: { stock: prevItem.quantity } }
          );
        }
        const product = products.find(p => p._id.toString() === item.productId);
        return sendError(res, 400, `Stok yetersiz: ${product?.name || product?.title || item.productId}`, "insufficient_stock");
      }
    }

    // Siparişi oluştur
    const order = await Order.create({
      user: userId,
      items: orderItems,
      totalAmount,
      shippingAddress: shippingAddress || {},
      paymentMethod: paymentMethod || "credit_card",
      notes,
      status: "pending",
      paymentStatus: "pending",
    });

    // Audit log
    try {
      await recordAudit("order.create", {
        userId,
        entityType: "order",
        entityId: order._id.toString(),
        metadata: {
          itemCount: orderItems.length,
          totalAmount,
        },
      });
    } catch (auditErr) {
      console.error("[createOrder] audit error (non-critical)", auditErr.message);
    }

    // Populate product details
    await order.populate("items.product", "name title images photos");

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
      .populate("items.product", "name title images photos");

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

    // Her siparişteki her ürüne review bilgisini ekle
    const ordersWithReviews = orders.map(order => {
      const orderObj = order.toObject();
      orderObj.items = orderObj.items.map(item => {
        const productId = item.product?._id?.toString() || item.product?.toString();
        const review = reviewMap[productId];
        return {
          ...item,
          myReview: review || null,
        };
      });
      return orderObj;
    });

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

    // Stokları geri yükle
    for (const item of order.items) {
      await Product.findByIdAndUpdate(
        item.product,
        { $inc: { stock: item.quantity } }
      );
    }

    // Siparişi güncelle
    order.status = "cancelled";
    order.paymentStatus = order.paymentStatus === "paid" ? "refunded" : "failed";
    await order.save();

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

    // Satıcının ürünlerini bul
    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    // Bu ürünleri içeren siparişleri bul
    const orders = await Order.find({
      "items.product": { $in: productIds },
    })
      .sort({ createdAt: -1 })
      .populate("user", "name email")
      .populate("items.product", "name title images photos seller");

    // Sadece satıcının ürünlerini filtrele
    const filteredOrders = orders.map(order => {
      const orderObj = order.toObject();
      orderObj.items = orderObj.items.filter(item =>
        productIds.some(pid => pid.toString() === item.product?._id?.toString())
      );
      // Satıcının ürünlerinin toplamını hesapla
      orderObj.sellerTotal = orderObj.items.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );
      return orderObj;
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
    const { status } = req.body;

    const validStatuses = ["processing", "shipped", "delivered"];
    if (!validStatuses.includes(status)) {
      return sendError(res, 400, "Gecersiz durum", "invalid_status");
    }

    // Satıcının ürünlerini bul
    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    // Siparişi bul ve satıcının ürünlerini içerdiğini doğrula
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

    order.status = status;
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

    // Satıcının ürünlerini bul
    const sellerProducts = await Product.find({ seller: sellerId }).select("_id");
    const productIds = sellerProducts.map(p => p._id);

    // Bu ürünleri içeren siparişleri bul
    const orders = await Order.find({
      "items.product": { $in: productIds },
    });

    let totalRevenue = 0;
    let pendingOrders = 0;
    let processingOrders = 0;
    let shippedOrders = 0;
    let deliveredOrders = 0;
    let cancelledOrders = 0;
    let totalItemsSold = 0;

    for (const order of orders) {
      // Sadece satıcının ürünlerini hesapla
      const sellerItems = order.items.filter(item =>
        productIds.some(pid => pid.toString() === item.product?.toString())
      );

      const sellerTotal = sellerItems.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      if (order.status !== "cancelled") {
        totalRevenue += sellerTotal;
        totalItemsSold += sellerItems.reduce((sum, item) => sum + item.quantity, 0);
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

    return sendOk(res, 200, {
      stats: {
        totalOrders: orders.length,
        pendingOrders,
        processingOrders,
        shippedOrders,
        deliveredOrders,
        cancelledOrders,
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        totalItemsSold,
      },
    });
  } catch (err) {
    console.error("[getSellerOrderStats] error", err);
    return sendError(res, 500, "Istatistikler alinamadi", "internal_error", err.message);
  }
}