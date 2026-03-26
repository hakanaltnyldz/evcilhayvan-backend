/// Uygulama genelinde kullanılan sabit değerler.
/// Magic number yerine bu sabitleri kullanın.
library;

// ─── Görsel Kalite ───────────────────────────────────────────────────────────
/// Profil fotoğrafı, ürün, mağaza logosu gibi genel yüklemeler (0-100)
const int kImageQualityMedium = 80;

/// Mesaj içi görseller, evcil hayvan fotoğrafları gibi yüksek kaliteli yüklemeler
const int kImageQualityHigh = 85;

/// Gönderi / etkinlik fotoğrafı gibi düşük öncelikli küçük önizlemeler
const int kImageQualityLow = 70;

/// Profil ve küçük görseller için maksimum genişlik (px)
const double kImageMaxWidthSmall = 800;

/// Galeri yüklemeleri için maksimum genişlik (px)
const double kImageMaxWidth = 1200;

// ─── Konum / Mesafe ──────────────────────────────────────────────────────────
/// Yakın evcil hayvan ilanları için varsayılan arama yarıçapı (km)
const double kDefaultPetRadiusKm = 25;

/// Veteriner arama için varsayılan yarıçap (km)
const double kDefaultVetRadiusKm = 10;

/// Kayıp & Bulunan için varsayılan yarıçap (km)
const double kDefaultLostFoundRadiusKm = 50;

/// Bakıcı arama için varsayılan yarıçap (km)
const double kDefaultSitterRadiusKm = 20;

/// Etkinlik listesi için varsayılan yarıçap (km)
const double kDefaultEventRadiusKm = 50;

/// Harita keşif sayfası için varsayılan yarıçap (km)
const double kDefaultMapRadiusKm = 15;

/// Çiftleşme eşleştirme için varsayılan maksimum mesafe (km)
const double kDefaultMatingMaxDistanceKm = 20;

// ─── Sayfalama ───────────────────────────────────────────────────────────────
/// Genel liste sayfası boyutu
const int kDefaultPageSize = 10;

/// Mağaza ürün akışı sayfa boyutu
const int kStoreFeedLimit = 40;
