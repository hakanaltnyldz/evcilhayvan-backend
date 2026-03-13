// scripts/reset-categories.js
// Kategorileri sıfırlayıp yeniden oluşturur
// Kullanım: node scripts/reset-categories.js

import mongoose from "mongoose";
import { config } from "../src/config/config.js";
import Category from "../src/models/Category.js";

const defaultCategories = [
  { name: "Kuru Mama", icon: "dry_food", color: "#FF6B6B" },
  { name: "Yas Mama", icon: "wet_food", color: "#4ECDC4" },
  { name: "Odul Mamasi", icon: "treat", color: "#45B7D1" },
  { name: "Vitamin & Takviye", icon: "vitamin", color: "#96CEB4" },
  { name: "Oyuncak", icon: "toy", color: "#FFEAA7" },
  { name: "Cignemeli Oyuncak", icon: "chew_toy", color: "#DDA0DD" },
  { name: "Interaktif Oyuncak", icon: "interactive", color: "#98D8C8" },
  { name: "Tasma & Kayis", icon: "leash", color: "#F7DC6F" },
  { name: "Kiyafet", icon: "clothing", color: "#BB8FCE" },
  { name: "Kolye & Kimlik", icon: "collar", color: "#85C1E9" },
  { name: "Yatak & Minder", icon: "bed", color: "#F8B500" },
  { name: "Kafes & Tasiyici", icon: "cage", color: "#00CEC9" },
  { name: "Mama & Su Kabi", icon: "bowl", color: "#E17055" },
  { name: "Kedi Kumu & Tuvaleti", icon: "litter", color: "#FDCB6E" },
  { name: "Sampuan & Bakim", icon: "shampoo", color: "#74B9FF" },
  { name: "Tarak & Firca", icon: "brush", color: "#A29BFE" },
  { name: "Tirnak Bakimi", icon: "nail", color: "#FD79A8" },
  { name: "Kulak & Goz Bakimi", icon: "ear_care", color: "#00B894" },
  { name: "Dis Bakimi", icon: "dental", color: "#E84393" },
  { name: "Pire & Kene", icon: "flea", color: "#6C5CE7" },
  { name: "Ilac & Saglik", icon: "medicine", color: "#FF7675" },
  { name: "Egitim Malzemeleri", icon: "training", color: "#55A3FF" },
  { name: "Akvaryum Malzemeleri", icon: "aquarium", color: "#00D2D3" },
  { name: "Kus Malzemeleri", icon: "bird", color: "#FF9FF3" },
  { name: "Kemirgen Malzemeleri", icon: "rodent", color: "#FECA57" },
];

function slugify(value) {
  const normalized = String(value || "")
    .trim()
    .toLowerCase()
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u");

  return normalized
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "") || "kategori";
}

async function resetCategories() {
  try {
    console.log("MongoDB'ye bağlanılıyor...");
    await mongoose.connect(config.mongoUri);
    console.log("Bağlandı!");

    // Mevcut kategorileri sil
    console.log("Mevcut kategoriler siliniyor...");
    await Category.deleteMany({});
    console.log("Silindi!");

    // Index'leri yeniden oluştur
    console.log("Index'ler yeniden oluşturuluyor...");
    await Category.syncIndexes();
    console.log("Index'ler oluşturuldu!");

    // Yeni kategorileri ekle
    console.log("Yeni kategoriler ekleniyor...");
    for (const cat of defaultCategories) {
      const slug = slugify(cat.name);
      await Category.create({
        name: cat.name,
        slug,
        icon: cat.icon,
        color: cat.color,
      });
      console.log(`  ✓ ${cat.name}`);
    }

    console.log("\n✅ Tamamlandı! " + defaultCategories.length + " kategori eklendi.");
  } catch (err) {
    console.error("Hata:", err.message);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

resetCategories();