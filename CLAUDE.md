# Evcilhayvan Projesi — Claude Kılavuzu

## Panel Strategy

- Active web panel source of truth: `evcilhayvan_admin/`.
- `evcilhayvan_admin/` contains both admin workspace and seller workspace.
- Seller web routes live under `/seller/*` and page code lives under `evcilhayvan_admin/src/pages/seller/`.
- `evcilhayvan_seller/` is a legacy standalone seller panel. Keep it buildable, but do not add new seller features there unless explicitly asked.
- Current deploy (`render.yaml`) publishes only `evcilhayvan_admin/dist`.
- Full decision record: `docs/PANEL_STRATEGY.md`.

Bu dosya her yeni oturumda otomatik okunur. Projeyi tekrar anlatmana gerek yok.

---

## Proje Yapısı

```
evcilhayvanoriginal/
├── evcilhayvan/          # Backend — Node.js + Express + MongoDB
├── evcilhayvan_admin/    # Admin Panel — React + Vite + Tailwind CSS
└── evcilhayvan_mobil2/   # Mobil Uygulama — Flutter + Riverpod + GoRouter
```

---

## Backend (evcilhayvan/)

**Entry point:** `evcilhayvan/server.js`

### Response Formatı
Backend `sendOk(res, status, payload)` kullanır. Payload **flat spread** edilir, `data` altında yuvalanmaz:
```js
// Doğru: res.data.users  (YANLIŞ: res.data.data.users)
sendOk(res, 200, { users: [...] })  →  { success: true, ok: true, users: [...] }
```

### Kritik API Endpoint'leri
| Endpoint | Response Key |
|---|---|
| GET /api/veterinaries | `{ vets: [...] }` (NOT `veterinaries`) |
| GET /api/veterinaries/:id | `{ vet: {...} }` (NOT `veterinary`) |
| GET /api/conversations | `{ conversations: [...] }` |
| GET /api/conversations/:id/messages | `{ messages: [...] }` |
| GET /api/auth/me/notification-preferences | `{ preferences: {...} }` |
| POST /api/ai/chat | `{ reply: "..." }` |

### Önemli Model Dosyaları
- `src/models/User.js` — `notificationPreferences` subdocument (9 Boolean alan)
- `src/models/Store.js` — `bannerUrl, phone, website, instagram, twitter, facebook, workingHours`
- `src/models/PetSitter.js` — `displayName, avatar, services, speciesServed, rating, reviewCount`
- `src/routes/adminRoutes.js` — tüm admin endpoint'leri
- `src/routes/authRoutes.js` — GET/PATCH `/me/notification-preferences`
- `src/routes/storeRoutes.js` — PATCH `/me/profile`

### AI Assistant
- `ANTHROPIC_API_KEY` → `.env` dosyasında (boşsa AI gracefully devre dışı)
- Model: `claude-haiku-4-5-20251001`
- Route: `POST /api/ai/chat` (auth gerekli)

---

## Admin Panel (evcilhayvan_admin/)

**Stack:** React + Vite + Tailwind CSS

### API İstemcisi
`src/api.js` — axios instance:
- `baseURL = VITE_API_URL + '/api'`  (genellikle `http://localhost:3000/api`)
- JWT interceptor: header'a `Authorization: Bearer <token>` ekler
- 401'de localStorage temizler ve login'e yönlendirir
- **Tüm sayfalar `api.js` kullanır** — yalnızca `Sitters.jsx` `fetch()` kullanıyor (tutarsızlık)

### Sayfalar ve Endpoint'leri
| Sayfa | Endpoint |
|---|---|
| Dashboard.jsx | GET /admin/stats → `res.data.stats` |
| Users.jsx | GET /admin/users → `res.data.users`, `res.data.total` |
| Orders.jsx | GET /admin/orders → `res.data.orders`, PATCH /admin/orders/:id/tracking |
| Posts.jsx | GET /admin/posts → `res.data.posts` |
| Coupons.jsx | GET /admin/coupons |
| Reports.jsx | GET /admin/reports |
| Support.jsx | GET /admin/support |
| Sitters.jsx | GET /admin/pet-sitters → `data.sitters` (fetch kullanıyor!) |

### Admin Route'ları (App.jsx)
Dashboard, Users, Pets, Orders, Posts, Coupons, Reports, Sitters, Support

---

## Flutter Mobil (evcilhayvan_mobil2/)

### Kritik Dosyalar
- **Router:** `lib/router/app_router.dart`
- **Shell:** `lib/main_shell.dart`
- **HTTP:** `lib/core/http.dart` (Dio instance)
- **Notification Provider:** `lib/features/notifications/providers/notification_provider.dart`

### Build Komutu (Windows)
```bash
flutter build apk --release
# APK çıktısı: build\app\outputs\flutter-apk\app-release.apk (~60MB)
```

**Hata: "Erişim engellendi" (dosya kilidi):**
```bash
taskkill /F /IM java.exe /T
taskkill /F /IM dart.exe /T
flutter clean
flutter build apk --release
```

**ADB ile kurulum:**
```bash
adb connect <IP>:<PORT>
adb -s <IP>:<PORT> install -r build/app/outputs/flutter-apk/app-release.apk
```

### Provider'lar
| Provider | Tip | Açıklama |
|---|---|---|
| `authProvider` | StateNotifierProvider<User?> | Giriş yapmış kullanıcı |
| `unreadCountProvider` | int | Okunmamış bildirim sayısı |
| `notificationProvider` | List<AppNotification> | Bildirim listesi |
| `conversationsProvider` | FutureProvider.autoDispose | Konuşmalar |
| `messagesProvider` | FutureProvider.autoDispose | Mesajlar |
| `myStoreProvider` | FutureProvider | Satıcı mağazası |
| `themeModeProvider` | StateNotifierProvider | Dark/Light mode (SharedPrefs) |

### Route İsimleri (GoRouter)
**Shell Routes (alt nav):** `home, messages, veterinary, store, profile`

**Diğer Routes:**
```
mating, mating-requests, lost-found, sitters, events
pet-detail (pathParam: id)
chat (pathParam: conversationId)
vaccination-reminders → VetHomeScreen(initialTabIndex: 2)
search, health-journal (pathParam: petId)
ai-assistant, onboarding, splash
user-profile (pathParam: userId)
privacy-policy
my-addresses, notification-preferences
add-address
```

### Flutter Kod Kalıpları
- `context.pushNamed()` → **her zaman dış build() context'inden** çağır, ListView itemBuilder içinden değil
- `VetHomeScreen` → `initialTabIndex` parametresi kabul eder (tab deep-linking için)
- `ValueKey` → swipe deck / filter değiştiğinde state sıfırlamak için
- Mating: `HapticFeedback.mediumImpact` (like), `.lightImpact` (pass)
- Block/report: route yok, `showBlockReportSheet()` bottom sheet

---

## Uygulanan Özellikler (Tam Liste)

### Temel
- Auth (giriş/kayıt/çıkış), Evcil Hayvanlar, İlanlar
- Eşleşme/Çiftleşme (swipe kartları), Mesajlar (real-time socket)
- Favoriler, Yorumlar

### Mağaza
- Ürünler, Sepet, Siparişler, Satıcı Dashboard
- Kuponlar (kullanıcı + satıcı yönetimi)
- Ürün Varyantları (beden/renk/boyut)
- Mağaza profili zenginleştirme (banner, iletişim, sosyal medya, çalışma saatleri)

### Veteriner & Sağlık
- Veteriner listesi + detay (çoklu foto galerisi - PageView)
- Randevular, Aşı takibi (hatırlatıcılar cron ile)
- Sağlık Günlüğü (kayıtlar + grafik + hedef kilo + istatistikler)

### Topluluk
- Kayıp İlanları, Evcil Hayvan Bakıcıları + Rezervasyonlar
- Evcil Hayvan Etkinlikleri, Sosyal Gönderiler
- Sahiplendirme Başvuruları

### Bildirimler & Keşif
- Bildirimler (socket + kalıcı)
- Bildirim Tercihleri (9 toggle, backend'e PATCH)
- Harita (vet/bakıcı/kayıp hayvan marker katmanları)
- Global Arama

### Kullanıcı
- Profil, Ayarlar
- Adreslerim ekranı
- Kullanıcı Profili (public)
- Engelle/Şikayet (bottom sheet)
- Gizlilik Politikası

### UX
- Dark Mode (SharedPrefs ile kalıcı)
- Onboarding (4 slayt, ilk açılışta)
- Splash Screen (animasyonlu, 2 saniye)
- Home skeleton loading (shimmer animasyon)
- Home sayfalama (paginated adverts)
- Home yakın filtresi (Geolocator + radiusKm)
- Pet detay: resim zoom + paylaşım butonu
- Chat: resim yükleme, okundu işareti
- Uygulama değerlendirme (in_app_review)
- AI Asistan ("Pati Asistan" - Claude Haiku)

### Admin Panel
- Dashboard istatistikleri
- Kullanıcı yönetimi (ban, rol değiştir)
- Sipariş yönetimi (kargo takip bilgisi)
- Gönderi moderasyonu (gizle/göster)
- Bakıcı yönetimi (doğrulama)
- Kupon, Rapor, Destek yönetimi

---

## Disk Uyarısı
C: sürücüsü dolabilir. `flutter clean` ~2GB serbest bırakır.
Build klasörü: `evcilhayvan_mobil2/build/` (temizlenebilir)

---

## Geliştirme Notları
- `sendOk` flat spread eder — asla `res.data.data.X` kullanma
- Sitters.jsx `fetch()` kullanıyor (api.js'e taşınabilir ama çalışıyor)
- Login.jsx `res.data?.data?.token || res.data?.token` — çift fallback (güvenli)
