// Fix Conversation Index Script
// Bu script yanlış participants index'ini siler ve düzeltin

import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function fixConversationIndex() {
  try {
    // MongoDB'ye bağlan
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/evcilhayvan');
    console.log('✅ MongoDB bağlantısı başarılı');

    // Conversation collection'ını al
    const db = mongoose.connection.db;
    const conversationsCollection = db.collection('conversations');

    // Mevcut index'leri listele
    console.log('\n📋 Mevcut index\'ler:');
    const indexes = await conversationsCollection.indexes();
    indexes.forEach((index) => {
      console.log(`   - ${index.name}:`, JSON.stringify(index.key));
    });

    // Yanlış participants_1 index'ini sil
    try {
      console.log('\n🗑️  participants_1 index\'i siliniyor...');
      await conversationsCollection.dropIndex('participants_1');
      console.log('✅ participants_1 index\'i silindi!');
    } catch (err) {
      if (err.message.includes('index not found')) {
        console.log('ℹ️  participants_1 index zaten yok.');
      } else {
        throw err;
      }
    }

    // Güncellenmiş index listesini göster
    console.log('\n📋 Güncellenmiş index\'ler:');
    const newIndexes = await conversationsCollection.indexes();
    newIndexes.forEach((index) => {
      console.log(`   - ${index.name}:`, JSON.stringify(index.key));
    });

    console.log('\n✅ Index düzeltme işlemi tamamlandı!');
    console.log('ℹ️  Artık conversation oluşturma çalışacak.');

    process.exit(0);
  } catch (error) {
    console.error('❌ Hata:', error);
    process.exit(1);
  }
}

fixConversationIndex();
