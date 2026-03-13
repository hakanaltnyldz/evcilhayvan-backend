import Product from "../models/Product.js";
import Store from "../models/Store.js";
import Category from "../models/Category.js";
import { sendError, sendOk } from "../utils/apiResponse.js";
import { recordAudit } from "../utils/audit.js";

export async function createSellerProduct(req, res) {
  try {
    const sellerId = req.user?.sub;
    if (!sellerId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");

    const { name, description, price, stock, images, category, isActive } = req.body || {};
    if (!name || price === undefined || price === null) {
      return sendError(res, 400, "Isim ve fiyat zorunludur", "validation_error");
    }

    // Satıcının mağazasını bul
    const store = await Store.findOne({ owner: sellerId });
    if (!store) {
      return sendError(res, 400, "Önce mağaza oluşturmalısınız", "store_required");
    }

    const product = await Product.create({
      name,
      title: name,
      description,
      price: Number(price),
      stock: typeof stock === "number" ? stock : Number(stock) || 0,
      images: Array.isArray(images) ? images : [],
      photos: Array.isArray(images) ? images : [],
      category,
      isActive: typeof isActive === "boolean" ? isActive : true,
      seller: sellerId,
      store: store._id,
    });

    await recordAudit("product.create", {
      userId: sellerId,
      entityType: "product",
      entityId: product._id.toString(),
    });

    return sendOk(res, 201, { product });
  } catch (err) {
    console.error("[createSellerProduct] error", err);
    return sendError(res, 500, "Urun olusturulamadi", "internal_error", err.message);
  }
}

export async function getSellerProducts(req, res) {
  try {
    const sellerId = req.user?.sub;
    const products = await Product.find({ seller: sellerId });
    return sendOk(res, 200, { products });
  } catch (err) {
    console.error("[getSellerProducts] error", err);
    return sendError(res, 500, "Urunler getirilemedi", "internal_error", err.message);
  }
}

export async function updateSellerProduct(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;
    const updates = { ...req.body };

    if (updates.name && !updates.title) updates.title = updates.name;
    if (updates.images && !updates.photos) updates.photos = updates.images;

    const product = await Product.findOneAndUpdate({ _id: id, seller: sellerId }, updates, { new: true });
    if (!product) return sendError(res, 404, "Urun bulunamadi", "product_not_found");

    await recordAudit("product.update", {
      userId: sellerId,
      entityType: "product",
      entityId: id,
    });

    return sendOk(res, 200, { product });
  } catch (err) {
    console.error("[updateSellerProduct] error", err);
    return sendError(res, 500, "Urun guncellenemedi", "internal_error", err.message);
  }
}

export async function deleteSellerProduct(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;
    const product = await Product.findOneAndDelete({ _id: id, seller: sellerId });
    if (!product) return sendError(res, 404, "Urun bulunamadi", "product_not_found");

    await recordAudit("product.delete", {
      userId: sellerId,
      entityType: "product",
      entityId: id,
    });

    return sendOk(res, 200, { message: "Silindi" });
  } catch (err) {
    console.error("[deleteSellerProduct] error", err);
    return sendError(res, 500, "Urun silinemedi", "internal_error", err.message);
  }
}

// Fotoğraflı ürün oluşturma (multipart/form-data)
export async function createSellerProductWithImages(req, res) {
  try {
    const sellerId = req.user?.sub;
    if (!sellerId) return sendError(res, 401, "Kimlik dogrulama gerekli", "auth_required");

    const { name, description, price, stock, category, isActive } = req.body || {};
    if (!name || price === undefined || price === null) {
      return sendError(res, 400, "Isim ve fiyat zorunludur", "validation_error");
    }

    // Satıcının mağazasını bul
    const store = await Store.findOne({ owner: sellerId });
    if (!store) {
      return sendError(res, 400, "Önce mağaza oluşturmalısınız", "store_required");
    }

    // Yüklenen dosyaların path'lerini al
    const imagePaths = req.files ? req.files.map((file) => `/uploads/products/${file.filename}`) : [];

    console.log("[createSellerProductWithImages] Creating product:", { name, price, store: store._id, seller: sellerId });

    const product = await Product.create({
      name,
      title: name,
      description,
      price: Number(price),
      stock: typeof stock === "number" ? stock : Number(stock) || 0,
      images: imagePaths,
      photos: imagePaths,
      category: category || null,
      isActive: isActive === "true" || isActive === true || isActive === undefined,
      seller: sellerId,
      store: store._id,
    });

    console.log("[createSellerProductWithImages] Product created:", product._id);

    await recordAudit("product.create", {
      userId: sellerId,
      entityType: "product",
      entityId: product._id.toString(),
    });

    // Populate category and store for response
    await product.populate("category", "name slug icon color");
    await product.populate("store", "name description logoUrl");

    return sendOk(res, 201, { product });
  } catch (err) {
    console.error("[createSellerProductWithImages] error", err);
    return sendError(res, 500, "Urun olusturulamadi", "internal_error", err.message);
  }
}

// Mevcut ürüne fotoğraf ekleme
export async function uploadProductImages(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;

    const product = await Product.findOne({ _id: id, seller: sellerId });
    if (!product) return sendError(res, 404, "Urun bulunamadi", "product_not_found");

    // Yüklenen dosyaların path'lerini al
    const newImagePaths = req.files ? req.files.map((file) => `/uploads/products/${file.filename}`) : [];

    // Mevcut resimlere ekle
    product.images = [...(product.images || []), ...newImagePaths];
    product.photos = product.images;
    await product.save();

    await recordAudit("product.images_upload", {
      userId: sellerId,
      entityType: "product",
      entityId: id,
      metadata: { newImages: newImagePaths.length },
    });

    return sendOk(res, 200, { product, newImages: newImagePaths });
  } catch (err) {
    console.error("[uploadProductImages] error", err);
    return sendError(res, 500, "Resimler yuklenemedi", "internal_error", err.message);
  }
}

// Stok güncelleme
export async function updateStock(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;
    const { stock, action } = req.body;

    const product = await Product.findOne({ _id: id, seller: sellerId });
    if (!product) return sendError(res, 404, "Urun bulunamadi", "product_not_found");

    let newStock = product.stock;
    if (action === "increase") {
      newStock += Number(stock) || 0;
    } else if (action === "decrease") {
      newStock = Math.max(0, newStock - (Number(stock) || 0));
    } else {
      newStock = Number(stock) || 0;
    }

    product.stock = newStock;
    await product.save();

    await recordAudit("product.stock_update", {
      userId: sellerId,
      entityType: "product",
      entityId: id,
      metadata: { oldStock: product.stock, newStock, action },
    });

    return sendOk(res, 200, { product, stock: newStock });
  } catch (err) {
    console.error("[updateStock] error", err);
    return sendError(res, 500, "Stok guncellenemedi", "internal_error", err.message);
  }
}

// Ürün aktif/pasif toggle
export async function toggleProductActive(req, res) {
  try {
    const sellerId = req.user?.sub;
    const { id } = req.params;

    const product = await Product.findOne({ _id: id, seller: sellerId });
    if (!product) return sendError(res, 404, "Urun bulunamadi", "product_not_found");

    product.isActive = !product.isActive;
    await product.save();

    await recordAudit("product.toggle_active", {
      userId: sellerId,
      entityType: "product",
      entityId: id,
      metadata: { isActive: product.isActive },
    });

    return sendOk(res, 200, { product, isActive: product.isActive });
  } catch (err) {
    console.error("[toggleProductActive] error", err);
    return sendError(res, 500, "Durum guncellenemedi", "internal_error", err.message);
  }
}

// Seller istatistikleri
export async function getSellerStats(req, res) {
  try {
    const sellerId = req.user?.sub;

    const products = await Product.find({ seller: sellerId });
    const totalProducts = products.length;
    const activeProducts = products.filter(p => p.isActive).length;
    const outOfStock = products.filter(p => p.stock <= 0).length;
    const lowStock = products.filter(p => p.stock > 0 && p.stock <= 5).length;
    const totalStock = products.reduce((sum, p) => sum + (p.stock || 0), 0);
    const totalValue = products.reduce((sum, p) => sum + ((p.price || 0) * (p.stock || 0)), 0);

    return sendOk(res, 200, {
      stats: {
        totalProducts,
        activeProducts,
        inactiveProducts: totalProducts - activeProducts,
        outOfStock,
        lowStock,
        totalStock,
        totalValue: Math.round(totalValue * 100) / 100,
      },
    });
  } catch (err) {
    console.error("[getSellerStats] error", err);
    return sendError(res, 500, "Istatistikler alinamadi", "internal_error", err.message);
  }
}

// Demo mağaza ürünleri oluşturma
export async function seedDemoProducts(req, res) {
  try {
    const sellerId = req.user?.sub;
    if (!sellerId) return sendError(res, 401, "Kimlik doğrulama gerekli", "auth_required");

    console.log("[seedDemoProducts] Starting seed for seller:", sellerId);

    // Satıcının mağazasını bul
    const store = await Store.findOne({ owner: sellerId });
    if (!store) {
      return sendError(res, 400, "Önce mağaza oluşturmalısınız", "store_required");
    }

    // Mevcut ürünleri kontrol et
    const existingProducts = await Product.countDocuments({ store: store._id });
    if (existingProducts > 0) {
      console.log(`[seedDemoProducts] Deleting ${existingProducts} existing products`);
      await Product.deleteMany({ store: store._id });
    }

    // Demo kategori ve ürün verileri
    const categoryProductMap = {
      'Köpek Maması': [
        { name: 'Royal Canin Köpek Maması Yetişkin 15kg', price: 1899, stock: 50, description: 'Yetişkin köpekler için dengeli beslenme. Kaliteli protein kaynakları içerir.' },
        { name: 'Pro Plan Küçük Irk Köpek Maması 7kg', price: 899, stock: 35, description: 'Küçük ırklar için özel formül. Yüksek protein ve enerji içeriği.' },
        { name: 'Pedigree Yavru Köpek Maması 3kg', price: 299, stock: 60, description: 'Yavru köpeklerin büyüme döneminde ihtiyaç duyduğu tüm besinler.' }
      ],
      'Kedi Maması': [
        { name: 'Whiskas Yetişkin Kedi Maması 5kg', price: 459, stock: 45, description: 'Dengeli beslenme için tam ve eksiksiz mama. Balık aromalı.' },
        { name: 'Pro Plan Sterilised Kedi Maması 3kg', price: 599, stock: 40, description: 'Kısırlaştırılmış kediler için özel formül. Kilo kontrolü sağlar.' },
        { name: 'Royal Canin Persian Kedi Maması 4kg', price: 899, stock: 30, description: 'İran kedileri için özel tüy sağlığı formülü.' }
      ],
      'Köpek Oyuncağı': [
        { name: 'Kong Classic Köpek Oyuncağı Kırmızı L', price: 199, stock: 45, description: 'Dayanıklı kauçuk oyuncak. İçine ödül koyulabilir.' },
        { name: 'Peluş Köpek Oyuncağı Sesli 30cm', price: 89, stock: 60, description: 'Yumuşak peluş oyuncak, içinde ses çıkaran mekanizma.' },
        { name: 'İp Top Köpek Oyuncağı Diş Temizleyici', price: 59, stock: 80, description: 'Doğal pamuk ip, oynarken diş temizliği yapar.' }
      ],
      'Kedi Oyuncağı': [
        { name: 'Tüylü Kedi Oltası Oyuncak Seti', price: 49, stock: 70, description: '5 farklı uçlu kedi oltası. Kedilerin avlanma içgüdüsünü harekete geçirir.' },
        { name: 'Lazer Pointer Kedi Oyuncağı', price: 69, stock: 55, description: 'USB şarjlı lazer oyuncak. 5 farklı desen modu.' },
        { name: 'Kedi Tüneli Katlanabilir 120cm', price: 159, stock: 35, description: 'Katlanabilir oyun tüneli, saklanma ve oyun için ideal.' }
      ],
      'Köpek Tasması': [
        { name: 'Deri Köpek Tasması Büyük Irk', price: 149, stock: 40, description: 'Gerçek deri tasma, ayarlanabilir, büyük ırklar için.' },
        { name: 'Şık Desenli Köpek Boyun Tasması M', price: 89, stock: 60, description: 'Dayanıklı naylon, modern desenler, orta boy köpekler için.' },
        { name: 'LED Işıklı Köpek Tasması USB Şarjlı', price: 129, stock: 35, description: 'Gece yürüyüşleri için USB şarjlı LED tasma.' }
      ],
      'Kedi Tasması': [
        { name: 'Güvenlik Kilitli Kedi Tasması', price: 49, stock: 70, description: 'Acil durumlarda açılan güvenlik kilidi ile. Zil dahil.' },
        { name: 'Nakışlı Kedi Tasması İsimlik Hediyeli', price: 79, stock: 45, description: 'Ücretsiz isim nakışı, dayanıklı kumaş.' }
      ],
      'Mama Kabı': [
        { name: 'Çelik Kedi Mama Kabı İkili Set', price: 79, stock: 60, description: 'Paslanmaz çelik, bulaşık makinesinde yıkanabilir. 200ml x2' },
        { name: 'Köpek Mama Kabı Ayarlanabilir Yükseklik', price: 249, stock: 30, description: 'Yükseklik ayarlı stand, boyun sağlığı için. 2 litre kapasiteli.' },
        { name: 'Otomatik Su Kabı Pet Fountain 2L', price: 349, stock: 25, description: 'Elektrikli su çeşmesi, filtreli. Kediler ve küçük köpekler için.' }
      ],
      'Tımar Ürünleri': [
        { name: 'Pet Şampuan Hassas Cilt 500ml', price: 89, stock: 50, description: 'pH dengeli, hipoalerjenik. Tüm evcil hayvanlar için.' },
        { name: 'Tüy Tarağı Çift Taraflı', price: 69, stock: 60, description: 'Çift taraflı tarak, seyrek ve sık diş. Ergonomik tutacak.' },
        { name: 'Tırnak Makası Köpek ve Kedi', price: 79, stock: 45, description: 'Paslanmaz çelik, güvenlik kilidi, limiter dahil.' }
      ]
    };

    const productImages = [
      'https://via.placeholder.com/400x400?text=Urun+1',
      'https://via.placeholder.com/400x400?text=Urun+2',
      'https://via.placeholder.com/400x400?text=Urun+3',
    ];

    let totalProducts = 0;
    const createdCategories = [];

    // Kategorileri oluştur ve ürünleri ekle
    for (const [categoryName, products] of Object.entries(categoryProductMap)) {
      // Kategoriyi bul veya oluştur
      let category = await Category.findOne({ name: categoryName });
      if (!category) {
        category = new Category({
          name: categoryName,
          slug: categoryName.toLowerCase()
            .replace(/ı/g, 'i')
            .replace(/ğ/g, 'g')
            .replace(/ü/g, 'u')
            .replace(/ş/g, 's')
            .replace(/ö/g, 'o')
            .replace(/ç/g, 'c')
            .replace(/\s+/g, '-'),
          description: `${categoryName} kategorisi altındaki tüm ürünler`
        });
        await category.save();
        console.log(`[seedDemoProducts] Created category: ${categoryName}`);
      }

      createdCategories.push(categoryName);

      // Ürünleri ekle
      for (const productData of products) {
        const product = new Product({
          name: productData.name,
          title: productData.name, // Duplicate for legacy support
          description: productData.description,
          price: productData.price,
          category: category._id,
          store: store._id,
          seller: sellerId,
          stock: productData.stock,
          images: productImages,
          photos: productImages, // Duplicate for legacy support
          isActive: true,
          averageRating: parseFloat((Math.random() * 1.5 + 3.5).toFixed(1)), // 3.5-5.0 arası rating
          reviewCount: Math.floor(Math.random() * 50)
        });

        await product.save();
        totalProducts++;
      }

      console.log(`[seedDemoProducts] Added ${products.length} products to ${categoryName}`);
    }

    await recordAudit("store.seed_demo_products", {
      userId: sellerId,
      entityType: "store",
      entityId: store._id.toString(),
      metadata: {
        categoriesCreated: createdCategories.length,
        productsCreated: totalProducts
      },
    });

    console.log(`[seedDemoProducts] Successfully seeded ${totalProducts} products`);

    return sendOk(res, 200, {
      message: "Demo ürünler başarıyla oluşturuldu",
      stats: {
        categoriesCreated: createdCategories.length,
        productsCreated: totalProducts,
        store: {
          id: store._id,
          name: store.name
        }
      }
    });
  } catch (err) {
    console.error("[seedDemoProducts] error", err);
    return sendError(res, 500, "Demo ürünler oluşturulamadı", "internal_error", err.message);
  }
}
