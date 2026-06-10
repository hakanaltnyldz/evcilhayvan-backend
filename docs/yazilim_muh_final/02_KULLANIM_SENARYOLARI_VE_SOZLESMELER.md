# Ek A: Kullanım Senaryoları ve Sözleşmeleri

## 1. Amaç

Bu dokümanın amacı, sistemin temel işlevlerini aktör merkezli olarak modellemek ve her önemli akış için ayrıntılı kullanım senaryosu sözleşmeleri oluşturmaktır. Bu sayede gereksinimlerin yalnızca madde listesi olarak kalması engellenir; iş kuralları, ön koşullar, alternatif akışlar ve son durumlar açıkça tanımlanır.

Bu doküman, Yazılım Mühendisliği dersi kapsamında özellikle istenen aşağıdaki gereksinimlere doğrudan karşılık vermektedir:

- Kullanım senaryolarının ortaya konulması
- Gerekli durumlarda kullanım senaryosu sözleşmelerinin eklenmesi
- Sorumlulukların ve aktörlerin netleştirilmesi
- Tasarım etkileşim diyagramlarına temel oluşturulması

---

## 2. Aktör Kataloğu

### 2.1 Ziyaretçi

Henüz sisteme kayıt olmamış veya giriş yapmamış kullanıcıdır. Kayıt olabilir, giriş ekranlarını görebilir, sınırlı keşif yapabilir.

### 2.2 Kayıtlı Kullanıcı

Sistemin ana aktörüdür. Pet profili açar, ilan verir, başvuru yapar, mesajlaşır, sipariş verir, bakıcı ve veteriner bulur.

### 2.3 Veteriner

Klinik bilgilerini yönetir, randevu akışına katılır, müsaitlik ve hizmet bilgisi sunar, yorum alabilir.

### 2.4 Pet Bakıcısı

Hizmet profili oluşturur, rezervasyon kabul eder veya reddeder, bakım sürecini yönetir.

### 2.5 Satıcı

Mağaza açar, ürün yükler, stok ve sipariş yönetimi yapar.

### 2.6 Admin

Platform güvenliğini, içerik moderasyonunu, başvuru yönetimini ve operasyonel denetimi yürütür.

---

## 3. Kullanım Senaryosu Listesi

| Kod | Kullanım Senaryosu | Birincil Aktör |
|---|---|---|
| UC-01 | Kayıt Olma | Ziyaretçi |
| UC-02 | Giriş Yapma | Ziyaretçi/Kullanıcı |
| UC-03 | Pet Profili Oluşturma | Kullanıcı |
| UC-04 | Sahiplendirme İlanı Oluşturma | Kullanıcı |
| UC-05 | Sahiplendirme Başvurusu Yapma | Kullanıcı |
| UC-06 | Yakındaki Veterinerleri Listeleme | Kullanıcı |
| UC-07 | Veteriner Randevusu Oluşturma | Kullanıcı |
| UC-08 | Aşı Kaydı Ekleme | Kullanıcı/Veteriner |
| UC-09 | Pet Bakıcısı Profili Oluşturma | Kullanıcı/Bakıcı |
| UC-10 | Pet Bakıcısı Rezervasyonu Oluşturma | Kullanıcı |
| UC-11 | Gerçek Zamanlı Mesaj Gönderme | Kullanıcı |
| UC-12 | Kayıp/Bulunan Hayvan İlanı Verme | Kullanıcı |
| UC-13 | Ürünü Sepete Ekleme ve Sipariş Verme | Kullanıcı |
| UC-14 | Ürün Yönetme | Satıcı |
| UC-15 | İçerik Moderasyonu Yapma | Admin |
| UC-16 | Etkinliğe Katılım Bildirme | Kullanıcı |

---

## 4. Kullanım Senaryosu Sözleşmeleri

## UC-01 Kayıt Olma

### Genel Bilgiler
- Kod: `UC-01`
- Ad: `Kayıt Olma`
- Amaç: Yeni kullanıcının sisteme hesap açabilmesi
- Birincil Aktör: `Ziyaretçi`
- İkincil Aktörler: `Bildirim Servisi`, `Kimlik Doğrulama Servisi`
- Ön Koşullar: Kullanıcının daha önce aynı e-posta ile kayıt olmamış olması
- Son Koşullar: Sistem yeni kullanıcı hesabını oluşturur ve kullanıcının giriş yapmasına izin verir

### Tetikleyici
Ziyaretçi kayıt ekranında bilgilerini doldurup "Kayıt Ol" butonuna basar.

### Ana Akış
1. Ziyaretçi kayıt ekranını açar.
2. Sistem ad, soyad, e-posta, şifre ve gerekli diğer alanları gösterir.
3. Ziyaretçi bilgileri girer.
4. Sistem alan doğrulaması yapar.
5. Sistem e-posta adresinin daha önce kullanılıp kullanılmadığını kontrol eder.
6. Sistem kullanıcı kaydını oluşturur.
7. Sistem gerekirse doğrulama kodu veya onay mesajı üretir.
8. Kullanıcıya kayıt başarılı bilgisi gösterilir.

### Alternatif Akışlar
1. E-posta zaten kayıtlı ise sistem kullanıcıyı uyarır.
2. Şifre güvenlik koşullarını sağlamıyorsa kayıt tamamlanmaz.
3. Ağ veya sunucu hatasında sistem uygun hata mesajı gösterir.

### İş Kuralları
- E-posta benzersiz olmalıdır.
- Şifre belirli karmaşıklık kurallarını sağlamalıdır.
- Rol bilgisi varsayılan olarak standart kullanıcıdır.

### Özel Gereksinimler
- Şifre alanı maskeli gösterilmelidir.
- Hata mesajları kullanıcı dostu olmalıdır.

---

## UC-02 Giriş Yapma

### Genel Bilgiler
- Kod: `UC-02`
- Ad: `Giriş Yapma`
- Amaç: Kayıtlı kullanıcının sisteme güvenli biçimde giriş yapması
- Birincil Aktör: `Ziyaretçi/Kullanıcı`
- Ön Koşullar: Kullanıcının hesabı mevcut olmalıdır
- Son Koşullar: Sistem geçerli oturum üretir

### Ana Akış
1. Kullanıcı giriş ekranını açar.
2. E-posta ve şifre bilgilerini girer.
3. Sistem kimlik doğrulama yapar.
4. Doğrulama başarılı ise token üretir.
5. Kullanıcı ana ekrana yönlendirilir.

### Alternatif Akışlar
1. Yanlış parola girilirse hata gösterilir.
2. Hesap kısıtlı ise giriş engellenir.
3. Çok sayıda başarısız deneme yapılmışsa rate limit devreye girer.

### İş Kuralları
- Hatalı denemeler izlenmelidir.
- Token süresi ve yenileme politikası tanımlı olmalıdır.

---

## UC-03 Pet Profili Oluşturma

### Genel Bilgiler
- Kod: `UC-03`
- Ad: `Pet Profili Oluşturma`
- Amaç: Kullanıcının kendi evcil hayvanı için profil açması
- Birincil Aktör: `Kullanıcı`
- Ön Koşullar: Kullanıcının giriş yapmış olması
- Son Koşullar: Pet kaydı veritabanına eklenir

### Ana Akış
1. Kullanıcı "Pet Ekle" ekranını açar.
2. Ad, tür, cinsiyet, yaş, açıklama, fotoğraf ve sağlıkla ilgili temel bilgileri girer.
3. Sistem zorunlu alanları doğrular.
4. Kullanıcı konum veya şehir bilgisi ekleyebilir.
5. Sistem pet kaydını oluşturur.
6. Kullanıcı pet detay ekranına yönlendirilir.

### Alternatif Akışlar
1. Fotoğraf yükleme başarısız olur; kullanıcı tekrar deneyebilir.
2. Eksik alan varsa kaydetme yapılamaz.

### İş Kuralları
- Her pet bir kullanıcıya bağlı olmalıdır.
- Tür ve cins gibi alanlar belirli sözlüklerle sınırlanabilir.

---

## UC-04 Sahiplendirme İlanı Oluşturma

### Genel Bilgiler
- Kod: `UC-04`
- Ad: `Sahiplendirme İlanı Oluşturma`
- Amaç: Kullanıcının peti için sahiplendirme ilanı açması
- Birincil Aktör: `Kullanıcı`
- Ön Koşullar: Kullanıcının pet profili bulunmalıdır
- Son Koşullar: İlan yayınlanır veya inceleme kuyruğuna alınır

### Ana Akış
1. Kullanıcı mevcut petlerinden birini seçer.
2. İlan tipi olarak sahiplendirmeyi işaretler.
3. Açıklama, şehir, iletişim tercihi ve ek medya girer.
4. Sistem ilanın doğrulamasını yapar.
5. İlan kaydedilir.
6. Sistem ilanı yayına alır veya moderasyon kuyruğuna gönderir.

### Alternatif Akışlar
1. Pet bulunmuyorsa sistem önce pet profili oluşturulmasını ister.
2. Yasaklı içerik saptanırsa ilan reddedilir.

### İş Kuralları
- Aynı pet için eş zamanlı çakışan ilan tipleri sınırlandırılabilir.
- Uygunsuz içerikler moderasyona yönlendirilir.

---

## UC-05 Sahiplendirme Başvurusu Yapma

### Genel Bilgiler
- Kod: `UC-05`
- Ad: `Sahiplendirme Başvurusu Yapma`
- Amaç: Kullanıcının uygun bir sahiplendirme ilanına başvuru yapması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `İlan Sahibi`, `Bildirim Servisi`

### Ana Akış
1. Kullanıcı sahiplendirme ilanını açar.
2. Başvuru formunu görüntüler.
3. Gerekli açıklama ve kişisel uygunluk bilgilerini girer.
4. Sistem başvuruyu kaydeder.
5. İlan sahibine bildirim gönderir.
6. Başvuru durumu "beklemede" olarak işaretlenir.

### Alternatif Akışlar
1. Kullanıcı kendi ilanına başvuramaz.
2. Aynı kullanıcı aynı ilana ikinci kez başvuramaz.

### İş Kuralları
- Başvurular durum bazlı yönetilir: beklemede, kabul, red, iptal.

---

## UC-06 Yakındaki Veterinerleri Listeleme

### Genel Bilgiler
- Kod: `UC-06`
- Ad: `Yakındaki Veterinerleri Listeleme`
- Amaç: Kullanıcının konumuna göre yakın veterinerleri bulması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Konum Servisi`, `Harita Servisi`

### Ön Koşullar
- Kullanıcı konum izni vermelidir veya manuel konum belirlemelidir.

### Ana Akış
1. Kullanıcı veteriner arama ekranını açar.
2. Sistem cihazdan konum alır.
3. Sistem sunucuya konum bilgisi gönderir.
4. Sunucu belirlenen yarıçap içindeki veterinerleri sorgular.
5. Sonuçlar liste ve/veya harita biçiminde gösterilir.

### Alternatif Akışlar
1. Konum izni reddedilirse manuel şehir seçimi sunulur.
2. Yakında veteriner yoksa daha geniş yarıçapla öneri yapılır.

### İş Kuralları
- Uzaklık sıralaması desteklenmelidir.
- Sonuçlar yorum, puan veya hizmet türüne göre filtrelenebilir.

---

## UC-07 Veteriner Randevusu Oluşturma

### Genel Bilgiler
- Kod: `UC-07`
- Ad: `Veteriner Randevusu Oluşturma`
- Amaç: Kullanıcının bir veteriner için randevu alması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktörler: `Veteriner`, `Bildirim Servisi`
- Ön Koşullar: Kullanıcının giriş yapmış olması ve en az bir pet profiline sahip olması
- Son Koşullar: Randevu kaydı beklemede veya onaylandı durumunda oluşturulur

### Ana Akış
1. Kullanıcı veteriner detay ekranını açar.
2. "Randevu Al" seçeneğini seçer.
3. Sistem uygun gün ve saatleri listeler.
4. Kullanıcı petini seçer.
5. Kullanıcı tarih, saat ve kısa not girer.
6. Sistem slot uygunluğunu yeniden doğrular.
7. Sistem randevu kaydını oluşturur.
8. Kullanıcıya başarı mesajı gösterilir.
9. Veteriner veya klinik paneline bildirim gönderilir.

### Alternatif Akışlar
1. Seçilen slot başka kullanıcı tarafından dolmuşsa sistem yeni slot seçtirir.
2. Kullanıcının pet profili yoksa sistem önce pet eklemeye yönlendirir.
3. Veteriner artık aktif değilse işlem iptal edilir.

### Son Durum
- Randevu veritabanında saklanır.
- Bildirimler tetiklenir.

### İş Kuralları
- Aynı zaman aralığına çakışan randevu alınamaz.
- Geçmiş tarihe randevu oluşturulamaz.
- İptal süresi kuralı ayrıca tanımlanabilir.

### İlişkili Diyagram
- [sequence_vet_appointment.puml](./sequence_vet_appointment.puml)

---

## UC-08 Aşı Kaydı Ekleme

### Genel Bilgiler
- Kod: `UC-08`
- Ad: `Aşı Kaydı Ekleme`
- Amaç: Pet için aşı kaydı ve gelecek takvim planı oluşturma
- Birincil Aktör: `Kullanıcı` veya `Veteriner`

### Ana Akış
1. Aktör ilgili petin sağlık ekranını açar.
2. Aşı türü, uygulama tarihi ve bir sonraki tarih girilir.
3. Sistem veriyi doğrular.
4. Kayıt veritabanına eklenir.
5. Hatırlatma mekanizması planlanır.

### Alternatif Akışlar
1. Tarih alanı hatalı ise kayıt alınmaz.
2. Aynı kaydın tekrar eklenmesi durumunda kullanıcı uyarılır.

### İş Kuralları
- Gelecek aşı tarihi mevcut aşı tarihinden önce olamaz.
- Hatırlatma tercihleri kullanıcı tarafından kapatılmış olabilir.

---

## UC-09 Pet Bakıcısı Profili Oluşturma

### Genel Bilgiler
- Kod: `UC-09`
- Ad: `Pet Bakıcısı Profili Oluşturma`
- Amaç: Kullanıcının kendisini hizmet sağlayıcı bakıcı olarak sisteme tanıtması
- Birincil Aktör: `Kullanıcı/Bakıcı`

### Ana Akış
1. Kullanıcı "Bakıcı Ol" sürecini başlatır.
2. Deneyim, hizmet türleri, fiyat bilgisi, müsaitlik ve konum girer.
3. Sistem gerekli alanları doğrular.
4. Profil oluşturulur.
5. Profil inceleme veya aktif statüsüne alınır.

### Alternatif Akışlar
1. Belgeler eksikse başvuru beklemeye alınır.
2. Uygunsuz içerik veya eksik açıklama varsa kullanıcıdan düzeltme istenir.

### İş Kuralları
- Bakıcı profili kullanıcı hesabına bağlıdır.
- Hizmet alanları belirli kategorilerle sınırlıdır.

---

## UC-10 Pet Bakıcısı Rezervasyonu Oluşturma

### Genel Bilgiler
- Kod: `UC-10`
- Ad: `Pet Bakıcısı Rezervasyonu Oluşturma`
- Amaç: Kullanıcının bakıcı için tarih aralıklı rezervasyon oluşturması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Bakıcı`, `Bildirim Servisi`

### Ana Akış
1. Kullanıcı bakıcı profilini görüntüler.
2. Hizmet türü seçer.
3. Başlangıç ve bitiş tarihi girer.
4. Pet ve ek not bilgisi seçilir.
5. Sistem uygunluk ve çakışma kontrolü yapar.
6. Rezervasyon oluşturulur.
7. Bakıcıya bildirim gönderilir.

### Alternatif Akışlar
1. Tarihler çakışıyorsa kullanıcı yeni aralık seçer.
2. Bakıcı pasif ise rezervasyon alınmaz.

### İş Kuralları
- Başlangıç tarihi bitiş tarihinden sonra olamaz.
- Geçmiş tarihli rezervasyon kabul edilmez.
- Rezervasyon durumları: beklemede, kabul, red, aktif, tamamlandı, iptal.

---

## UC-11 Gerçek Zamanlı Mesaj Gönderme

### Genel Bilgiler
- Kod: `UC-11`
- Ad: `Gerçek Zamanlı Mesaj Gönderme`
- Amaç: Kullanıcıların uygulama içi anlık iletişim kurması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktör: `Socket Servisi`

### Ana Akış
1. Kullanıcı bir konuşma ekranını açar.
2. Metin veya medya mesajı hazırlar.
3. Mesaj sunucuya gönderilir.
4. Sistem kullanıcının konuşma yetkisini kontrol eder.
5. Mesaj kaydedilir.
6. İlgili alıcılara anlık olarak iletilir.
7. Arayüz yeni mesajı gösterir.

### Alternatif Akışlar
1. Alıcı çevrimdışı ise sistem push bildirim gönderir.
2. Socket bağlantısı yoksa istemci tekrar deneme veya yenileme yapar.

### İş Kuralları
- Kullanıcı yalnızca dahil olduğu konuşmalara mesaj gönderebilir.
- Engellenen kullanıcılar arasında mesajlaşma sınırlandırılabilir.

---

## UC-12 Kayıp/Bulunan Hayvan İlanı Verme

### Genel Bilgiler
- Kod: `UC-12`
- Ad: `Kayıp/Bulunan Hayvan İlanı Verme`
- Amaç: Kullanıcının kayıp veya bulunan hayvan için duyuru oluşturması
- Birincil Aktör: `Kullanıcı`

### Ana Akış
1. Kullanıcı kayıp/bulunan ilan ekranını açar.
2. İlan türü seçilir: kayıp veya bulundu.
3. Konum, açıklama, fotoğraf ve iletişim bilgisi girilir.
4. Sistem konum bilgisini doğrular.
5. İlan kaydedilir.
6. Yakındaki kullanıcılara görünür hale gelir.

### Alternatif Akışlar
1. Konum olmadan harita tabanlı görünürlük sınırlı olur.
2. Yetersiz açıklama için kullanıcı uyarılabilir.

### İş Kuralları
- İlanın durumu sonradan "bulundu/çözüldü" olarak işaretlenebilir.

---

## UC-13 Ürünü Sepete Ekleme ve Sipariş Verme

### Genel Bilgiler
- Kod: `UC-13`
- Ad: `Ürünü Sepete Ekleme ve Sipariş Verme`
- Amaç: Kullanıcının ürün seçip sipariş oluşturması
- Birincil Aktör: `Kullanıcı`
- İkincil Aktörler: `Satıcı`, `Bildirim Servisi`

### Ana Akış
1. Kullanıcı mağaza veya ürün detay ekranını açar.
2. Ürünü sepete ekler.
3. Sepet ekranına gider.
4. Adres seçer veya yeni adres ekler.
5. Gerekirse kupon uygular.
6. Siparişi onaylar.
7. Sistem stok ve toplam tutarı doğrular.
8. Sipariş kaydı oluşturulur.
9. Satıcı tarafına sipariş bildirimi düşer.

### Alternatif Akışlar
1. Stok yetersizse sipariş alınmaz.
2. Kupon geçersiz ise kullanıcı uyarılır.
3. Adres eksikse sipariş tamamlanamaz.

### İş Kuralları
- Sipariş yalnızca mevcut stoktan verilebilir.
- Kuponların süre ve kullanım limiti olabilir.
- Sipariş durumları belirli yaşam döngüsü ile ilerler.

---

## UC-14 Ürün Yönetme

### Genel Bilgiler
- Kod: `UC-14`
- Ad: `Ürün Yönetme`
- Amaç: Satıcının ürün ekleme, güncelleme ve kaldırma işlemlerini yapması
- Birincil Aktör: `Satıcı`

### Ana Akış
1. Satıcı panelde ürün yönetimi ekranını açar.
2. Yeni ürün ekler veya mevcut ürünü seçer.
3. İsim, fiyat, stok, açıklama, kategori ve görsel bilgisi girer.
4. Sistem doğrulama yapar.
5. Kayıt oluşturulur veya güncellenir.
6. Sonuç ekranda listelenir.

### Alternatif Akışlar
1. Zorunlu alanlar eksikse ürün kaydedilmez.
2. Yüklenen görsel kabul edilmeyen formatta ise işlem iptal edilir.

### İş Kuralları
- Yalnızca ilgili satıcı kendi mağazasındaki ürünleri yönetebilir.
- Fiyat ve stok alanları negatif olamaz.

---

## UC-15 İçerik Moderasyonu Yapma

### Genel Bilgiler
- Kod: `UC-15`
- Ad: `İçerik Moderasyonu Yapma`
- Amaç: Adminin raporlanmış veya sorunlu içerik/kullanıcı üzerinde işlem yapması
- Birincil Aktör: `Admin`

### Ana Akış
1. Admin moderasyon kuyruğunu açar.
2. Raporlanmış içerik veya kullanıcı kaydını seçer.
3. İçeriği, geçmiş raporları ve ilgili detayları inceler.
4. Gerekirse içerik kaldırma, uyarı verme, engelleme veya hesap kısıtlama işlemi yapar.
5. Sistem tüm müdahaleleri audit log'a yazar.

### Alternatif Akışlar
1. Rapor asılsız ise admin kaydı kapatır.
2. Kanıt yetersizse manuel inceleme kuyruğuna aktarılır.

### İş Kuralları
- Admin işlemleri izlenebilir olmalıdır.
- Geri alınabilir veya kademeli yaptırım modeli tercih edilebilir.

---

## UC-16 Etkinliğe Katılım Bildirme

### Genel Bilgiler
- Kod: `UC-16`
- Ad: `Etkinliğe Katılım Bildirme`
- Amaç: Kullanıcının sistemde listelenen bir etkinliğe katılım göstermesi
- Birincil Aktör: `Kullanıcı`

### Ana Akış
1. Kullanıcı etkinlik detay ekranını açar.
2. Kontenjan ve konum bilgilerini inceler.
3. "Katıl" seçeneğine basar.
4. Sistem kontenjan ve tarih kontrolü yapar.
5. Katılım kaydı oluşturulur.
6. Kullanıcıya onay gösterilir.

### Alternatif Akışlar
1. Etkinlik doluysa kayıt alınmaz.
2. Etkinlik tarihi geçmişse işlem engellenir.

### İş Kuralları
- Aynı kullanıcı aynı etkinliğe bir kez katılabilir.

---

## 5. Analiz Sınıfları

### 5.1 Varlık Sınıfları

- User
- Pet
- Veterinary
- Appointment
- VaccinationRecord
- HealthRecord
- PetSitter
- SitterBooking
- Store
- Product
- Order
- Conversation
- Message
- LostFoundPet
- Post
- AdoptionApplication

### 5.2 Sınır Sınıfları

- Mobil giriş ekranları
- Mobil veteriner ve randevu ekranları
- Mobil mağaza ekranları
- Admin panel tabloları
- Satıcı panel formları
- REST endpoint katmanı

### 5.3 Kontrol Sınıfları

- AuthController
- AppointmentController
- VaccinationController
- PetSitterController
- OrderController
- MessageController
- AdminController

Bu ayrım, nesneye dayalı analiz ve tasarım sürecinde sorumluluk dağılımını netleştirmektedir.

---

## 6. İş Kuralları Özeti

1. Her kullanıcı benzersiz e-posta ile kayıt olur.
2. Yetkisiz kullanıcı korumalı kaynağa erişemez.
3. Kullanıcı yalnızca kendi petlerini düzenleyebilir.
4. Sahiplendirme başvuruları durum bazlı izlenir.
5. Aynı slot için çakışan veteriner randevusu açılamaz.
6. Aşı tarihi mantıksal zaman akışına uygun olmalıdır.
7. Bakıcı rezervasyonlarında çakışan tarih aralıkları engellenmelidir.
8. Mesaj gönderen kullanıcı konuşmanın tarafı olmalıdır.
9. Ürün siparişi stok sınırını aşamaz.
10. Admin işlemleri kayıt altına alınmalıdır.

---

## 7. Diyagram Referansları

Bu kullanım senaryolarına bağlı diyagram dosyaları:

- [use_case_diagram.puml](./use_case_diagram.puml)
- [class_diagram.puml](./class_diagram.puml)
- [sequence_vet_appointment.puml](./sequence_vet_appointment.puml)

İstersen bir sonraki adımda bu kullanım senaryolarının her biri için ayrı activity veya sequence diyagramları da üretebilirim.
