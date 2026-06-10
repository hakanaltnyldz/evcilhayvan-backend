# Yazılım Mühendisliği Final Projesi Taslağı

## Proje Adı
Bulut Tabanlı Dağıtık Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu

## 1. Proje Tanımı
Bu proje; evcil hayvan sahiplerini, veterinerleri, pet bakıcılarını, satıcıları ve platform yöneticilerini aynı sistem altında buluşturan dağıtık bir yazılım platformudur. Sistem; mobil uygulama, yönetim panelleri, bulut üzerinde çalışan backend servisi, gerçek zamanlı mesajlaşma altyapısı ve veritabanı katmanından oluşur.

Projenin amacı; evcil hayvan sahiplerinin tek bir platform üzerinden hayvan profili yönetebilmesi, sahiplendirme ve eşleştirme ilanları verebilmesi, veteriner randevusu oluşturabilmesi, aşı ve sağlık kayıtlarını takip edebilmesi, pet bakıcısı bulabilmesi, mağazadan ürün sipariş edebilmesi ve diğer kullanıcılarla mesajlaşabilmesidir.

## 2. Bu Proje Ödev Şartlarını Karşılıyor mu?

| Ödev Şartı | Projedeki Karşılığı |
|---|---|
| Yazılım projesi olmalı | Proje tamamen yazılım tabanlıdır |
| Dağıtık sistem içermeli | Mobil istemci + admin paneli + satıcı paneli + backend API + Socket sunucusu + bulut veritabanı |
| İnternet/bulut/ağ üzerinde çalışmalı | Backend bulutta, veritabanı MongoDB Atlas üzerinde, istemciler ağ üzerinden erişir |
| Veritabanı işlemleri içermeli | MongoDB/Mongoose ile kullanıcı, ilan, randevu, sipariş, mesaj, bakıcı rezervasyonu vb. yönetilir |
| Mobil uygulama ayağı olmalı | Flutter tabanlı mobil uygulama vardır |
| En az 6 personel içermeli | Aşağıda 6 kişilik proje ekibi kurgulanmıştır |
| Gereksinimler modellenmeli | Bu taslakta işlevsel, işlevsel olmayan gereksinimler ve kullanım senaryoları verilmiştir |
| Diyagramlar çizilmeli | Use case, deployment, class ve sequence diyagramları eklenmiştir |

## 3. Varsayımlar

1. Bu rapor bireysel teslim edilecektir; ancak proje organizasyonu ders şartına uygun olacak şekilde 6 kişilik ekip modeli ile ele alınacaktır.
2. Proje, gerçek kodu bulunan bir sistemden esinlenerek yazılım mühendisliği çıktılarıyla yeniden modellenmektedir.
3. Ödeme entegrasyonu gerçek banka bağlantısı yerine sipariş onay akışı olarak modellenmiştir.
4. Bildirim altyapısı Firebase Cloud Messaging benzeri bir servis ile sağlanmaktadır.
5. Dosya yüklemeleri uygulama görselleri, pet fotoğrafları ve mağaza ürün görselleri için kullanılmaktadır.

## 4. Proje Kapsamı

### Kapsama Dahil Modüller
- Kullanıcı kayıt, giriş ve profil yönetimi
- Evcil hayvan profili oluşturma ve yönetme
- Sahiplendirme ilanları ve başvuru sistemi
- Çiftleştirme/eşleştirme sistemi
- Gerçek zamanlı mesajlaşma
- Veteriner arama ve randevu sistemi
- Aşı takibi ve sağlık günlüğü
- Pet bakıcı bulma ve rezervasyon sistemi
- Kayıp/bulunan hayvan ilanları
- Sosyal paylaşım akışı
- Mağaza, ürün, sepet ve sipariş yönetimi
- Admin paneli ve satıcı paneli

### Kapsam Dışı
- Gerçek banka/ödeme kuruluşu entegrasyonu
- iOS mağaza yayını
- Fiziksel donanım/sensör tabanlı IoT entegrasyonu

## 5. Paydaşlar
- Evcil hayvan sahibi kullanıcılar
- Veteriner klinikleri
- Pet bakıcıları
- Satıcılar
- Sistem yöneticileri
- Proje ekibi

## 6. Proje Ekibi ve Roller

> Not: Bu bölüm ödevdeki "en az 6 personel" şartını karşılamak için proje organizasyonu olarak modellenmiştir.

| Rol | Sorumluluk |
|---|---|
| Proje Yöneticisi / İş Analisti | Kapsam, gereksinim yönetimi, sprint planlama, paydaş iletişimi |
| Sistem Analisti / UML Tasarımcısı | Use case, sınıf diyagramı, etkileşim diyagramı, süreç modelleme |
| Backend Geliştirici | REST API, kimlik doğrulama, iş kuralları, socket altyapısı |
| Mobil Uygulama Geliştiricisi | Flutter arayüzleri, servis entegrasyonları, kullanıcı deneyimi |
| Web Panel Geliştiricisi | Admin paneli, satıcı paneli, raporlama ekranları |
| Veritabanı ve DevOps Uzmanı | Veritabanı tasarımı, deploy, güvenlik, yedekleme, loglama |
| Test ve Kalite Uzmanı | Test senaryoları, kabul testleri, regresyon ve hata takibi |

## 7. Yazılım Geliştirme Yaşam Döngüsü

### 7.1 İhtiyaç Analizi
- Kullanıcıların çok sayıda farklı pet hizmeti için ayrı uygulama kullanma problemi tespit edilmiştir.
- Tek platformda sosyal, sağlık, bakım ve ticaret süreçlerinin birleştirilmesi hedeflenmiştir.

### 7.2 Gereksinim Analizi
- Aktörler belirlenmiştir.
- İşlevsel ve işlevsel olmayan gereksinimler çıkarılmıştır.
- Kullanım senaryoları ve iş akışları tanımlanmıştır.

### 7.3 Tasarım
- Katmanlı ve servis tabanlı bir mimari seçilmiştir.
- Mobil istemci, web panelleri, backend API, socket ve veritabanı bileşenleri ayrıştırılmıştır.
- UML diyagramları ile sistem tasarımı modellenmiştir.

### 7.4 Gerçekleme
- Bu ders tesliminde kodlama yapılmasa da gerçekleme aşaması teorik olarak mobil, web ve backend modülleri şeklinde planlanmıştır.

### 7.5 Test
- Birim test, API test, kullanıcı kabul testi ve entegrasyon testi planlanmıştır.
- Kritik akışlar: giriş, randevu, sipariş, rezervasyon, mesajlaşma.

### 7.6 Yaygınlaştırma ve Bakım
- Sistem bulut üzerinde yayınlanır.
- Hata logları, performans takibi ve kullanıcı geri bildirimleri ile bakım süreci devam eder.

## 8. İşlevsel Gereksinimler

1. Sistem kullanıcı kaydı ve giriş işlemini desteklemelidir.
2. Kullanıcı evcil hayvan profili oluşturabilmeli ve güncelleyebilmelidir.
3. Kullanıcı sahiplendirme ilanı oluşturabilmelidir.
4. Kullanıcı sahiplendirme ilanına başvuru yapabilmelidir.
5. Kullanıcı eşleştirme profillerini görüntüleyip istek gönderebilmelidir.
6. Kullanıcı diğer kullanıcılarla gerçek zamanlı mesajlaşabilmelidir.
7. Kullanıcı yakın veterinerleri konuma göre arayabilmelidir.
8. Kullanıcı veteriner randevusu oluşturabilmelidir.
9. Kullanıcı aşı takvimi ve sağlık kayıtlarını yönetebilmelidir.
10. Kullanıcı pet bakıcısı arayabilmeli ve rezervasyon yapabilmelidir.
11. Kullanıcı mağazadan ürün sepete ekleyip sipariş verebilmelidir.
12. Satıcı kendi ürünlerini ve siparişlerini yönetebilmelidir.
13. Admin kullanıcı, ilan ve şikayetleri denetleyebilmelidir.
14. Sistem kullanıcılara bildirim gönderebilmelidir.
15. Sistem kayıp/bulunan hayvan ilanlarını harita üzerinde sunabilmelidir.

## 9. İşlevsel Olmayan Gereksinimler

1. Sistem internet üzerinden 7/24 erişilebilir olmalıdır.
2. API yanıt süreleri yoğun olmayan durumda kabul edilebilir seviyede olmalıdır.
3. Kullanıcı şifreleri güvenli biçimde hashlenerek saklanmalıdır.
4. Yetkisiz kullanıcılar korumalı kaynaklara erişememelidir.
5. Sistem mobil cihazlarda kullanılabilir ve anlaşılır bir arayüze sahip olmalıdır.
6. Veritabanı yedeklenebilir ve merkezi olarak yönetilebilir olmalıdır.
7. Gerçek zamanlı mesajlaşma gecikmesi düşük olmalıdır.
8. Sistem yeni modüller eklenecek şekilde ölçeklenebilir olmalıdır.

## 10. Aktörler
- Ziyaretçi
- Kayıtlı Kullanıcı
- Veteriner
- Pet Bakıcısı
- Satıcı
- Admin

## 11. Temel Kullanım Senaryoları

| Kod | Kullanım Senaryosu | Aktör |
|---|---|---|
| UC-01 | Sisteme kayıt olma | Ziyaretçi |
| UC-02 | Giriş yapma | Ziyaretçi/Kullanıcı |
| UC-03 | Evcil hayvan profili oluşturma | Kullanıcı |
| UC-04 | Sahiplendirme ilanı oluşturma | Kullanıcı |
| UC-05 | Sahiplendirme başvurusu yapma | Kullanıcı |
| UC-06 | Veteriner arama | Kullanıcı |
| UC-07 | Veteriner randevusu oluşturma | Kullanıcı |
| UC-08 | Aşı kaydı ekleme | Kullanıcı/Veteriner |
| UC-09 | Pet bakıcısı bulma | Kullanıcı |
| UC-10 | Bakıcı rezervasyonu oluşturma | Kullanıcı |
| UC-11 | Mesaj gönderme | Kullanıcı |
| UC-12 | Sepete ürün ekleme | Kullanıcı |
| UC-13 | Sipariş oluşturma | Kullanıcı |
| UC-14 | Ürün yönetme | Satıcı |
| UC-15 | İçerik ve kullanıcı denetleme | Admin |

## 12. Detaylı Kullanım Senaryoları

### UC-07: Veteriner Randevusu Oluşturma
- Amaç: Kullanıcının uygun veteriner için randevu alması
- Ön Koşul: Kullanıcı giriş yapmış olmalıdır
- Tetikleyici: Kullanıcının veteriner detay ekranında "Randevu Al" seçeneğine basması

#### Ana Akış
1. Kullanıcı veteriner arama ekranını açar.
2. Sistem kullanıcının konumuna göre veteriner listesini gösterir.
3. Kullanıcı bir veteriner seçer.
4. Sistem uygun tarih ve saatleri listeler.
5. Kullanıcı tarih, saat ve evcil hayvan seçimini yapar.
6. Sistem randevu kaydını oluşturur.
7. Sistem kullanıcıya onay mesajı gösterir.

#### Alternatif Akış
1. Uygun saat yoksa sistem başka tarih önerir.
2. Kullanıcı oturumu geçersizse sistem tekrar giriş ister.

#### Sonuç
- Randevu beklemede durumunda sisteme kaydedilir.

### UC-10: Bakıcı Rezervasyonu Oluşturma
- Amaç: Kullanıcının pet bakıcısı için rezervasyon oluşturması
- Ön Koşul: Kullanıcı giriş yapmış olmalıdır

#### Ana Akış
1. Kullanıcı bakıcı listesini görüntüler.
2. Kullanıcı bir bakıcı profili seçer.
3. Sistem hizmet tipleri ve uygun tarihleri gösterir.
4. Kullanıcı hizmet, tarih aralığı ve not bilgisi girer.
5. Sistem rezervasyon kaydını oluşturur.
6. Sistem bakıcıya bildirim gönderir.

#### Sonuç
- Rezervasyon beklemede durumunda oluşturulur.

### UC-13: Sipariş Oluşturma
- Amaç: Kullanıcının mağaza ürünlerini satın alması
- Ön Koşul: Kullanıcının adres bilgisi bulunmalıdır

#### Ana Akış
1. Kullanıcı ürünleri görüntüler.
2. Kullanıcı ürünü sepete ekler.
3. Kullanıcı sepet ekranına gider.
4. Kullanıcı teslimat adresini seçer.
5. Kullanıcı siparişi onaylar.
6. Sistem siparişi ve sipariş kalemlerini veritabanına kaydeder.
7. Sistem satıcıya sipariş bildirimi gönderir.

### UC-15: İçerik ve Kullanıcı Denetleme
- Amaç: Adminin sistem güvenliğini ve içerik kalitesini koruması
- Ön Koşul: Admin yetkisi ile giriş yapılmış olmalıdır

#### Ana Akış
1. Admin panelde raporlanan içerikleri görüntüler.
2. Admin kullanıcı, ilan veya paylaşım detayını inceler.
3. Gerekirse içerik kaldırma, kullanıcı uyarma veya hesabı kısıtlama işlemi yapar.
4. Sistem denetim kaydı oluşturur.

## 13. Analiz ve Tasarım Sınıfları

### Temel Varlık Sınıfları
- User
- Pet
- Veterinary
- Appointment
- VaccinationRecord
- PetSitter
- SitterBooking
- Store
- Product
- Order
- Conversation
- Message
- AdoptionApplication

### Kontrol Sınıfları
- AuthController
- AppointmentController
- PetSitterController
- OrderController
- MessageController
- AdminController

### Sınır Sınıfları
- Mobile App Screens
- Admin Panel Screens
- Seller Panel Screens
- REST API Endpoints

## 14. Diyagram Listesi

Bu klasörde aşağıdaki UML diyagram taslakları bulunmaktadır:

- `use_case_diagram.puml`
- `deployment_diagram.puml`
- `class_diagram.puml`
- `sequence_vet_appointment.puml`

## 15. Teslim İçin Önerilen Rapor Bölümleri

1. Kapak
2. İçindekiler
3. Giriş
4. Problem Tanımı
5. Proje Amacı ve Kapsamı
6. Paydaş Analizi
7. Gereksinim Analizi
8. İşlevsel ve İşlevsel Olmayan Gereksinimler
9. Kullanım Senaryoları
10. UML Diyagramları
11. Veritabanı Tasarımı
12. Mimari Tasarım
13. Proje Ekibi ve Görev Dağılımı
14. Varsayımlar ve Kısıtlar
15. Sonuç

## 16. Son Not

Bu proje, mevcut haliyle ders ödevi için zayıf değil; tersine kapsam olarak güçlü. Asıl kritik nokta, projeyi "uygulama tanıtımı" gibi değil "yazılım mühendisliği analizi ve modelleme dokümanı" gibi sunmaktır. Bu nedenle raporda ekran görüntülerinden önce gereksinim modeli, kullanım senaryoları, ekip yapısı, mimari ve UML çıktıları yer almalıdır.
