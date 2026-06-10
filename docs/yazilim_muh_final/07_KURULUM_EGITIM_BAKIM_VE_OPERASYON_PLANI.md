# Ek E: Kurulum, Eğitim, Bakım ve Operasyon Planı

## 1. Amaç

Bu bölüm, sistemin geliştirme ve analiz aşamasından sonra nasıl kurulacağını, kimlere nasıl eğitim verileceğini, bakım sürecinin nasıl yürütüleceğini ve operasyonel devamlılığın nasıl sağlanacağını açıklar. Önceki proje raporlarında yer alan eğitim ve bakım planı yaklaşımı bu projeye uyarlanmıştır.

---

## 2. Kurulum Planı

### 2.1 Kurulum Ortamları

Sistem üç ana ortam üzerinden ele alınmalıdır:

| Ortam | Amaç |
|---|---|
| Geliştirme ortamı | Kodlama, lokal test ve hata ayıklama |
| Test ortamı | Entegrasyon, kullanıcı kabul ve regresyon testleri |
| Canlı ortam | Son kullanıcıların eriştiği üretim sistemi |

### 2.2 Backend Kurulumu

Backend kurulumu için gereken adımlar:

1. Node.js ortamı hazırlanır.
2. Ortam değişkenleri tanımlanır.
3. MongoDB Atlas bağlantısı doğrulanır.
4. JWT ve güvenlik anahtarları oluşturulur.
5. Upload dizini veya medya depolama servisi hazırlanır.
6. Firebase veya bildirim servisi bağlantısı tanımlanır.
7. API sağlık kontrolü yapılır.

### 2.3 Mobil Uygulama Kurulumu

Mobil uygulama kurulumu için gereken adımlar:

1. Flutter SDK hazırlanır.
2. API base URL değeri doğru ortama göre ayarlanır.
3. Android build ayarları kontrol edilir.
4. Firebase yapılandırması doğrulanır.
5. Debug veya release APK alınır.
6. Gerçek cihaz üzerinde giriş, listeleme ve bildirim test edilir.

### 2.4 Web Panel Kurulumu

Admin ve satıcı panelleri için:

1. Bağımlılıklar kurulur.
2. API URL yapılandırması yapılır.
3. Yetkili kullanıcı hesapları oluşturulur.
4. Panelde kullanıcı, ürün, sipariş ve rapor ekranları test edilir.

### 2.5 Veritabanı Kurulumu

Veritabanı tarafında:

1. MongoDB Atlas cluster hazırlanır.
2. Kullanıcı ve bağlantı izinleri tanımlanır.
3. Koleksiyonlar uygulama tarafından oluşturulur.
4. Gerekli indeksler kontrol edilir.
5. Test verileri eklenir.
6. Yedekleme politikası belirlenir.

---

## 3. Eğitim Planı

### 3.1 Eğitim Verilecek Gruplar

| Grup | Eğitim İçeriği |
|---|---|
| Son kullanıcı | Kayıt, pet ekleme, ilan, randevu, sipariş |
| Veteriner | Klinik profili, randevu, sağlık kayıtları |
| Pet bakıcısı | Profil, rezervasyon, hizmet süreci |
| Satıcı | Mağaza, ürün, sipariş, kupon |
| Admin | Kullanıcı, içerik, rapor, moderasyon |
| Teknik ekip | Deploy, log, yedekleme, hata analizi |

### 3.2 Eğitim Yöntemi

Eğitim üç biçimde verilebilir:

1. Kısa kullanım kılavuzu
2. Ekran görüntülü adım adım doküman
3. Uygulamalı demo oturumu

### 3.3 Eğitim Süresi

| Eğitim | Süre |
|---|---:|
| Son kullanıcı eğitimi | 1 saat |
| Satıcı eğitimi | 2 saat |
| Admin eğitimi | 3 saat |
| Teknik ekip eğitimi | 4 saat |

### 3.4 Eğitim Başarı Ölçütleri

- Kullanıcı kendi hesabını açabilmeli
- Kullanıcı pet profili oluşturabilmeli
- Kullanıcı randevu veya rezervasyon oluşturabilmeli
- Satıcı ürün ekleyebilmeli
- Admin raporlanan içeriği inceleyebilmeli
- Teknik ekip sağlık kontrolü ve log takibi yapabilmeli

---

## 4. Bakım Planı

### 4.1 Bakım Türleri

| Bakım Türü | Açıklama |
|---|---|
| Düzeltici bakım | Hataların giderilmesi |
| Uyarlayıcı bakım | Yeni işletim sistemi, API veya servis değişikliklerine uyum |
| İyileştirici bakım | Performans ve kullanıcı deneyimi geliştirmeleri |
| Önleyici bakım | Hata oluşmadan risklerin azaltılması |

### 4.2 Bakım Süreci

1. Hata veya talep kaydı açılır.
2. Öncelik ve etki analizi yapılır.
3. Sorumlu kişi atanır.
4. Çözüm geliştirilir.
5. Test ortamında doğrulanır.
6. Canlı ortama kontrollü aktarılır.
7. Değişiklik kayıt altına alınır.

### 4.3 Bakım Öncelik Seviyeleri

| Seviye | Açıklama | Müdahale Süresi |
|---|---|---:|
| Kritik | Sistem kullanılamıyor veya güvenlik açığı var | 4 saat |
| Yüksek | Temel işlem yapılamıyor | 1 iş günü |
| Orta | Alternatif yol var ama kullanıcı etkileniyor | 3 iş günü |
| Düşük | Kozmetik veya iyileştirme talebi | Planlı sürüm |

---

## 5. Operasyon Planı

### 5.1 İzlenecek Göstergeler

| Gösterge | Neden Önemli |
|---|---|
| API yanıt süresi | Performans takibi |
| 5xx hata oranı | Sunucu kararlılığı |
| Başarısız giriş sayısı | Güvenlik takibi |
| Socket bağlantı sayısı | Gerçek zamanlı iletişim yükü |
| Bildirim başarı oranı | FCM verimliliği |
| Sipariş tamamlama oranı | Ticari akış sağlığı |
| Randevu iptal oranı | Hizmet kalitesi |

### 5.2 Loglama

Loglanması gereken olaylar:

- Giriş denemeleri
- Rol ve yetki değişiklikleri
- Admin işlemleri
- Sipariş durum değişiklikleri
- Randevu durum değişiklikleri
- Rezervasyon durum değişiklikleri
- Kritik API hataları

### 5.3 Yedekleme Planı

| Veri | Yedekleme Sıklığı |
|---|---|
| Kullanıcı ve pet verileri | Günlük |
| Sipariş ve ödeme benzeri kayıtlar | Günlük |
| Mesaj ve konuşmalar | Günlük |
| Dosya yüklemeleri | Haftalık |
| Konfigürasyonlar | Her değişiklikte |

### 5.4 Felaket Kurtarma

Sistem kesintisi veya veri kaybı durumunda:

1. Sorunun kapsamı belirlenir.
2. Son sağlıklı yedek tespit edilir.
3. Veri geri yükleme işlemi yapılır.
4. API sağlık kontrolü çalıştırılır.
5. Admin ve teknik ekip bilgilendirilir.
6. Olay sonrası kök neden analizi yapılır.

---

## 6. Entegrasyon Planı

### 6.1 Entegre Edilecek Servisler

| Servis | Amaç |
|---|---|
| MongoDB Atlas | Merkezi veri saklama |
| Firebase FCM | Bildirim gönderimi |
| Google Places | Veteriner/konum arama |
| Socket.io | Anlık mesajlaşma ve olay yayını |
| Upload servisi | Görsel ve medya yönetimi |

### 6.2 Entegrasyon Riskleri

- Dış servis erişim hatası
- API anahtarının geçersiz olması
- Kota sınırı
- Ağ gecikmesi
- Yanlış ortam değişkeni

### 6.3 Entegrasyon Testleri

| Test | Beklenen Sonuç |
|---|---|
| MongoDB bağlantı testi | API veri okuyup yazabilmeli |
| FCM test bildirimi | Cihaza bildirim düşmeli |
| Google Places araması | Konuma göre sonuç gelmeli |
| Socket bağlantısı | Kullanıcı çevrim içi görünmeli |
| Upload testi | Görsel yüklenip URL dönmeli |

---

## 7. Güvenlik Operasyonu

### 7.1 Periyodik Kontroller

- Yetkisiz erişim logları incelenir.
- Admin hesapları kontrol edilir.
- Ortam değişkenleri ve anahtarlar yenilenir.
- Rate limit kayıtları değerlendirilir.
- Şüpheli kullanıcı davranışları raporlanır.

### 7.2 Kullanıcı Verisi Koruma

Kullanıcı verilerinin korunması için:

- Gereksiz veri toplanmamalıdır.
- Hassas veri loglara yazılmamalıdır.
- Silme ve hesap kapatma talepleri süreçle yönetilmelidir.
- Erişim rolleri düzenli gözden geçirilmelidir.

---

## 8. Sürümleme ve Yayın Planı

| Sürüm | İçerik |
|---|---|
| v0.1 | Temel auth, pet ve ilan modeli |
| v0.2 | Mesajlaşma ve sahiplendirme |
| v0.3 | Veteriner ve randevu |
| v0.4 | Bakıcı ve rezervasyon |
| v0.5 | Mağaza ve sipariş |
| v0.6 | Admin/satıcı paneli |
| v1.0 | Test edilmiş bütünleşik MVP |

### 8.1 Yayın Öncesi Kontrol Listesi

- API health endpoint çalışıyor
- Mobil uygulama giriş yapabiliyor
- Randevu ve sipariş akışları test edildi
- Admin panel erişimi kontrol edildi
- Veritabanı bağlantısı doğrulandı
- Bildirim testi yapıldı
- Rollback planı hazır

---

## 9. Sonuç

Kurulum, eğitim, bakım ve operasyon planı; projenin yalnızca analiz edilen bir fikir değil, gerçek dünyada sürdürülebilir biçimde çalışabilecek bir yazılım sistemi olarak düşünüldüğünü gösterir. Özellikle dağıtık sistemlerde kurulum ve bakım adımlarının raporda bulunması, yazılım mühendisliği bakışını güçlendirir.
