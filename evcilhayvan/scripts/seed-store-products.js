// scripts/seed-store-products.js
// Demo mağaza ürünleri seed scripti
// Kullanım: node scripts/seed-store-products.js --email=hakanaltunyaldiz1248@gmail.com

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../src/models/User.js';
import Store from '../src/models/Store.js';
import Product from '../src/models/Product.js';
import Category from '../src/models/Category.js';

dotenv.config();

// Kategori ve ürün verileri
const categoryProductMap = {
  'Köpek Maması': [
    { name: 'Royal Canin Köpek Maması Yetişkin 15kg', price: 1899, stock: 50, description: 'Yetişkin köpekler için dengeli beslenme. Kaliteli protein kaynakları içerir.' },
    { name: 'Pro Plan Küçük Irk Köpek Maması 7kg', price: 899, stock: 35, description: 'Küçük ırklar için özel formül. Yüksek protein ve enerji içeriği.' },
    { name: 'Pedigree Yavru Köpek Maması 3kg', price: 299, stock: 60, description: 'Yavru köpeklerin büyüme döneminde ihtiyaç duyduğu tüm besinler.' },
    { name: 'Hills Science Diet Hassas Mide 12kg', price: 1599, stock: 25, description: 'Hassas mideye sahip köpekler için prebiyotik lifler içerir.' }
  ],
  'Kedi Maması': [
    { name: 'Whiskas Yetişkin Kedi Maması 5kg', price: 459, stock: 45, description: 'Dengeli beslenme için tam ve eksiksiz mama. Balık aromalı.' },
    { name: 'Pro Plan Sterilised Kedi Maması 3kg', price: 599, stock: 40, description: 'Kısırlaştırılmış kediler için özel formül. Kilo kontrolü sağlar.' },
    { name: 'Royal Canin Persian Kedi Maması 4kg', price: 899, stock: 30, description: 'İran kedileri için özel tüy sağlığı formülü.' },
    { name: 'Purina One Yavru Kedi Maması 1.5kg', price: 249, stock: 50, description: 'Yavru kedilerin gelişimi için DHA içerir.' }
  ],
  'Kuş Yemi': [
    { name: 'Versele-Laga Muhabbet Kuşu Yemi 1kg', price: 89, stock: 80, description: 'Muhabbet kuşları için özel karışım. Doğal tahıllar içerir.' },
    { name: 'Vitakraft Kanarya Yemi 500g', price: 65, stock: 70, description: 'Kanarya kuşlarının tüy sağlığı için özel karışım.' },
    { name: 'Benek Premium Cennet Papağanı Yemi 15kg', price: 899, stock: 20, description: 'Büyük papağanlar için zengin içerik. Meyve ve sebze karışımlı.' }
  ],
  'Kemirgen Yemi': [
    { name: 'Versele-Laga Hamster Yemi 2kg', price: 149, stock: 40, description: 'Hamsterlar için dengeli beslenme karışımı.' },
    { name: 'Tavşan Premium Yem Karışımı 5kg', price: 299, stock: 35, description: 'Tavşanlar için vitamin ve mineral açısından zengin yem.' },
    { name: 'Guinea Pig Pellet Yem 3kg', price: 189, stock: 30, description: 'Kobaylar için C vitamini takviyeli pellet yem.' }
  ],
  'Köpek Oyuncağı': [
    { name: 'Kong Classic Köpek Oyuncağı Kırmızı L', price: 199, stock: 45, description: 'Dayanıklı kauçuk oyuncak. İçine ödül koyulabilir.' },
    { name: 'Peluş Köpek Oyuncağı Sesli 30cm', price: 89, stock: 60, description: 'Yumuşak peluş oyuncak, içinde ses çıkaran mekanizma.' },
    { name: 'İp Top Köpek Oyuncağı Diş Temizleyici', price: 59, stock: 80, description: 'Doğal pamuk ip, oynarken diş temizliği yapar.' },
    { name: 'Frisbee Köpek Oyuncağı Silikon', price: 79, stock: 50, description: 'Esnek silikon malzeme, diş dostudur.' }
  ],
  'Kedi Oyuncağı': [
    { name: 'Tüylü Kedi Oltası Oyuncak Seti', price: 49, stock: 70, description: '5 farklı uçlu kedi oltası. Kedilerin avlanma içgüdüsünü harekete geçirir.' },
    { name: 'Lazer Pointer Kedi Oyuncağı', price: 69, stock: 55, description: 'USB şarjlı lazer oyuncak. 5 farklı desen modu.' },
    { name: 'Kedi Tüneli Katlanabilir 120cm', price: 159, stock: 35, description: 'Katlanabilir oyun tüneli, saklanma ve oyun için ideal.' },
    { name: 'Catnip Kedi Yastığı 3lü Set', price: 79, stock: 60, description: 'Catnip otlu yastıklar, kedileri rahatlatır ve eğlendirir.' }
  ],
  'Köpek Tasması': [
    { name: 'Deri Köpek Tasması Büyük Irk', price: 149, stock: 40, description: 'Gerçek deri tasma, ayarlanabilir, büyük ırklar için.' },
    { name: 'Şık Desenli Köpek Boyun Tasması M', price: 89, stock: 60, description: 'Dayanıklı naylon, modern desenler, orta boy köpekler için.' },
    { name: 'LED Işıklı Köpek Tasması USB Şarjlı', price: 129, stock: 35, description: 'Gece yürüyüşleri için USB şarjlı LED tasma.' },
    { name: 'Yumuşak Yavru Köpek Tasması S', price: 59, stock: 50, description: 'Yumuşak dokulu, yavru köpekler için hafif tasma.' }
  ],
  'Kedi Tasması': [
    { name: 'Güvenlik Kilitli Kedi Tasması', price: 49, stock: 70, description: 'Acil durumlarda açılan güvenlik kilidi ile. Zil dahil.' },
    { name: 'Nakışlı Kedi Tasması İsimlik Hediyeli', price: 79, stock: 45, description: 'Ücretsiz isim nakışı, dayanıklı kumaş.' },
    { name: 'Deri Kedi Tasması Çan Detaylı', price: 69, stock: 55, description: 'İnce deri tasma, paslanmaz çelik çan ve toka.' }
  ],
  'Köpek Kıyafeti': [
    { name: 'Kış Montu Köpek Kıyafeti Su Geçirmez', price: 189, stock: 30, description: 'Su geçirmez dış yüzey, polar astarı. Küçük ve orta ırklar için.' },
    { name: 'Yağmurluk Köpek Kıyafeti Şeffaf', price: 99, stock: 40, description: 'Şeffaf PVC malzeme, yağmurlu havalarda koruma sağlar.' },
    { name: 'Pamuklu Tişört Köpek Kıyafeti', price: 59, stock: 60, description: '%100 pamuk, rahat kesim. Çeşitli baskılar.' }
  ],
  'Kedi Yatağı': [
    { name: 'Peluş Kedi Yatağı Yuvarlak 50cm', price: 189, stock: 35, description: 'Yumuşak peluş kumaş, makinede yıkanabilir.' },
    { name: 'İglo Kedi Evi Gri', price: 249, stock: 25, description: 'Sıcak ve konforlu iglo tasarım, katlanabilir.' },
    { name: 'Kedi Hamağı Kalorifer Askılı', price: 149, stock: 30, description: 'Kaloriferye asılabilir hamak, kışın sıcak tutar.' }
  ],
  'Köpek Yatağı': [
    { name: 'Ortopedik Köpek Yatağı Büyük Boy', price: 599, stock: 20, description: 'Memory foam, yaşlı köpekler için ideal. 90x70cm' },
    { name: 'Su Geçirmez Köpek Minderi Orta Boy', price: 299, stock: 35, description: 'Su geçirmez alt yüzey, çıkarılabilir kılıf. 70x50cm' },
    { name: 'Peluş Köpek Yatağı Küçük Irk', price: 189, stock: 45, description: 'Yumuşak ve rahat, küçük ırklar için. 50x40cm' }
  ],
  'Mama Kabı': [
    { name: 'Çelik Kedi Mama Kabı İkili Set', price: 79, stock: 60, description: 'Paslanmaz çelik, bulaşık makinesinde yıkanabilir. 200ml x2' },
    { name: 'Köpek Mama Kabı Ayarlanabilir Yükseklik', price: 249, stock: 30, description: 'Yükseklik ayarlı stand, boyun sağlığı için. 2 litre kapasiteli.' },
    { name: 'Otomatik Su Kabı Pet Fountain 2L', price: 349, stock: 25, description: 'Elektrikli su çeşmesi, filtreli. Kediler ve küçük köpekler için.' },
    { name: 'Seramik Köpek Mama Kabı 1.5L', price: 129, stock: 40, description: 'Ağır seramik, kaymaz taban.' }
  ],
  'Tırmalama Tahtası': [
    { name: 'Dikey Tırmalama Tahtası 60cm', price: 189, stock: 35, description: 'Sisal malzeme, sağlam taban. Üstte peluş yatak.' },
    { name: 'Kedi Tırmalama Ağacı 120cm', price: 599, stock: 15, description: '3 katlı, 2 yatakli, tünelli kedi ağacı.' },
    { name: 'Köşe Tırmalama Pedi Askılı', price: 89, stock: 50, description: 'Duvara monte edilebilir, sisal halat kaplı.' }
  ],
  'Tuvalet Kabı': [
    { name: 'Kapalı Kedi Tuvaleti Büyük Boy', price: 249, stock: 30, description: 'Kapaklı tasarım, koku filtresi dahil. 50x40x40cm' },
    { name: 'Açık Kedi Tuvaleti Kürek Hediyeli', price: 129, stock: 45, description: 'Yüksek kenarlı, kürek ve filtre hediyeli.' },
    { name: 'Otomatik Kedi Tuvaleti Kendini Temizler', price: 2499, stock: 8, description: 'Sensörlü otomatik temizlik, uygulama bağlantısı.' }
  ],
  'Taşıma Çantası': [
    { name: 'Kedi Taşıma Çantası Sert 45cm', price: 299, stock: 25, description: 'Sert plastik, havalandırmalı, üst açılır kapak.' },
    { name: 'Köpek Taşıma Sırt Çantası 5kg', price: 349, stock: 20, description: 'Küçük köpekler için sırt çantası, havalandırma delikleri.' },
    { name: 'Katlanabilir Pet Taşıma Kutusu', price: 189, stock: 35, description: 'Katlanabilir, hafif. Kedi ve küçük köpekler için.' }
  ],
  'Tımar Ürünleri': [
    { name: 'Pet Şampuan Hassas Cilt 500ml', price: 89, stock: 50, description: 'pH dengeli, hipoalerjenik. Tüm evcil hayvanlar için.' },
    { name: 'Tüy Tarağı Çift Taraflı', price: 69, stock: 60, description: 'Çift taraflı tarak, seyrek ve sık diş. Ergonomik tutacak.' },
    { name: 'Tırnak Makası Köpek ve Kedi', price: 79, stock: 45, description: 'Paslanmaz çelik, güvenlik kilidi, limiter dahil.' },
    { name: 'Diş Fırçası Set Kedi Köpek', price: 59, stock: 40, description: '3 boyut fırça ve diş macunu. Tavuk aromalı.' }
  ],
  'Akuaryum': [
    { name: 'Cam Akuaryum 50 Litre', price: 599, stock: 15, description: '50x30x35cm, filtre ve led ışık dahil.' },
    { name: 'Nano Akuaryum 20 Litre Komple Set', price: 899, stock: 10, description: 'Başlangıç seti, filtre, ışık, ısıtıcı, dekorasyon dahil.' }
  ],
  'Balık Yemi': [
    { name: 'Tetra Min Pul Balık Yemi 250ml', price: 89, stock: 50, description: 'Tropikal balıklar için dengeli beslenme.' },
    { name: 'Sera Vipan Balık Yemi 1L', price: 249, stock: 30, description: 'Tüm süs balıkları için tam yem karışımı.' },
    { name: 'JBL Artemia Balık Yavrusu Yemi', price: 129, stock: 25, description: 'Yavru balıklar için protein yoğun yem.' }
  ],
  'Kuş Kafesi': [
    { name: 'Muhabbet Kuşu Kafesi 40x40x60cm', price: 399, stock: 20, description: 'Tünekler ve yemlikler dahil, çelik konstrüksiyon.' },
    { name: 'Kanarya Kafesi Dikdörtgen 50x30x40cm', price: 299, stock: 25, description: 'Klasik tasarım, çıkarılabilir tepsi.' },
    { name: 'Papağan Kafesi Büyük 80x60x150cm', price: 2499, stock: 5, description: 'Büyük papağanlar için, oyun alanı dahil.' }
  ],
  'Kemirgen Kafesi': [
    { name: 'Hamster Kafesi 2 Katlı', price: 349, stock: 20, description: 'Plastik tüpler ve tekerlek dahil. 40x30x40cm' },
    { name: 'Tavşan Kafesi Ahşap 100cm', price: 1299, stock: 8, description: 'Açık hava kullanımına uygun, 2 bölmeli.' }
  ],
  'Sağlık Ürünleri': [
    { name: 'Pire Tasması Kedi Köpek', price: 149, stock: 40, description: '8 ay koruma sağlar, su geçirmez.' },
    { name: 'Damla Pire İlacı Köpek 10-25kg', price: 189, stock: 30, description: '1 aylık koruma, hızlı etki.' },
    { name: 'Multivitamin Köpek 100 Tablet', price: 129, stock: 35, description: 'Bağışıklık sistemi desteği, tüy sağlığı.' },
    { name: 'Probiyotik Kedi Tozu 50g', price: 99, stock: 40, description: 'Sindirim sistemi sağlığı, prebiyotik ve probiyotik.' }
  ],
  'Eğitim Malzemeleri': [
    { name: 'Köpek Eğitim Düdüğü Ultrasonik', price: 59, stock: 50, description: 'Ayarlanabilir frekans, ipli.' },
    { name: 'Clicker Eğitim Seti 2li', price: 49, stock: 60, description: 'Pozitif pekiştirme eğitimi için clicker ve rehber kitapçık.' },
    { name: 'Köpek Eğitim Pedi 100 Adet', price: 249, stock: 25, description: 'Tuvalet eğitimi için emici pedler. 60x60cm' }
  ]
};

async function seedStoreProducts(userEmail) {
  try {
    console.log('🌱 Demo mağaza ürünleri oluşturuluyor...\n');

    // MongoDB bağlantısı
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/evcilhayvan');
    console.log('✅ MongoDB bağlantısı başarılı\n');

    // Kullanıcıyı bul veya oluştur
    let user = await User.findOne({ email: userEmail });

    if (!user) {
      console.log('❌ Kullanıcı bulunamadı:', userEmail);
      console.log('💡 Önce kayıt olun veya mevcut bir email kullanın.');
      process.exit(1);
    }

    console.log('✅ Kullanıcı bulundu:', user.name, `(${user.email})`);

    // Kullanıcı satıcı değilse satıcı yap
    if (user.role !== 'seller') {
      user.role = 'seller';
      await user.save();
      console.log('✅ Kullanıcı satıcı olarak ayarlandı\n');
    }

    // Mağaza bul veya oluştur
    let store = await Store.findOne({ ownerId: user._id });

    if (!store) {
      store = new Store({
        name: `${user.name}'ın Pet Shop`,
        ownerId: user._id,
        description: 'Evcil hayvanlarınız için her şey! Kaliteli mama, oyuncak, aksesuar ve daha fazlası.',
        contactEmail: user.email,
        contactPhone: '0555 123 4567',
        address: 'İstanbul, Türkiye',
        status: 'active',
        logo: 'https://via.placeholder.com/200x200?text=Pet+Shop',
        rating: 4.8,
        totalReviews: 0
      });
      await store.save();
      console.log('✅ Yeni mağaza oluşturuldu:', store.name, '\n');
    } else {
      console.log('✅ Mağaza bulundu:', store.name, '\n');
    }

    // Mevcut ürünleri temizle (isteğe bağlı)
    const existingProducts = await Product.countDocuments({ storeId: store._id });
    if (existingProducts > 0) {
      console.log(`⚠️  Mağazada ${existingProducts} adet ürün var.`);
      console.log('🗑️  Eski ürünler siliniyor...');
      await Product.deleteMany({ storeId: store._id });
      console.log('✅ Eski ürünler silindi\n');
    }

    // Kategorileri bul/oluştur ve ürünleri ekle
    let totalProducts = 0;
    const productImages = [
      'https://via.placeholder.com/400x400?text=Urun+1',
      'https://via.placeholder.com/400x400?text=Urun+2',
      'https://via.placeholder.com/400x400?text=Urun+3',
    ];

    for (const [categoryName, products] of Object.entries(categoryProductMap)) {
      console.log(`📦 Kategori: ${categoryName}`);

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
        console.log(`   ✅ Kategori oluşturuldu: ${categoryName}`);
      }

      // Ürünleri ekle
      for (const productData of products) {
        const product = new Product({
          name: productData.name,
          description: productData.description,
          price: productData.price,
          originalPrice: Math.floor(productData.price * 1.2), // %20 indirimli göster
          categoryId: category._id,
          storeId: store._id,
          stock: productData.stock,
          images: productImages,
          status: 'active',
          tags: categoryName.toLowerCase().split(' '),
          rating: (Math.random() * 1.5 + 3.5).toFixed(1), // 3.5-5.0 arası rating
          soldCount: Math.floor(Math.random() * 100),
          viewCount: Math.floor(Math.random() * 500)
        });

        await product.save();
        totalProducts++;
      }

      console.log(`   ✅ ${products.length} ürün eklendi\n`);
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 Seed işlemi başarıyla tamamlandı!\n');
    console.log(`📊 Özet:`);
    console.log(`   • Mağaza: ${store.name}`);
    console.log(`   • Kategori sayısı: ${Object.keys(categoryProductMap).length}`);
    console.log(`   • Toplam ürün: ${totalProducts}`);
    console.log(`   • Mağaza sahibi: ${user.name} (${user.email})`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Hata:', error);
    process.exit(1);
  }
}

// Command line argümanlarını parse et
const args = process.argv.slice(2);
const emailArg = args.find(arg => arg.startsWith('--email='));

if (!emailArg) {
  console.log('❌ Email parametresi gerekli!');
  console.log('\n📖 Kullanım:');
  console.log('   node scripts/seed-store-products.js --email=hakanaltunyaldiz1248@gmail.com\n');
  process.exit(1);
}

const email = emailArg.split('=')[1];
seedStoreProducts(email);
