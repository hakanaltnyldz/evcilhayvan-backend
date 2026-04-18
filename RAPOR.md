# EvcilHayvan Mobil Uygulaması
## Dönem Sonu Proje Raporu

**Proje Adı:** EvcilHayvan — Evcil Hayvan Sahipleri İçin Sosyal & Hizmet Platformu  
**Dönem:** 2024–2025 Bahar Dönemi  
**Tarih:** Nisan 2025  
**Geliştirici:** Hakan Altınyıldız  
**Teknoloji Yığını:** Flutter · Node.js + Express · MongoDB Atlas · Render.com

---

## 1. Proje Hakkında Genel Bilgi

EvcilHayvan; sahiplendirme, çiftleşme, mesajlaşma, veteriner bulma, pet bakıcısı kiralama, alışveriş ve kayıp hayvan ilanı gibi evcil hayvan sahiplerinin ihtiyaç duyduğu tüm hizmetleri tek bir mobil uygulamada toplayan kapsamlı bir platformdur.

**Hedef Kullanıcı Kitlesi:**

| Kullanıcı Tipi | Açıklama |
|---|---|
| Evcil Hayvan Sahipleri | Bakıcı bulmak, veterinere gitmek, alışveriş yapmak isteyen kullanıcılar |
| Veteriner Klinikleri | Randevu almak ve klinik profilini yönetmek isteyen veterinerler |
| Pet Bakıcıları | Kendi bakıcılık hizmetlerini sunan bireyler |
| Hayvan Severler | Sahiplenmek, sosyal içerik üretmek, etkinliklere katılmak isteyenler |

**Üç Ana Bileşen:**
- **Mobil Uygulama (Flutter):** Android APK olarak build alınıp yüklenebilmektedir.
- **Backend (Node.js + Express):** Render.com üzerinde canlı olarak çalışmaktadır.
- **Veritabanı (MongoDB Atlas):** Bulut tabanlı, 7/24 erişilebilir.

---

## 2. Teknik Mimari

```
┌──────────────────────────────────┐
│   Flutter Mobil (Android APK)    │
│   Riverpod + GoRouter            │
└──────────────┬───────────────────┘
               │ HTTPS / WebSocket
               ▼
┌──────────────────────────────────┐
│   Node.js + Express (Render.com) │
│   REST API  │  Socket.io         │
└──────────────┬───────────────────┘
               │ Mongoose ODM
               ▼
┌──────────────────────────────────┐
│   MongoDB Atlas (Bulut DB)       │
└──────────────────────────────────┘
```

**Flutter Temel Kütüphaneleri:**

| Kütüphane | Amaç |
|---|---|
| `flutter_riverpod 2.5.1` | State yönetimi |
| `go_router 14.1.0` | Sayfa yönlendirme (60+ route) |
| `dio 5.4.3` | HTTP istekleri |
| `socket_io_client 3.0.2` | Gerçek zamanlı mesajlaşma |
| `google_maps_flutter 2.14.0` | Harita |
| `firebase_messaging 15.1.3` | Push bildirimler |
| `fl_chart 0.69.0` | Grafik/istatistik |
| `table_calendar 3.1.2` | Takvim widget |
| `flutter_card_swiper 7.1.0` | Eşleştirme swipe kartları |

**Backend Özellikleri:**
- 34 route dosyası, 260+ REST API endpoint
- JWT kimlik doğrulama, Socket.io gerçek zamanlı iletişim
- Firebase FCM push bildirimler, Cron job (aşı hatırlatıcı), Multer dosya yükleme

---

## 3. Geçen Dönem Yapılanlar (Özet)

Geçen dönemde uygulamanın iskelet yapısı kurulmuştu:

- **Kimlik Doğrulama:** JWT tabanlı kayıt, giriş, profil yönetimi
- **Hayvan İlanları:** Sahiplendirme ve çiftleştirme ilanı oluşturma
- **Eşleştirme (Swipe):** Tinder benzeri kart kaydırma ile hayvan eşleştirme
- **Gerçek Zamanlı Mesajlaşma:** Socket.io ile anlık mesaj, fotoğraf gönderme, okundu işareti
- **Mağaza & E-Ticaret:** Ürün listeleme, sepet, sipariş oluşturma ve takip
- **Profil & Düzenleme Ekranları**

**Dönemin Sınırlılığı:** Uygulama yalnızca lokal ortamda çalışıyordu; dış dünyadan erişilemiyordu.

---

## 4. Bu Dönem Yapılan Çalışmalar

### 4.1 Canlı Sunucu ve MongoDB Atlas Geçişi *(En Kritik Değişiklik)*

**Önceki Durum:** Backend geliştirici bilgisayarında çalışıyordu, veritabanı lokaldi.

**Yapılan Değişiklikler:**

- **MongoDB Atlas:** Lokal veritabanı buluta taşındı. 7/24 erişim, otomatik yedekleme ve TLS/SSL güvenliği sağlandı.
- **Render.com Deploy:** Backend Render platformuna deploy edildi. GitHub'a push yapıldığında otomatik yeni versiyon devreye giriyor. Otomatik SSL, otomatik yeniden başlatma.

**Sonuç:** APK'yı alan herhangi bir Android kullanıcısı uygulamayı gerçek verilerle test edebilmektedir. Birden fazla kullanıcı aynı anda mesajlaşabilmekte ve birbirlerinin ilanlarını görebilmektedir.

[Ekran görüntüsü: Ana ekran — uygulamanın canlı ortamda çalışır hali]

---

### 4.2 Veteriner Modülü

Kullanıcılar konumlarına yakın veterinerleri listeleyebilmekte, klinik detaylarına ulaşabilmekte ve Google Places API ile sistemde kayıtlı olmayan klinikleri de aratabilmektedir.

**Ekranlar:** Veteriner listesi, veteriner detayı (fotoğraf galerisi, hizmetler, çalışma saatleri, randevu butonu), veteriner arama.

**Önemli Teknik Detay:** Konum bilgisi MongoDB'nin `2dsphere` indeksiyle saklanmaktadır. Bu sayede "bana en yakın 5 veteriner" gibi coğrafi sorgular milisaniyelerde yanıt vermektedir.

**API Endpoint'leri:**
```
GET /api/veterinaries          → Veteriner listesi
GET /api/veterinaries/nearby   → Konuma göre yakın veterinerler
GET /api/veterinaries/google-search → Google Places ile arama
GET /api/veterinaries/:id      → Veteriner detayı
```

[Ekran görüntüsü: Veteriner listesi]

[Ekran görüntüsü: Veteriner detay ekranı]

---

### 4.3 Randevu Sistemi

Uygulama üzerinden doğrudan veteriner randevusu alınabilmektedir. Veterinerler müsait saatlerini sisteme girmekte, kullanıcılar takvimden seçim yapmaktadır.

**Randevu Durumları:** Beklemede → Onaylandı → Tamamlandı / İptal Edildi

```
POST  /api/appointments                  → Randevu oluştur
GET   /api/appointments/me               → Benim randevularım
GET   /api/appointments/vet/:id/slots    → Müsait saatler
PATCH /api/appointments/:id/status       → Durum güncelle
```

[Ekran görüntüsü: Randevu oluşturma — takvim görünümü]

---

### 4.4 Aşı Takibi ve Otomatik Hatırlatıcılar

Hayvanların aşı geçmişi kaydedilebilmekte, gelecek aşılar için takvim oluşturulabilmektedir. Sunucu tarafında çalışan cron job her 15 dakikada bir yaklaşan aşı tarihlerini kontrol ederek Firebase FCM üzerinden push bildirim göndermektedir.

```javascript
cron.schedule('*/15 * * * *', async () => {
  // Gelecek 24 saat içindeki aşıları bul → FCM ile bildirim gönder
})
```

[Ekran görüntüsü: Aşı takvimi ekranı]

---

### 4.5 Sağlık Günlüğü

Her hayvan için kilo, veteriner ziyareti, ilaç ve genel notlar içeren sağlık kaydı tutulabilmektedir. `fl_chart` kütüphanesiyle kilo değişimi grafiksel olarak görselleştirilmekte, hedef kilo çizgisi ayrı renkte gösterilmektedir.

```
GET    /api/health/:petId   → Sağlık kayıtları
POST   /api/health          → Yeni kayıt ekle
```

[Ekran görüntüsü: Sağlık günlüğü — kilo grafiği]

---

### 4.6 Pet Bakıcı (Pet Sitter) Modülü

Tatile ya da seyahate çıkan evcil hayvan sahipleri güvenilir bakıcı bulup rezervasyon yapabilmektedir.

**Sunulan Hizmetler:** Yürüyüş · Ev Bakımı · Pansiyonluk · Günlük Bakım · Tımar

**Rezervasyon Akışı:**
1. Kullanıcı bakıcı listesinde gezinir, profil ve fiyat inceler
2. Tarih ve hizmet seçerek rezervasyon isteği oluşturur
3. Bakıcıya bildirim gider; kabul veya reddeder
4. Onaydan sonra bakıcı yürüyüş sırasında fotoğraf/güncelleme gönderebilir

```
GET   /api/pet-sitters             → Bakıcı listesi
GET   /api/pet-sitters/:id         → Bakıcı detayı
POST  /api/sitter-bookings         → Rezervasyon oluştur
PATCH /api/sitter-bookings/:id/status → Kabul/Reddet
```

[Ekran görüntüsü: Pet bakıcı listesi]

[Ekran görüntüsü: Bakıcı profil detayı]

---

### 4.7 Kayıp / Bulunan Hayvan İlan Sistemi

Kayıp hayvan sahipleri ve hayvan bulanlar ilan oluşturabilmektedir. Tüm ilanlar haritada görüntülenmekte, MongoDB `$near` operatörü ile kullanıcıya en yakın ilanlar önce listelenmektedir.

```
GET   /api/lost-found        → İlanlar
GET   /api/lost-found/near   → Yakındaki ilanlar
POST  /api/lost-found        → Yeni ilan oluştur
PATCH /api/lost-found/:id/status → "Bulundu" işaretle
```

[Ekran görüntüsü: Kayıp/Bulunan hayvan listesi]

---

### 4.8 Sahiplendirme Başvuru Sistemi

Geçen dönem ilan açılabiliyordu ancak başvuru yapılamıyordu. Bu dönem eklenen sistemle kullanıcılar sahiplendirme ilanına resmi başvuru yapabilmekte, ilan sahibi başvuruları inceleyerek kabul veya reddedebilmektedir.

**Akış:** Başvur → İlan sahibine bildirim → Profil inceleme → Kabul / Red → Başvurucuya bildirim

---

### 4.9 Evcil Hayvan Etkinlikleri

Köpek yürüyüşleri, kedi buluşmaları, sahiplendirme fuarları gibi etkinlikler oluşturulabilmekte ve katılım bildirilebilmektedir.

[Ekran görüntüsü: Etkinlikler listesi]

---

### 4.10 Sosyal Akış (Feed) ve Gönderi Sistemi

Kullanıcılar hayvanlarıyla ilgili fotoğraf paylaşabilmekte, beğenebilmekte ve yorum yapabilmektedir. Beğeni işleminde optimistik UI kullanılmaktadır: UI önce güncellenir, API isteği arka planda atılır.

[Ekran görüntüsü: Sosyal akış (Feed)]

---

### 4.11 Harita Ekranı

Çevredeki veterinerler, pet bakıcıları ve kayıp hayvan ilanları tek harita üzerinde görselleştirilmektedir. Renkli marker'larla kategoriler ayrılmaktadır (kırmızı: vet, yeşil: bakıcı, turuncu: kayıp ilan). Katmanlar toggle ile açılıp kapatılabilmektedir.

[Ekran görüntüsü: Harita ekranı — vet ve bakıcı markerları]

---

### 4.12 Global Arama

Tek arama kutusundan hayvan ilanları, mağazalar ve veterinerler aranabilmektedir. 400ms debounce ile aşırı API çağrısı önlenmekte, sonuçlar kategorilere göre gruplanmaktadır.

[Ekran görüntüsü: Global arama sonuçları]

---

### 4.13 Bildirim Tercihleri

9 kategori için bildirim açma/kapama ayarı mevcuttur: Mesajlar, Eşleştirme, Yorumlar, Beğeniler, Sipariş Güncellemeleri, Sahiplendirme Başvuruları, Aşı Hatırlatıcıları, Etkinlikler, Sistem. Tercihler sunucuya kaydedilmekte, cihaz değiştirilse bile korunmaktadır.

[Ekran görüntüsü: Bildirim tercihleri — toggle listesi]

---

### 4.14 Mağaza Güncellemeleri

Ürünler artık fiyat (artan/azalan), tarih ve puana göre sıralanabilmekte; kategori, hayvan türü ve fiyat aralığına göre filtrelenebilmektedir.

---

### 4.15 Kullanıcı Arayüzü Yenileme — Dark Mode ve Tasarım

**Dark Mode:** `themeModeProvider` (Riverpod) ile yönetilmekte, tercih `SharedPreferences`'ta saklanmaktadır. Uygulama kapatılsa da seçilen tema korunur.

**Genel UI Yenileme:** Tüm renk paleti yeşil tona (`#4CAF50`) çevrilmiştir. Shimmer yükleme animasyonları, sayfa geçiş efektleri (fade + slide), tutarlı tipografi ve boşluk sistemi eklenmiştir.

[Ekran görüntüsü: Ana ekran — Dark Mode]

[Ekran görüntüsü: Ana ekran — Light Mode]

---

### 4.16 Onboarding ve Splash Ekranı

**Splash:** Uygulama açılışında 2 saniyelik animasyonlu karşılama. Bu sürede token kontrolü yapılır; giriş yapılmışsa ana sayfaya, yapılmamışsa onboarding'e yönlendirilir.

**Onboarding:** İlk açılışta 4 slaytlık tanıtım (Sahiplendirme → Veteriner → Alışveriş → Topluluk). `onboardingSeenProvider` ile bir kez gösterilip SharedPreferences'a kaydedilir.

[Ekran görüntüsü: Onboarding — 1. slayt]

[Ekran görüntüsü: Splash ekranı]

---

### 4.17 Engelle ve Şikayet Özelliği

Rahatsız edici kullanıcılar engellenebilmekte veya şikayet edilebilmektedir. Tam ekran yerine bottom sheet (aşağıdan kayan panel) olarak tasarlanmıştır.

---

## 5. Veritabanı Yapısı

EvcilHayvan 37 MongoDB koleksiyonu kullanmaktadır. Önemli olanlar:

| Koleksiyon | Açıklama |
|---|---|
| `users` | Kullanıcı hesapları, bildirim tercihleri |
| `pets` | Hayvan ilanları (2dsphere konum indeksi) |
| `conversations / messages` | Mesajlaşma |
| `veterinaries` | Veteriner klinikleri (2dsphere) |
| `appointments` | Randevular |
| `vaccinationrecords` | Aşı kayıtları |
| `petsitters / sitterbookings` | Bakıcı profili ve rezervasyonlar |
| `lostfoundpets` | Kayıp/Bulunan ilanları (2dsphere) |
| `healthrecords` | Sağlık günlüğü |
| `events` | Etkinlikler |
| `posts` | Sosyal gönderiler |
| `stores / products / orders` | E-ticaret |
| `adoptionapplications` | Sahiplendirme başvuruları |
| `matchrequests` | Eşleştirme istekleri |

**Coğrafi İndeksler (`2dsphere`):** Pet, Veterinary, LostFoundPet, PetSitter modellerinde — yakın arama sorgularını milisaniyeye indiriyor.

---

## 6. Önemli API Endpoint'leri

| Modül | Endpoint Örnekleri |
|---|---|
| Auth | POST /auth/login · GET /auth/me · PATCH /auth/me/notification-preferences |
| Hayvan İlanları | GET /pets/feed · POST /pets · GET /pets/:id |
| Eşleştirme | GET /matching/profiles · POST /matching/requests |
| Mesajlaşma | GET /conversations · POST /conversations/:id/messages |
| Veteriner | GET /veterinaries/nearby · GET /veterinaries/google-search |
| Randevu | POST /appointments · GET /appointments/vet/:id/slots |
| Aşı | POST /vaccinations · GET /vaccinations |
| Pet Bakıcı | GET /pet-sitters · POST /sitter-bookings |
| Kayıp/Bulunan | GET /lost-found/near · POST /lost-found |
| Sağlık | GET /health/:petId · POST /health |
| Sosyal | GET /posts · POST /posts/:id/like |
| Etkinlikler | GET /events · POST /events/:id/attend |
| Mağaza | GET /stores · POST /orders · GET /orders/track/:number |

---

## 7. Ekran Görüntüleri

### Başlangıç Deneyimi
[Ekran görüntüsü: Splash ekranı]

[Ekran görüntüsü: Onboarding — 1. slayt]

### Ana Ekran
[Ekran görüntüsü: Ana ekran — Light Mode]

[Ekran görüntüsü: Ana ekran — Dark Mode]

### Veteriner & Sağlık
[Ekran görüntüsü: Veteriner listesi]

[Ekran görüntüsü: Veteriner detay ekranı]

[Ekran görüntüsü: Randevu oluşturma]

[Ekran görüntüsü: Aşı takvimi]

[Ekran görüntüsü: Sağlık günlüğü — kilo grafiği]

### Pet Bakıcı
[Ekran görüntüsü: Bakıcı listesi]

[Ekran görüntüsü: Bakıcı profil detayı]

### Sosyal & Keşif
[Ekran görüntüsü: Kayıp/Bulunan hayvan listesi]

[Ekran görüntüsü: Etkinlikler listesi]

[Ekran görüntüsü: Sosyal akış (Feed)]

[Ekran görüntüsü: Harita ekranı]

[Ekran görüntüsü: Global arama sonuçları]

### Ayarlar
[Ekran görüntüsü: Bildirim tercihleri]

---

## 8. Karşılaşılan Zorluklar ve Çözümler

| Sorun | Çözüm |
|---|---|
| Flutter build dosyaları C: sürücüsünü doldurdu | `flutter clean` ile ~2GB alan açıldı |
| Windows'ta java/dart process dosyaları kilitledi | `taskkill /F /IM java.exe /T` ardından clean & rebuild |
| Render'a deploy sonrası CORS hatası | Backend CORS yapılandırması production için güncellendi |
| Uygulama arka planda WebSocket bağlantısı kesiliyor | Firebase FCM fallback mekanizması kuruldu |
| Konum filtresi tüm kayıtlarda yavaş çalışıyordu | MongoDB `2dsphere` indeksi ile ms seviyesine indirildi |

---

## 9. Sonuç ve Gelecek Dönem Planları

### Bu Dönem Özeti

| Metrik | Geçen Dönem | Bu Dönem |
|---|---|---|
| Temel Özellik | 6 | 25+ |
| Flutter Ekranı | ~15 | 60+ |
| MongoDB Koleksiyonu | ~10 | 37 |
| Sunucu | Lokal | Render.com (Canlı) |
| Veritabanı | Lokal MongoDB | MongoDB Atlas (Bulut) |

Bu dönemde uygulama işlevsel bir demo ürününden gerçek bir ürüne dönüştürülmüştür.

### Gelecek Dönem Planları

- iOS desteği (Flutter'ın çapraz platform avantajı)
- Ödeme entegrasyonu (iyzico)
- AI destekli hayvan tanıma (fotoğraftan ırk tespiti)
- Coğrafi push bildirimler (yakınında kayıp ilan varsa uyar)
- Play Store yayını

---

## Ek — Kullanılan Teknolojiler

| Teknoloji | Amaç |
|---|---|
| Flutter / Dart | Mobil uygulama |
| Node.js + Express.js | Backend REST API |
| MongoDB Atlas | Bulut veritabanı |
| Render.com | Backend hosting |
| Socket.io | Gerçek zamanlı mesajlaşma |
| Firebase FCM | Push bildirimler |
| Google Maps + Places API | Harita ve konum arama |
| JWT + Bcrypt | Güvenli kimlik doğrulama |
| Riverpod | State yönetimi |
| GoRouter | Sayfa yönlendirme |

---

*EvcilHayvan — 2025–2026 Bahar Dönemi Proje Raporu*  
*Geliştirici: Hakan Altunyaldız*
