import Category from "../models/Category.js";
import Product from "../models/Product.js";
import SellerProfile from "../models/SellerProfile.js";
import { sendError, sendOk } from "../utils/apiResponse.js";

const defaultCategories = [
  // Mama & Beslenme
  { name: "Kuru Mama", icon: "dry_food", color: "#FF6B6B" },
  { name: "Yas Mama", icon: "wet_food", color: "#4ECDC4" },
  { name: "Odul Mamasi", icon: "treat", color: "#45B7D1" },
  { name: "Vitamin Takviye", icon: "vitamin", color: "#96CEB4" },

  // Oyuncaklar
  { name: "Oyuncak", icon: "toy", color: "#FFEAA7" },
  { name: "Cignemeli Oyuncak", icon: "chew_toy", color: "#DDA0DD" },
  { name: "Interaktif Oyuncak", icon: "interactive", color: "#98D8C8" },

  // Aksesuar & Giyim
  { name: "Tasma Kayis", icon: "leash", color: "#F7DC6F" },
  { name: "Kiyafet", icon: "clothing", color: "#BB8FCE" },
  { name: "Kolye Kimlik", icon: "collar", color: "#85C1E9" },

  // Yasam Alani
  { name: "Yatak Minder", icon: "bed", color: "#F8B500" },
  { name: "Kafes Tasiyici", icon: "cage", color: "#00CEC9" },
  { name: "Mama Su Kabi", icon: "bowl", color: "#E17055" },
  { name: "Kedi Kumu", icon: "litter", color: "#FDCB6E" },

  // Bakim & Saglik
  { name: "Sampuan Bakim", icon: "shampoo", color: "#74B9FF" },
  { name: "Tarak Firca", icon: "brush", color: "#A29BFE" },
  { name: "Tirnak Bakimi", icon: "nail", color: "#FD79A8" },
  { name: "Kulak Goz Bakimi", icon: "ear_care", color: "#00B894" },
  { name: "Dis Bakimi", icon: "dental", color: "#E84393" },
  { name: "Pire Kene", icon: "flea", color: "#6C5CE7" },
  { name: "Ilac Saglik", icon: "medicine", color: "#FF7675" },

  // Egitim
  { name: "Egitim Malzemeleri", icon: "training", color: "#55A3FF" },

  // Diger
  { name: "Akvaryum", icon: "aquarium", color: "#00D2D3" },
  { name: "Kus Malzemeleri", icon: "bird", color: "#FF9FF3" },
  { name: "Kemirgen", icon: "rodent", color: "#FECA57" },
];

function slugify(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "") || "kategori";
}

// Server başlangıcında bir kez çalışacak
let categoriesInitialized = false;

async function initCategories() {
  if (categoriesInitialized) return;

  try {
    const count = await Category.countDocuments();
    if (count > 0) {
      console.log("[initCategories] Already have", count, "categories");
      categoriesInitialized = true;
      return;
    }

    console.log("[initCategories] Creating default categories...");
    for (const cat of defaultCategories) {
      const slug = slugify(cat.name);
      try {
        await Category.create({
          name: cat.name,
          slug,
          icon: cat.icon,
          color: cat.color,
        });
      } catch (err) {
        if (err.code !== 11000) {
          console.error(`[initCategories] Error creating ${cat.name}:`, err.message);
        }
      }
    }
    console.log("[initCategories] Categories created successfully");
    categoriesInitialized = true;
  } catch (err) {
    console.error("[initCategories] Error:", err.message);
  }
}

export async function getCategories(_req, res) {
  console.log("[getCategories] >>> Called");
  try {
    await initCategories();
    console.log("[getCategories] Init complete");
    const categories = await Category.find().sort({ name: 1 }).lean();
    console.log("[getCategories] Found", categories.length, "categories");
    return sendOk(res, 200, { categories });
  } catch (err) {
    console.error("[getCategories] !!! ERROR:", err);
    return sendError(res, 500, "Kategoriler alinamadi", "internal_error", err.message);
  }
}

export async function getStorefrontProducts(req, res) {
  try {
    const {
      category,
      q, search,
      sort = "newest",
      minPrice, maxPrice,
      page = 1, limit = 20,
    } = req.query;

    const filter = { isActive: true };
    if (category) filter.category = category;

    const term = q || search;
    if (term) filter.name = { $regex: term, $options: "i" };

    if (minPrice !== undefined || maxPrice !== undefined) {
      filter.price = {};
      if (minPrice !== undefined) filter.price.$gte = Number(minPrice);
      if (maxPrice !== undefined) filter.price.$lte = Number(maxPrice);
    }

    const sortMap = {
      newest:     { createdAt: -1 },
      oldest:     { createdAt:  1 },
      price_asc:  { price:      1 },
      price_desc: { price:     -1 },
      name_asc:   { name:       1 },
    };
    const sortObj = sortMap[sort] ?? sortMap.newest;

    const pageNum  = Math.max(1, parseInt(page,  10) || 1);
    const limitNum = Math.min(50, parseInt(limit, 10) || 20);
    const skip = (pageNum - 1) * limitNum;

    const [products, total] = await Promise.all([
      Product.find(filter)
        .populate("category", "name slug icon color")
        .populate("store", "name description logoUrl")
        .sort(sortObj)
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Product.countDocuments(filter),
    ]);

    return sendOk(res, 200, {
      products,
      total,
      page: pageNum,
      limit: limitNum,
      hasMore: skip + products.length < total,
    });
  } catch (err) {
    console.error("[getStorefrontProducts] Error:", err.message);
    return sendError(res, 500, "Urunler alinamadi", "internal_error", err.message);
  }
}

export async function getProductDetail(req, res) {
  try {
    const product = await Product.findById(req.params.id)
      .populate("category", "name slug icon color")
      .populate("store", "name description logoUrl")
      .lean();

    if (!product || !product.isActive) {
      return sendError(res, 404, "Urun bulunamadi", "product_not_found");
    }
    return sendOk(res, 200, { product });
  } catch (err) {
    console.error("[getProductDetail] Error:", err.message);
    return sendError(res, 500, "Urun alinamadi", "internal_error", err.message);
  }
}

export async function getSellerProfile(req, res) {
  try {
    const { userId } = req.params;
    const profile = await SellerProfile.findOne({ user: userId }).lean();
    if (!profile) {
      return sendError(res, 404, "Magaza bulunamadi", "store_not_found");
    }

    const products = await Product.find({ seller: userId, isActive: true })
      .populate("category", "name slug")
      .lean();

    return sendOk(res, 200, { profile, products });
  } catch (err) {
    console.error("[getSellerProfile] Error:", err.message);
    return sendError(res, 500, "Magaza bilgisi alinamadi", "internal_error", err.message);
  }
}
