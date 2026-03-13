// scripts/fix-favorites-itemmodel.js
// Migration script to add itemModel field to existing favorites

import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/evcilhayvan';

const itemTypeToModel = {
  pet: 'Pet',
  product: 'Product',
  store: 'Store',
};

async function fixFavoritesItemModel() {
  console.log('🔧 Favoriler için itemModel düzeltme scripti başlatılıyor...\n');

  try {
    // MongoDB'ye bağlan
    await mongoose.connect(MONGODB_URI);
    console.log('✅ MongoDB bağlantısı başarılı\n');

    const db = mongoose.connection.db;
    const favoritesCollection = db.collection('favorites');

    // itemModel alanı olmayan tüm favori kayıtlarını bul
    const favoritesWithoutItemModel = await favoritesCollection.find({
      $or: [
        { itemModel: { $exists: false } },
        { itemModel: null },
        { itemModel: '' }
      ]
    }).toArray();

    console.log(`📊 itemModel alanı eksik olan ${favoritesWithoutItemModel.length} favori bulundu\n`);

    if (favoritesWithoutItemModel.length === 0) {
      console.log('✨ Tüm favoriler zaten güncel, düzeltme gerekmiyor!');
      return;
    }

    let updated = 0;
    let errors = 0;

    for (const favorite of favoritesWithoutItemModel) {
      const itemModel = itemTypeToModel[favorite.itemType];

      if (!itemModel) {
        console.log(`⚠️  Geçersiz itemType: ${favorite.itemType} (ID: ${favorite._id})`);
        errors++;
        continue;
      }

      try {
        await favoritesCollection.updateOne(
          { _id: favorite._id },
          { $set: { itemModel: itemModel } }
        );
        updated++;
        console.log(`✅ Güncellendi: ${favorite._id} (${favorite.itemType} -> ${itemModel})`);
      } catch (err) {
        console.log(`❌ Hata: ${favorite._id} - ${err.message}`);
        errors++;
      }
    }

    console.log('\n📋 Özet:');
    console.log(`   ✅ Güncellenen: ${updated}`);
    console.log(`   ❌ Hatalı: ${errors}`);
    console.log(`   📊 Toplam: ${favoritesWithoutItemModel.length}`);

  } catch (error) {
    console.error('❌ Migration hatası:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 MongoDB bağlantısı kapatıldı');
  }
}

// Scripti çalıştır
fixFavoritesItemModel();
