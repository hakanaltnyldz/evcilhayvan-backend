# Ek B: Test, Risk, Planlama ve Proje Yönetimi Ekleri

## 1. Amaç

Bu ek doküman, ana raporun yönetimsel ve kalite boyutunu güçlendirmek amacıyla hazırlanmıştır. Yazılım mühendisliği proje raporlarında yalnızca neyin yapılacağı değil, bunun nasıl test edileceği, hangi risklerin yönetileceği, işin nasıl planlanacağı ve başarı ölçümünün nasıl yapılacağı da gösterilmelidir. Bu nedenle bu dokümanda aşağıdaki başlıklar yer almaktadır:

- İş kırılım yapısı
- Zaman planı
- Sprint bazlı ilerleme önerisi
- RACI matrisi
- Risk yönetimi
- Test stratejisi
- Örnek test senaryoları
- Kullanıcı hikâyeleri ve backlog
- Kalite ölçütleri
- Değişiklik yönetimi

---

## 2. İş Kırılım Yapısı (WBS)

### 2.1 Seviye 1

1. Proje Başlatma
2. Analiz ve Gereksinim Yönetimi
3. Mimari ve Tasarım
4. Mobil Uygulama Geliştirme
5. Backend Geliştirme
6. Web Paneller Geliştirme
7. Test ve Kalite Güvence
8. Dağıtım ve Operasyon
9. Dokümantasyon ve Teslim

### 2.2 Seviye 2 Ayrıntısı

| WBS Kodu | İş Paketi | Açıklama |
|---|---|---|
| 1.1 | Proje konusu netleştirme | Alan seçimi, kapsam belirleme |
| 1.2 | Paydaş tanımlama | Aktörlerin ve rollerin belirlenmesi |
| 2.1 | Gereksinim toplama | İşlevsel ve işlevsel olmayan gereksinimler |
| 2.2 | Use case hazırlama | Senaryo ve sözleşmeler |
| 2.3 | İş kuralları tanımı | Alan kısıtları ve kurallar |
| 3.1 | Mimari tasarım | Dağıtım, katman ve bileşen yapısı |
| 3.2 | Veri tasarımı | Varlıklar, ilişkiler, indeksler |
| 3.3 | Arayüz tasarımı | Mobil ve panel ekran akışları |
| 4.1 | Kimlik ve profil modülü | Mobil istemci çekirdek akışları |
| 4.2 | Veteriner modülü | Arama, detay, randevu |
| 4.3 | Bakıcı modülü | Profil, rezervasyon, durum takibi |
| 4.4 | Mağaza modülü | Ürün, sepet, sipariş |
| 4.5 | Sosyal modüller | Mesaj, gönderi, etkinlik |
| 5.1 | Auth API | Giriş, token, yetkilendirme |
| 5.2 | Pet ve ilan API | Pet CRUD, başvuru akışları |
| 5.3 | Hizmet API'leri | Randevu, aşı, bakıcı |
| 5.4 | Ticaret API'leri | Sipariş, kupon, ürün |
| 6.1 | Admin paneli | Moderasyon ve operasyon |
| 6.2 | Satıcı paneli | Ürün ve sipariş yönetimi |
| 7.1 | Birim test | Servis ve kontrol seviyeleri |
| 7.2 | Entegrasyon test | API ve modül etkileşimi |
| 7.3 | Kabul testi | İş senaryosu bazlı test |
| 8.1 | Deploy hazırlığı | Ortam değişkenleri, sunucu |
| 8.2 | İzleme | Log, bildirim, hata takibi |
| 9.1 | Final raporu | Word teslim dosyası |
| 9.2 | Ekler ve diyagramlar | UML, test tabloları, ekranlar |

---

## 3. Zaman Planı

### 3.1 Önerilen Faz Planı

| Faz | Süre | Çıktı |
|---|---|---|
| Faz 1 | 1 hafta | Problem, kapsam, paydaş analizi |
| Faz 2 | 1 hafta | Gereksinim listesi, use case, iş kuralları |
| Faz 3 | 1 hafta | Mimari, veri modeli, diyagramlar |
| Faz 4 | 2 hafta | Ana modüllerin gerçeklenmesi/kanıtlanması |
| Faz 5 | 1 hafta | Test, hata düzeltme, kalite kontrol |
| Faz 6 | 1 hafta | Son rapor, ekler, teslim paketi |

### 3.2 Sprint Tabanlı Planlama

| Sprint | Hedef |
|---|---|
| Sprint 1 | Auth, profil ve pet modülleri |
| Sprint 2 | Sahiplendirme ve eşleştirme |
| Sprint 3 | Mesajlaşma ve sosyal modüller |
| Sprint 4 | Veteriner, aşı ve sağlık |
| Sprint 5 | Bakıcı rezervasyonu ve canlı süreçler |
| Sprint 6 | Mağaza, sipariş, admin, seller ve kalite |

### 3.3 Kilometre Taşları

1. Gereksinimlerin dondurulması
2. Temel mimarinin onaylanması
3. Çekirdek modüllerin tamamlanması
4. Çok modüllü entegrasyonun görülmesi
5. Test ve düzeltme
6. Rapor ve teslim

---

## 4. RACI Matrisi

| İş Alanı | Proje Yöneticisi | Analist | Backend | Mobil | Web Panel | DB/DevOps | Test Uzmanı |
|---|---|---|---|---|---|---|---|
| Kapsam belirleme | A | R | C | C | C | C | C |
| Gereksinim yazımı | A | R | C | C | C | C | C |
| UML modelleme | C | R | C | C | C | C | C |
| API tasarımı | C | C | R | C | C | C | C |
| Mobil ekranlar | C | C | C | R | C | C | C |
| Admin/seller panel | C | C | C | C | R | C | C |
| Veritabanı tasarımı | C | C | C | C | C | R | C |
| Test planı | C | C | C | C | C | C | R |
| Dağıtım | C | C | C | C | C | R | C |

`R`: Responsible, `A`: Accountable, `C`: Consulted

---

## 5. Risk Yönetimi

### 5.1 Risk Tanımlama Yaklaşımı

Dağıtık sistemlerde riskler yalnızca kod hataları ile sınırlı değildir. Aşağıdaki alanlar birlikte değerlendirilmelidir:

- Teknik riskler
- Operasyonel riskler
- Güvenlik riskleri
- Takvim riskleri
- Kapsam sürünmesi
- Kullanılabilirlik riskleri

### 5.2 Risk Matrisi

| Risk Kodu | Risk Tanımı | Olasılık | Etki | Önlem |
|---|---|---|---|---|
| R-01 | Gereksinimlerin sık değişmesi | Orta | Yüksek | Kapsam dondurma ve değişiklik yönetimi |
| R-02 | Modüller arası entegrasyon hataları | Yüksek | Yüksek | Erken entegrasyon ve API sözleşmeleri |
| R-03 | Yetkilendirme açığı | Orta | Çok Yüksek | Rol bazlı erişim ve güvenlik testleri |
| R-04 | Veritabanı performans sorunu | Orta | Yüksek | İndeksleme ve sorgu incelemesi |
| R-05 | Konum servislerinde hata | Orta | Orta | Manuel konum fallback |
| R-06 | Bildirimlerin ulaşmaması | Orta | Orta | Retry ve kullanıcı içi durum ekranları |
| R-07 | Socket bağlantı kopmaları | Yüksek | Orta | Yeniden bağlanma ve offline fallback |
| R-08 | Medya yükleme problemleri | Orta | Orta | Dosya boyutu ve tür doğrulaması |
| R-09 | Takvim çakışma hataları | Orta | Yüksek | Çift taraflı uygunluk doğrulaması |
| R-10 | Stok ve sipariş tutarsızlığı | Orta | Yüksek | İşlem sırası ve sunucu tarafı doğrulama |
| R-11 | Uygunsuz içerik yayını | Orta | Yüksek | Moderasyon kuyruğu ve raporlama |
| R-12 | Kullanıcı verisi sızıntısı | Düşük | Çok Yüksek | Şifreleme, log denetimi, erişim sınırı |
| R-13 | Sunucu kesintisi | Düşük | Yüksek | Sağlık kontrolü ve yedekleme planı |
| R-14 | Kapsamın aşırı büyümesi | Yüksek | Orta | Önceliklendirme ve fazlama |
| R-15 | Teslim öncesi dokümantasyon eksikliği | Orta | Yüksek | Belge üretimini erken başlatma |

### 5.3 En Kritik Riskler

Bu proje özelinde en kritik riskler:

1. Yetkilendirme ve güvenlik açıkları
2. Randevu/rezervasyon çakışmaları
3. Çok modüllü yapının entegrasyon karmaşıklığı
4. Dokümantasyonun uygulama kapsamını yeterince yansıtamaması

---

## 6. Test Stratejisi

### 6.1 Test Seviyeleri

1. Birim test
2. Entegrasyon test
3. Sistem testi
4. Kullanıcı kabul testi
5. Regresyon testi

### 6.2 Test Kapsamı

- Kimlik doğrulama
- Yetkilendirme
- Pet ve ilan yönetimi
- Randevu ve takvim süreçleri
- Aşı ve sağlık kayıtları
- Bakıcı rezervasyonları
- Mesajlaşma
- Sipariş ve stok
- Moderasyon

### 6.3 Test Ortamı

- Geliştirme ortamı
- Test veritabanı
- Örnek kullanıcı rolleri
- Gerçek cihaz ve emülatör
- Panel için masaüstü tarayıcı

### 6.4 Test Veri Kümeleri

- Standart kullanıcı hesabı
- Admin hesabı
- Satıcı hesabı
- Veteriner hesabı
- Bakıcı hesabı
- Farklı türde pet kayıtları
- Stoklu/stoksuz ürünler
- Gelecek ve geçmiş tarihli rezervasyon örnekleri

---

## 7. Örnek Test Senaryoları

### 7.1 Kimlik ve Erişim Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-01 | Geçerli bilgilerle kayıt olma | Kullanıcı hesabı oluşturulur |
| T-02 | Aynı e-posta ile ikinci kayıt | Sistem hata verir |
| T-03 | Geçerli bilgilerle giriş | Token üretilir |
| T-04 | Yanlış parola ile giriş | Hata mesajı gösterilir |
| T-05 | Yetkisiz kullanıcı admin endpoint'ine erişir | 401/403 döner |

### 7.2 Pet ve İlan Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-06 | Zorunlu alanlarla pet ekleme | Pet kaydı oluşur |
| T-07 | Fotoğrafsız pet oluşturma | Kurala göre kabul veya uyarı |
| T-08 | Sahiplendirme ilanı oluşturma | İlan kaydedilir |
| T-09 | Kendi ilanına başvurma | Sistem engeller |
| T-10 | Aynı ilana iki kez başvurma | İkinci başvuru reddedilir |

### 7.3 Veteriner ve Sağlık Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-11 | Konumla veteriner arama | Yakın sonuçlar listelenir |
| T-12 | Boş slot için randevu alma | Randevu oluşturulur |
| T-13 | Dolu slot için randevu alma | Sistem yeni slot ister |
| T-14 | Aşı kaydı ekleme | Kayıt oluşur |
| T-15 | Geçersiz aşı tarihi girme | Sistem hatayı gösterir |

### 7.4 Bakıcı Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-16 | Bakıcı profili oluşturma | Profil kaydedilir |
| T-17 | Uygun tarihe rezervasyon oluşturma | Rezervasyon oluşur |
| T-18 | Çakışan tarihe rezervasyon | Sistem engeller |
| T-19 | Bakıcı rezervasyonu kabul eder | Durum güncellenir |
| T-20 | Aktif hizmette durum takibi | İlgili olaylar görünür |

### 7.5 Mesajlaşma ve Etkileşim Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-21 | Konuşma içinden mesaj gönderme | Mesaj kaydedilir ve iletilir |
| T-22 | Yetkisiz konuşmaya mesaj gönderme | Sistem engeller |
| T-23 | Alıcı çevrimdışı iken mesaj | Mesaj kaydedilir, bildirim atılır |
| T-24 | Gönderi beğenme | Sayaç artar |
| T-25 | Kullanıcıyı engelleme sonrası etkileşim | Kurallara göre kısıtlama uygulanır |

### 7.6 Mağaza ve Sipariş Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-26 | Ürünü sepete ekleme | Sepet güncellenir |
| T-27 | Yetersiz stokla sipariş verme | Sistem reddeder |
| T-28 | Geçerli kupon uygulama | Tutar güncellenir |
| T-29 | Geçersiz kupon uygulama | Hata gösterilir |
| T-30 | Sipariş oluşturma | Sipariş numarası oluşur |

### 7.7 Admin ve Moderasyon Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-31 | Admin moderasyon kuyruğunu açar | Veriler listelenir |
| T-32 | Raporlu içeriği kaldırma | İçerik pasif olur |
| T-33 | Kullanıcıyı kısıtlama | Hesap işlem sınırı alır |
| T-34 | Admin işlemi loglanır | Audit kaydı oluşur |
| T-35 | Admin dışı kullanıcı moderasyon endpoint'ine gider | Erişim reddedilir |

### 7.8 Regresyon ve Kullanılabilirlik Testleri

| Test ID | Senaryo | Beklenen Sonuç |
|---|---|---|
| T-36 | Tema değişimi sonrası ana ekran | Arayüz bozulmaz |
| T-37 | Dil değişimi sonrası kritik ekranlar | Metinler doğru görünür |
| T-38 | Ağ zayıfken liste ekranları | Boş/hata durumları anlaşılırdır |
| T-39 | Bildirimden ekran açma | Kullanıcı doğru modüle gider |
| T-40 | Oturum süresi dolmuş halde işlem | Kullanıcı yeniden girişe yönlendirilir |

---

## 8. Kullanıcı Hikâyeleri ve Backlog

### 8.1 Örnek Kullanıcı Hikâyeleri

| Hikâye ID | Kullanıcı Hikâyesi | Öncelik |
|---|---|---|
| US-01 | Bir kullanıcı olarak hesap açmak istiyorum ki uygulamayı kişisel verilerimle kullanabileyim | Must |
| US-02 | Bir kullanıcı olarak pet profili oluşturmak istiyorum ki hayvanıma ait kayıtlar sistemde tutulsun | Must |
| US-03 | Bir kullanıcı olarak sahiplendirme ilanı vermek istiyorum ki hayvanıma yuva bulabileyim | Must |
| US-04 | Bir kullanıcı olarak veterinerleri yakınlığa göre görmek istiyorum ki bana en uygun kliniği seçebileyim | Must |
| US-05 | Bir kullanıcı olarak randevu almak istiyorum ki kliniğe gitmeden planlama yapabileyim | Must |
| US-06 | Bir kullanıcı olarak aşı tarihimi kaydetmek istiyorum ki unutmayayım | Should |
| US-07 | Bir kullanıcı olarak bakıcı bulmak istiyorum ki seyahat dönemimde yardım alabileyim | Must |
| US-08 | Bir kullanıcı olarak bakıcı rezervasyonumu takip etmek istiyorum ki süreçten haberdar olayım | Should |
| US-09 | Bir kullanıcı olarak diğer kullanıcılarla mesajlaşmak istiyorum ki ayrıntıları konuşabileyim | Must |
| US-10 | Bir kullanıcı olarak ürün satın almak istiyorum ki ihtiyaçlarımı uygulamadan karşılayabileyim | Must |
| US-11 | Bir satıcı olarak ürün eklemek istiyorum ki mağazamda satış yapabileyim | Must |
| US-12 | Bir admin olarak raporlanan içeriği görmek istiyorum ki platformu güvenli tutabileyim | Must |
| US-13 | Bir kullanıcı olarak kayıp ilanı vermek istiyorum ki hayvanımı daha hızlı bulabileyim | Should |
| US-14 | Bir kullanıcı olarak etkinliğe katılmak istiyorum ki toplulukla etkileşim kurabileyim | Could |
| US-15 | Bir kullanıcı olarak bildirim tercihimi yönetmek istiyorum ki istemediğim bildirimleri kapatabileyim | Should |

### 8.2 Modül Bazlı Backlog

#### Auth ve Profil
- E-posta/parola ile kayıt
- Güvenli giriş
- Şifre sıfırlama
- Profil düzenleme
- Bildirim tercihleri

#### Veteriner ve Sağlık
- Yakın veteriner arama
- Veteriner detay
- Müsait slot sorgulama
- Randevu oluşturma
- Aşı takvimi
- Sağlık günlüğü

#### Bakıcı
- Bakıcı profili
- Hizmet türleri
- Rezervasyon oluşturma
- Durum takibi
- Geri bildirim/puanlama

#### Mağaza
- Ürün listeleme
- Filtreleme
- Sepet
- Kupon
- Sipariş oluşturma
- Sipariş izleme

---

## 9. Kalite Ölçütleri

### 9.1 İşlevsel Kalite

- Kritik kullanım senaryolarının başarıyla tamamlanması
- İş kurallarının doğru uygulanması
- Yetkisiz işlem yapılamaması

### 9.2 Kullanılabilirlik

- Kullanıcının temel görevleri az adımda tamamlaması
- Form ve hata mesajlarının anlaşılır olması
- Mobil cihazlarda akıcı deneyim

### 9.3 Güvenilirlik

- Aynı işlemin tekrarında tutarlı sonuç üretme
- Çökme veya veri kaybı yaşanmaması
- Ağ dalgalanmalarında kontrollü davranış

### 9.4 Performans

- Liste ve detay ekranlarında kabul edilebilir yanıt
- Bildirim ve mesaj gecikmesinin düşük olması

### 9.5 Sürdürülebilirlik

- Yeni modüllerin mevcut yapıyı bozmadan eklenebilmesi
- Kod ve dokümantasyon ayrışmasının net olması

---

## 10. Değişiklik Yönetimi

### 10.1 Değişiklik Türleri

- Yeni özellik talebi
- Mevcut iş kuralı değişikliği
- Güvenlik iyileştirmesi
- Performans iyileştirmesi
- Kullanıcı deneyimi düzeltmesi

### 10.2 Değişiklik Süreci

1. Talep oluşturulur.
2. Etki analizi yapılır.
3. Öncelik belirlenir.
4. Backlog'a alınır.
5. İlgili sprint veya sürüme planlanır.
6. Test ve dokümantasyon güncellenir.

---

## 11. Başarı Ölçütleri

Projeyi başarıya götüren ölçütler aşağıdaki gibi tanımlanabilir:

- Kullanıcı uygulamada temel işlemleri tamamlayabiliyor olmalı
- Sistem internet üzerinden erişilebilir olmalı
- Farklı aktör rolleri anlamlı şekilde ayrışmalı
- En az birden fazla dağıtık bileşen birlikte çalışmalı
- Veritabanı ağırlıklı süreçler başarıyla yönetilmeli
- Mobil uygulama raporun merkezinde yer almalı
- Gereksinim, use case, tasarım ve test arasında izlenebilirlik kurulmuş olmalı

---

## 12. Son Değerlendirme

Bu ek doküman, projenin yalnızca fikir ve arayüz düzeyinde değil; planlama, kalite güvence, risk yönetimi ve sürdürülebilirlik açısından da düşünüldüğünü göstermektedir. Yazılım mühendisliği projelerinde yüksek notu belirleyen şey çoğu zaman yalnızca kod miktarı değildir. Gereksinimlerin, testlerin, risklerin ve iş planının mühendislik disiplini ile ifade edilmesi projeyi üst seviyeye taşır.

Bu nedenle ana rapor ile birlikte bu ek dosya kullanıldığında, proje teslimi daha olgun, daha detaylı ve değerlendirici açısından daha savunulabilir hale gelmektedir.
