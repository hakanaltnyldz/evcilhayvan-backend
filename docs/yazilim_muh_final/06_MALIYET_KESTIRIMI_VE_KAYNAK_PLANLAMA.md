# Ek D: Maliyet Kestirimi, Kaynak Planlama ve İş-Zaman Planı

## 1. Amaç

Bu bölüm, Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu projesinin planlama aşamasında ele alınması gereken maliyet, kaynak, süre ve iş gücü değerlendirmelerini sunar. Önceki örnek raporlarda görülen COCOMO, işlev noktası, ekip yapısı ve iş-zaman planı yaklaşımı bu projeye uyarlanmıştır.

Buradaki sayısal değerler akademik proje varsayımıdır. Amaç, gerçek ticari ihale bedeli çıkarmak değil; yazılım mühendisliği planlama mantığını göstermek ve projenin büyüklüğünü ölçülebilir hale getirmektir.

---

## 2. Proje Büyüklüğünün Değerlendirilmesi

Bu proje klasik tek modüllü bir otomasyon değildir. Mobil istemci, backend API, gerçek zamanlı mesajlaşma, admin paneli, satıcı paneli, bulut veritabanı ve dış servis entegrasyonları birlikte çalışmaktadır. Bu nedenle proje karmaşıklığı orta-yüksek seviyede kabul edilmiştir.

### 2.1 Ana Modül Sayısı

| Modül | Açıklama |
|---|---|
| Kimlik doğrulama | Kayıt, giriş, token, rol kontrolü |
| Pet yönetimi | Pet profili, ilan, favori |
| Sahiplendirme | İlan ve başvuru akışları |
| Eşleştirme | Çiftleştirme ve match istekleri |
| Mesajlaşma | REST + Socket.io tabanlı iletişim |
| Veteriner | Yakın veteriner arama, detay, yorum |
| Randevu | Slot, randevu, durum yönetimi |
| Aşı ve sağlık | Aşı takvimi, sağlık günlüğü |
| Pet bakıcı | Bakıcı profili, rezervasyon, canlı takip |
| Kayıp/bulunan | Konum tabanlı kayıp ilanları |
| Sosyal akış | Gönderi, beğeni, yorum |
| Etkinlik | Etkinlik oluşturma ve katılım |
| Mağaza | Ürün, kategori, sepet, sipariş |
| Satıcı paneli | Ürün, sipariş, kupon, mağaza yönetimi |
| Admin paneli | Kullanıcı, içerik, rapor, başvuru denetimi |

Bu yapı, projenin ders ödevi için oldukça kapsamlı olduğunu ve maliyet/süre planının tek ekranlı bir uygulamadan farklı ele alınması gerektiğini göstermektedir.

---

## 3. İşlev Noktası Yaklaşımı

İşlev noktası yöntemi, yazılımın büyüklüğünü kod satırına bağımlı kalmadan değerlendirmek için kullanılır. Bu projede aşağıdaki varsayımsal sayımlar yapılmıştır:

| Ölçüm Parametresi | Sayı | Karmaşıklık | Ağırlık | Katkı |
|---|---:|---|---:|---:|
| Dış Girdiler | 95 | Ortalama | 4 | 380 |
| Dış Çıktılar | 45 | Ortalama | 5 | 225 |
| Dış Sorgular | 60 | Ortalama | 4 | 240 |
| İç Mantıksal Dosyalar | 40 | Ortalama | 10 | 400 |
| Dış Arayüz Dosyaları | 6 | Ortalama | 7 | 42 |
| Toplam | 246 |  |  | 1287 |

Ayarlanmamış işlev noktası sayısı:

```text
AIN = 1287
```

### 3.1 Teknik Karmaşıklık Faktörü

Teknik karmaşıklık; dağıtık çalışma, performans, çevrim içi veri girişi, güvenlik, tekrar kullanılabilirlik ve dış servis entegrasyonları dikkate alınarak değerlendirilmiştir.

| Teknik Faktör | Puan |
|---|---:|
| Veri iletişimi gereksinimi | 5 |
| Dağıtık işlem yapısı | 5 |
| Performans hassasiyeti | 4 |
| Çevrim içi veri girişi | 5 |
| Ana verilerin çevrim içi güncellenmesi | 5 |
| Karmaşık sorgular ve filtreleme | 4 |
| Yeniden kullanılabilir bileşenler | 3 |
| Kurulum ve geçiş kolaylığı | 3 |
| Kullanım kolaylığı | 4 |
| Güvenlik gereksinimi | 5 |
| Bildirim ve gerçek zamanlı iletişim | 4 |
| Çoklu rol ve yetki yapısı | 4 |
| Mobil ve web istemci çeşitliliği | 4 |
| Bakım ve genişletilebilirlik | 4 |
| Toplam Teknik Faktör | 59 |

Ayarlama katsayısı:

```text
VAF = 0.65 + (0.01 x 59)
VAF = 1.24
```

Ayarlanmış işlev noktası:

```text
FP = 1287 x 1.24
FP = 1595.88 ≈ 1596
```

### 3.2 Yorum

Bu değer, projenin akademik bir mikro proje olmadığını gösterir. Tam ticari kapsamda değerlendirildiğinde proje orta-yüksek büyüklükte bir platformdur. Ancak ders tesliminde kodlama yapılmayacağı ve modelleme/dokümantasyon esas olduğu için bu büyüklük raporda kapsamlı analiz avantajı sağlar.

---

## 4. COCOMO Yaklaşımı

COCOMO modeli, yazılım geliştirme eforunu tahmin etmek için kullanılır. Bu proje dağıtık, çok modüllü ve farklı istemciler içeren bir sistem olduğu için "yarı gömülü / semi-detached" karaktere yakın kabul edilmiştir. Ancak akademik rapor kapsamında iki ayrı değerlendirme yapılmıştır:

1. Tam ticari ürün kapsamı
2. Ders projesi ve modelleme kapsamı

### 4.1 Tam Ticari Ürün Varsayımı

İşlev noktası ve mevcut modül yoğunluğu dikkate alınarak yaklaşık kod satırı karşılığı:

```text
Tahmini LOC = 60.000
KLOC = 60
```

Semi-detached COCOMO katsayıları:

```text
Effort = 3.0 x KLOC^1.12
Effort = 3.0 x 60^1.12
Effort ≈ 294 kişi-ay
```

Tahmini geliştirme süresi:

```text
Duration = 2.5 x Effort^0.35
Duration ≈ 18 ay
```

Ortalama ekip büyüklüğü:

```text
Team Size = Effort / Duration
Team Size ≈ 16 kişi
```

Bu değer, uygulamanın tüm modülleriyle ticari üretim kalitesinde hazırlanması halinde büyük ekip ve uzun süre gerektireceğini gösterir.

### 4.2 Ders Projesi ve Analiz Kapsamı Varsayımı

Bu final ödevi kapsamında kodlama yapılmayacağı için iş gücü ağırlığı analiz, modelleme, dokümantasyon, diyagram ve test planına kayar. Bu nedenle akademik iş gücü daha düşük hesaplanır:

| İş Paketi | Tahmini Kişi-Gün |
|---|---:|
| Problem ve kapsam analizi | 5 |
| Gereksinim analizi | 7 |
| Use case ve sözleşmeler | 8 |
| UML ve mimari modelleme | 8 |
| Veri sözlüğü ve veri tasarımı | 6 |
| Test, risk ve plan dokümanları | 6 |
| Rapor düzenleme ve Word teslimi | 8 |
| Toplam | 48 kişi-gün |

Akademik modelde tek öğrenci çalışması için bu süre, yoğunluk durumuna göre 3-5 haftalık çalışma aralığına denk gelir.

---

## 5. Kaynak Planı

### 5.1 İnsan Kaynakları

Ödev bireysel teslim edilecek olsa da proje organizasyonu ders şartına uygun şekilde en az 6 personel içerecek biçimde modellenmiştir.

| Rol | Sorumluluk | Tahmini Katkı |
|---|---|---:|
| Proje Yöneticisi | Plan, kapsam, koordinasyon | %12 |
| İş/Sistem Analisti | Gereksinim, use case, iş kuralları | %16 |
| Backend Geliştirici | API, güvenlik, socket, servisler | %18 |
| Mobil Geliştirici | Flutter ekranları ve mobil akışlar | %18 |
| Web Panel Geliştiricisi | Admin ve satıcı paneli | %12 |
| Veritabanı ve DevOps Uzmanı | DB, deploy, izleme, yedekleme | %12 |
| Test ve Kalite Uzmanı | Test planı, kabul kriterleri | %12 |

### 5.2 Donanım Kaynakları

| Kaynak | Kullanım Amacı |
|---|---|
| Geliştirici bilgisayarı | Kod, test, dokümantasyon |
| Android test cihazı | Mobil uygulama testleri |
| Android emülatör | Farklı ekran testleri |
| Bulut uygulama sunucusu | Backend yayınlama |
| Bulut veritabanı | MongoDB Atlas veri saklama |
| Dosya depolama alanı | Görsel ve medya dosyaları |

### 5.3 Yazılım Kaynakları

| Yazılım / Araç | Amaç |
|---|---|
| Flutter SDK | Mobil uygulama geliştirme |
| Dart | Mobil programlama dili |
| Node.js | Backend çalışma ortamı |
| Express.js | REST API geliştirme |
| MongoDB Atlas | Bulut veritabanı |
| Mongoose | ODM ve veri modeli |
| Socket.io | Gerçek zamanlı iletişim |
| Firebase FCM | Bildirim altyapısı |
| React / Vite | Web panel geliştirme |
| Git / GitHub | Sürüm kontrolü |
| Postman / Swagger | API test ve dokümantasyon |
| PlantUML / Mermaid | Diyagram ve grafik hazırlama |

---

## 6. Maliyet Varsayımı

Bu bölümde ticari ekip ile 6 aylık prototip ve raporlama dönemi varsayılmıştır. Rakamlar akademik örnekleme içindir.

| Kalem | Aylık Tahmini Maliyet | Süre | Toplam |
|---|---:|---:|---:|
| Proje yöneticisi | 60.000 TL | 6 ay | 360.000 TL |
| Analist | 55.000 TL | 5 ay | 275.000 TL |
| Backend geliştirici | 70.000 TL | 6 ay | 420.000 TL |
| Mobil geliştirici | 70.000 TL | 6 ay | 420.000 TL |
| Web panel geliştirici | 60.000 TL | 4 ay | 240.000 TL |
| DB/DevOps uzmanı | 65.000 TL | 4 ay | 260.000 TL |
| Test uzmanı | 50.000 TL | 3 ay | 150.000 TL |
| Bulut servisleri | 10.000 TL | 6 ay | 60.000 TL |
| Test cihazları ve araçlar | 75.000 TL | 1 kez | 75.000 TL |
| Dokümantasyon ve eğitim | 40.000 TL | 1 kez | 40.000 TL |
| Toplam |  |  | 2.300.000 TL |

### 6.1 Maliyet Dağılımı Yorumu

En büyük maliyet kalemi insan kaynağıdır. Bunun nedeni sistemin birden fazla uzmanlık alanına ihtiyaç duymasıdır. Backend, mobil uygulama, panel, veritabanı, test ve operasyon süreçleri farklı yetkinlikler gerektirir. Bulut maliyetleri erken aşamada insan kaynağına göre düşük kalsa da kullanıcı sayısı, medya kullanımı ve bildirim hacmi arttıkça büyüyebilir.

---

## 7. İş-Zaman Planı

### 7.1 Faz Bazlı Plan

| Faz | Tarih Aralığı | Süre | Çıktı |
|---|---|---:|---|
| Planlama | 02.04.2026 - 07.04.2026 | 6 gün | Kapsam, ekip, yöntem |
| Analiz | 08.04.2026 - 16.04.2026 | 9 gün | Gereksinimler, aktörler |
| Mantıksal Model | 17.04.2026 - 25.04.2026 | 9 gün | Use case, veri modeli |
| Tasarım | 26.04.2026 - 03.05.2026 | 8 gün | Mimari, sınıf, sequence |
| Test ve Risk Planı | 04.05.2026 - 08.05.2026 | 5 gün | Test, risk, kabul kriterleri |
| Raporlama | 09.05.2026 - 12.05.2026 | 4 gün | Word raporu, ekler |
| Teslim Kontrolü | 13.05.2026 | 1 gün | Son teslim |

### 7.2 Kritik Yol

Kritik yol aşağıdaki sırayı izler:

1. Kapsam belirleme
2. Gereksinim analizi
3. Use case ve iş kuralları
4. Veri modeli
5. Mimari tasarım
6. Test ve risk planı
7. Rapor düzenleme

Bu sırada özellikle gereksinim analizi tamamlanmadan doğru UML ve test planı üretilemez. Bu nedenle analiz aşaması projenin en kritik aşamasıdır.

---

## 8. İş Paketleri ve Teslim Çıktıları

| İş Paketi | Teslim Çıktısı |
|---|---|
| Proje tanımı | Problem, amaç, kapsam |
| Gereksinim analizi | FR/NFR listesi |
| Use case | Use case diyagramı ve sözleşmeleri |
| Veri modeli | Veri sözlüğü, ER/MongoDB view diyagramı |
| Mimari model | Deployment ve component diyagramları |
| Dinamik model | Sequence, activity ve state diyagramları |
| Test planı | Test senaryoları ve kabul ölçütleri |
| Risk planı | Risk matrisi |
| Maliyet planı | FP/COCOMO ve maliyet tablosu |
| Teslim raporu | Word formatlı final dokümanı |

---

## 9. Grafik Olarak Kullanılacak Veriler

Bu bölümdeki tablolar aşağıdaki grafiklere dönüştürülmelidir:

- Rol bazlı iş gücü dağılımı
- Maliyet kalemleri dağılımı
- Faz bazlı süre dağılımı
- Modül kapsam yoğunluğu

Bu grafikler için kaynak dosyalar ayrıca `charts` klasöründe hazırlanmıştır.
