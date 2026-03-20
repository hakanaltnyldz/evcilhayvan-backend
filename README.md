# EvcilHayvan Monorepo

## Backend (Node/Mongo)
- Konfig: `evcilhayvan/.env.example` dosyasını kopyalayıp değerleri doldurun (JWT, Mongo URI, SendGrid vb.).
- Çalıştırma: `cd evcilhayvan && npm install && npm start`
- Test: `cd evcilhayvan && npm test` (Jest + Supertest smoke senaryoları: auth, ilan CRUD, mesaj, mağaza/ürün/sepet).
- API sözleşmesi: `evcilhayvan/swagger.yaml` (OpenAPI 3.0).
- Yükleme servisi: `/api/uploads` ve ilan yükleme uçları yerel dosya sistemi üzerine çalışır.

## Flutter (evcilhayvan_mobil2)
- Bağlantı: `lib/config/app_config.dart` ve giriş dosyaları (`main_dev.dart`, `main_prod.dart`) üzerinden baseUrl/flavor seçin.
  - Örnek: `flutter run -t lib/main_dev.dart --dart-define API_BASE=http://10.0.2.2:4000`
- Testler:
  - Unit/widget: `cd evcilhayvan_mobil2 && flutter test`
  - Entegrasyon: `flutter test integration_test`
- Build kontrolü: `flutter build apk -t lib/main_dev.dart --debug`
- Ağ katmanı: `ApiClient` (Dio) otomatik token/refresh, log ve idempotent retry; tüm depolar bunu kullanır.
- Offline/optimistic: ilan akışı ve mağaza ürünü akışı SharedPreferences üzerinde cache’lenir; ilan oluşturma optimistik olarak listeye eklenir.

## CI
- `.github/workflows/ci.yml`: backend npm test + Flutter analyze/test/integration_test + debug APK build.
