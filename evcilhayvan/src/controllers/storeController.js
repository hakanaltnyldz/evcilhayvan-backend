import Store from "../models/Store.js";
import Product from "../models/Product.js";
import User from "../models/User.js";
import SellerProfile from "../models/SellerProfile.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import { issueTokens } from "../utils/tokens.js";
import { recordAudit } from "../utils/audit.js";

function buildUserPayload(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    city: user.city,
    role: user.role,
    avatarUrl: user.avatarUrl,
    isSeller: user.isSeller === true,
  };
}

const storePopulate = {
  path: "store",
  select: "name description logoUrl owner isActive",
  populate: { path: "owner", select: "name avatarUrl city" },
};

const ownerSelect = { path: "owner", select: "name avatarUrl city" };

export async function discoverStores(_req, res) {
  try {
    const stores = await Store.find({ isActive: true })
      .populate(ownerSelect)
      .sort({ createdAt: -1 })
      .lean();
    return sendOk(res, 200, { stores });
  } catch (err) {
    return sendError(res, 500, "Magazalar alinmadi", "internal_error");
  }
}

export async function productFeed(_req, res) {
  try {
    const activeStoreDocs = await Store.find({ isActive: true }).select("_id").lean();
    const activeStoreIds = activeStoreDocs.map((s) => s._id);
    const products = await Product.find({ isActive: true, store: { $in: activeStoreIds } })
      .populate(storePopulate)
      .sort({ createdAt: -1 })
      .limit(40)
      .lean();
    return sendOk(res, 200, { products });
  } catch (err) {
    return sendError(res, 500, "Urunler getirilemedi", "internal_error");
  }
}

export async function getMyStore(req, res) {
  try {
    const store = await Store.findOne({ owner: req.user.sub }).populate(ownerSelect);
    if (!store) {
      return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
    }
    return sendOk(res, 200, { store });
  } catch (err) {
    console.error("[getMyStore]", err);
    return sendError(res, 500, "Magaza alinmadi", "internal_error", err.message);
  }
}

export async function getMyProducts(req, res) {
  try {
    const store = await Store.findOne({ owner: req.user.sub });
    if (!store) {
      return sendError(res, 404, "Henuz magazaniz yok", "store_not_found");
    }
    const products = await Product.find({ store: store._id }).populate(storePopulate).sort({ createdAt: -1 });
    return sendOk(res, 200, { products });
  } catch (err) {
    console.error("[getMyProducts]", err);
    return sendError(res, 500, "Urunler alinmadi", "internal_error", err.message);
  }
}

export async function getStore(req, res) {
  try {
    const { storeId } = req.params;
    const store = await Store.findById(storeId).populate(ownerSelect);
    if (!store || !store.isActive) {
      return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
    }
    return sendOk(res, 200, { store });
  } catch (err) {
    console.error("[getStore]", err);
    return sendError(res, 500, "Magaza alinmadi", "internal_error", err.message);
  }
}

export async function getStoreProducts(req, res) {
  try {
    const { storeId } = req.params;
    const store = await Store.findById(storeId);
    if (!store || !store.isActive) {
      return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
    }
    const products = await Product.find({ store: storeId, isActive: true })
      .populate(storePopulate)
      .sort({ createdAt: -1 })
      .lean();
    return sendOk(res, 200, { products });
  } catch (err) {
    return sendError(res, 500, "Urunler yuklenemedi", "internal_error");
  }
}

// Direct seller creation without admin approval
export async function applySeller(req, res) {
  try {
  const storeName = req.body?.storeName || req.body?.name;
  const { description, logoUrl } = req.body || {};
  if (!storeName) {
    return sendError(res, 400, "Mağaza adı gerekli", "validation_error");
  }

  const user = await User.findById(req.user.sub);
  if (!user) {
    return sendError(res, 404, "Kullanıcı bulunamadı", "user_not_found");
  }

  // Önce mağaza var mı kontrol et
  const existingStore = await Store.findOne({ owner: user._id });
  if (existingStore) {
    const populated = await existingStore.populate(ownerSelect);
    return sendError(res, 400, "Zaten bir mağazanız var. Mağazanızı yönetmek için Satıcı Paneli'ne gidin.", "store_exists", populated);
  }

  const store = await Store.create({
    name: storeName,
    description,
    logoUrl,
    owner: user._id,
  });

  await SellerProfile.findOneAndUpdate(
    { user: user._id },
    {
      user: user._id,
      storeName,
      storeDescription: description,
      storeLogo: logoUrl,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  user.role = "seller";
  user.isSeller = true;
  await user.save();

  const tokens = await issueTokens(user);
  const populatedStore = await store.populate(ownerSelect);

  await recordAudit("store.create", {
    userId: user._id,
    entityType: "store",
    entityId: store._id.toString(),
  });

  return sendOk(res, 201, {
    token: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    user: buildUserPayload(user),
    store: populatedStore,
  });
  } catch (err) {
    console.error("[applySeller]", err);
    return sendError(res, 500, "Mağaza oluşturulamadı", "internal_error");
  }
}

export async function addProduct(req, res) {
  try {
    if (!["seller", "admin"].includes(req.user.role)) {
      return sendError(res, 403, "Sadece saticilar urun ekleyebilir", "forbidden");
    }
    const { title, name, price, description, photos, images, stock, category, categoryId } = req.body || {};
    const productTitle = title || name;
    const productImages = Array.isArray(images) ? images : Array.isArray(photos) ? photos : [];
    const resolvedCategory = category ?? categoryId;

    if (!productTitle || price === undefined || price === null) {
      return sendError(res, 400, "Baslik ve fiyat gereklidir", "validation_error");
    }

    const store = await Store.findOne({ owner: req.user.sub });
    if (!store) {
      return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
    }

    const product = await Product.create({
      title: productTitle,
      name: productTitle,
      price: Number(price),
      description,
      photos: productImages,
      images: productImages,
      stock: typeof stock === "number" ? stock : Number(stock) || 0,
      category: resolvedCategory,
      store: store._id,
      seller: req.user.sub,
    });

    const populatedProduct = await product.populate(storePopulate);

    await recordAudit("product.create", {
      userId: req.user.sub,
      entityType: "product",
      entityId: product._id.toString(),
      metadata: { store: store._id.toString() },
    });

    return sendOk(res, 201, { product: populatedProduct });
  } catch (err) {
    console.error("[addProduct]", err);
    return sendError(res, 500, "Urun olusturulamadi", "internal_error", err.message);
  }
}
