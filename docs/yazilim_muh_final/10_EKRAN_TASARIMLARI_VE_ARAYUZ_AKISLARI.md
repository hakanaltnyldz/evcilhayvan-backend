# Ek H: Ekran Tasarımları ve Arayüz Akışları

## 1. Amaç

Bu bölüm, mobil uygulama, admin paneli ve satıcı panelinde yer alan temel ekranları yazılım mühendisliği bakışıyla açıklar. Her ekranın amacı, aktörü, giriş verisi, ürettiği çıktı ve hata durumları belirtilmiştir. Word raporuna ekran görüntüleri eklenecekse bu bölüm görsellerin alt açıklamalarına temel oluşturur.

---

## 2. Mobil Uygulama Ekranları

| Ekran | Aktör | Amaç |
|---|---|---|
| Splash | Tüm kullanıcılar | Oturum ve ilk açılış kontrolü |
| Onboarding | Yeni kullanıcı | Uygulamayı tanıtma |
| Giriş | Ziyaretçi | Kimlik doğrulama |
| Kayıt | Ziyaretçi | Yeni hesap oluşturma |
| Ana Sayfa | Kullanıcı | Pet, ilan ve hızlı modül erişimi |
| Pet Ekle | Kullanıcı | Pet profili oluşturma |
| Pet Detay | Kullanıcı | Pet bilgilerini ve aksiyonları görüntüleme |
| Sahiplendirme | Kullanıcı | İlanları listeleme ve başvuru |
| Eşleştirme | Kullanıcı | Swipe/match akışı |
| Mesajlar | Kullanıcı | Konuşma listesi |
| Sohbet | Kullanıcı | Gerçek zamanlı mesajlaşma |
| Veteriner Arama | Kullanıcı | Yakın veterinerleri bulma |
| Veteriner Detay | Kullanıcı | Klinik bilgisi ve randevu |
| Randevu Oluştur | Kullanıcı | Tarih/saat seçimi |
| Aşı Takvimi | Kullanıcı | Aşı kayıtları ve hatırlatmalar |
| Sağlık Günlüğü | Kullanıcı | Kilo, ilaç, not takibi |
| Bakıcı Listesi | Kullanıcı | Pet bakıcılarını görüntüleme |
| Bakıcı Detay | Kullanıcı | Bakıcı profili ve rezervasyon |
| Rezervasyon | Kullanıcı | Hizmet tarihi ve not girme |
| Mağaza | Kullanıcı | Ürünleri keşfetme |
| Ürün Detay | Kullanıcı | Ürün bilgisi ve sepete ekleme |
| Sepet | Kullanıcı | Ürünleri ve toplamı görme |
| Checkout | Kullanıcı | Adres, kupon ve sipariş onayı |
| Siparişlerim | Kullanıcı | Sipariş takibi |
| Kayıp/Bulunan | Kullanıcı | Kayıp ve bulunan ilanları |
| Sosyal Akış | Kullanıcı | Gönderi, yorum, beğeni |
| Etkinlikler | Kullanıcı | Etkinlik keşfi ve katılım |
| Ayarlar | Kullanıcı | Dil, tema, bildirim, hesap |

---

## 3. Mobil Ekran Detayları

### 3.1 Giriş Ekranı

- Amaç: Kullanıcının e-posta ve şifre ile sisteme giriş yapmasını sağlamak.
- Giriş Verileri: E-posta, şifre.
- Çıktılar: Token, kullanıcı rolü, ana ekrana yönlendirme.
- Hata Durumları: Yanlış şifre, kayıtlı olmayan e-posta, rate limit, bağlantı hatası.
- Test Edilecek Noktalar: Boş alan kontrolü, hatalı şifre, başarılı giriş, token saklama.

### 3.2 Kayıt Ekranı

- Amaç: Yeni kullanıcı hesabı oluşturmak.
- Giriş Verileri: Ad, soyad, e-posta, şifre.
- Çıktılar: Kullanıcı kaydı, giriş yönlendirmesi.
- Hata Durumları: Kayıtlı e-posta, zayıf şifre, eksik alan.
- Test Edilecek Noktalar: Benzersiz e-posta kontrolü, şifre politikası, başarılı kayıt.

### 3.3 Pet Ekleme Ekranı

- Amaç: Kullanıcının pet profili oluşturmasını sağlamak.
- Giriş Verileri: Pet adı, tür, cinsiyet, yaş, fotoğraf, konum.
- Çıktılar: Pet kaydı ve pet detay ekranı.
- Hata Durumları: Eksik zorunlu alan, medya yükleme hatası.
- Test Edilecek Noktalar: Zorunlu alanlar, fotoğraf seçimi, yetkili kayıt.

### 3.4 Veteriner Arama Ekranı

- Amaç: Kullanıcının konumuna göre veterinerleri listelemek.
- Giriş Verileri: Enlem-boylam, şehir, filtreler.
- Çıktılar: Veteriner listesi, harita marker'ları.
- Hata Durumları: Konum izni yok, sonuç bulunamadı, harita servisi hatası.
- Test Edilecek Noktalar: Konumlu arama, manuel arama, boş sonuç ekranı.

### 3.5 Randevu Oluşturma Ekranı

- Amaç: Veteriner için uygun tarih ve saat seçilmesini sağlamak.
- Giriş Verileri: Veteriner, pet, tarih, saat, not.
- Çıktılar: Randevu kaydı, bildirim.
- Hata Durumları: Slot dolu, pet seçilmedi, geçmiş tarih.
- Test Edilecek Noktalar: Slot kontrolü, randevu oluşumu, çakışma engeli.

### 3.6 Bakıcı Rezervasyon Ekranı

- Amaç: Pet bakıcısı için rezervasyon oluşturmak.
- Giriş Verileri: Bakıcı, hizmet türü, tarih aralığı, pet, not.
- Çıktılar: Rezervasyon kaydı, bakıcı bildirimi.
- Hata Durumları: Tarih çakışması, bakıcı pasif, geçersiz tarih.
- Test Edilecek Noktalar: Tarih doğrulama, durum oluşturma, bildirim.

### 3.7 Sohbet Ekranı

- Amaç: Kullanıcılar arasında mesajlaşma sağlamak.
- Giriş Verileri: Mesaj içeriği, konuşma kimliği, ek medya.
- Çıktılar: Yeni mesaj, socket olayı, push bildirimi.
- Hata Durumları: Yetkisiz konuşma, bağlantı kopması, medya hatası.
- Test Edilecek Noktalar: Gerçek zamanlı iletim, çevrim dışı alıcı, yetki kontrolü.

### 3.8 Checkout Ekranı

- Amaç: Sipariş onay sürecini tamamlamak.
- Giriş Verileri: Sepet, adres, kupon, not.
- Çıktılar: Sipariş numarası, sipariş durumu.
- Hata Durumları: Stok yetersiz, adres eksik, kupon geçersiz.
- Test Edilecek Noktalar: Stok kontrolü, kupon kontrolü, sipariş oluşturma.

---

## 4. Admin Panel Ekranları

| Ekran | Amaç |
|---|---|
| Admin Giriş | Yetkili giriş |
| Dashboard | Genel sistem özeti |
| Kullanıcılar | Kullanıcı listeleme ve durum yönetimi |
| Petler | Pet kayıtlarını inceleme |
| Gönderiler | Sosyal içerik denetimi |
| Raporlar | Şikayet ve kötüye kullanım yönetimi |
| Satıcı Başvuruları | Satıcı onay/red işlemleri |
| Veteriner Talepleri | Klinik doğrulama |
| Siparişler | Ticaret akışını izleme |
| Bakıcılar | Bakıcı profillerini inceleme |
| Audit Logs | Kritik admin işlemlerini izleme |
| Platform Ayarları | Sistem parametreleri |

### 4.1 Admin Dashboard

- Amaç: Platformun genel durumunu tek ekranda göstermek.
- Giriş Verileri: Tarih aralığı, filtreler.
- Çıktılar: Kullanıcı sayısı, sipariş sayısı, rapor sayısı, bekleyen başvurular.
- Hata Durumları: Veri çekilemedi, yetkisiz erişim.
- Test Edilecek Noktalar: Rol kontrolü, metrik doğruluğu, boş veri durumu.

### 4.2 Moderasyon Kuyruğu

- Amaç: Raporlanan içerikleri incelemek.
- Giriş Verileri: Rapor türü, içerik kimliği, admin kararı.
- Çıktılar: İçerik durumu, audit log.
- Hata Durumları: İçerik bulunamadı, karar yetkisi yok.
- Test Edilecek Noktalar: İçerik kaldırma, uyarı, log üretimi.

### 4.3 Satıcı Başvuruları

- Amaç: Satıcı olmak isteyen kullanıcıları değerlendirmek.
- Giriş Verileri: Başvuru bilgileri, karar, gerekçe.
- Çıktılar: Onay/red durumu, kullanıcı rolü güncellemesi.
- Hata Durumları: Eksik belge, tekrar karar, yetkisiz işlem.
- Test Edilecek Noktalar: Rol güncellemesi, başvuru durumu, bildirim.

---

## 5. Satıcı Panel Ekranları

| Ekran | Amaç |
|---|---|
| Satıcı Giriş | Satıcı yetkili giriş |
| Satıcı Dashboard | Satış ve sipariş özeti |
| Mağaza Profili | Mağaza bilgisi düzenleme |
| Ürün Yönetimi | Ürün ekleme, güncelleme, pasifleştirme |
| Siparişler | Siparişleri listeleme ve durum güncelleme |
| Kuponlar | Kampanya ve kupon yönetimi |
| Yorumlar | Müşteri yorumlarını izleme |
| Analitik | Satış ve performans özeti |

### 5.1 Ürün Yönetimi

- Amaç: Satıcının mağazasındaki ürünleri yönetmesini sağlamak.
- Giriş Verileri: Ürün adı, açıklama, fiyat, stok, kategori, görsel.
- Çıktılar: Ürün listesi, ürün durumu.
- Hata Durumları: Negatif stok, eksik fiyat, medya hatası.
- Test Edilecek Noktalar: Satıcı yetkisi, ürün ekleme, ürün güncelleme.

### 5.2 Satıcı Siparişleri

- Amaç: Satıcının kendi mağazasına gelen siparişleri yönetmesi.
- Giriş Verileri: Sipariş durumu, kargo bilgisi, filtreler.
- Çıktılar: Sipariş listesi, durum güncellemesi, kullanıcı bildirimi.
- Hata Durumları: Başka satıcının siparişine erişim, geçersiz durum geçişi.
- Test Edilecek Noktalar: Yetki sınırı, durum geçişi, bildirim.

---

## 6. Ekran Akışları

### 6.1 Randevu Akışı

1. Ana Sayfa
2. Veteriner Arama
3. Veteriner Detay
4. Randevu Oluştur
5. Randevularım
6. Randevu Detay

### 6.2 Bakıcı Rezervasyon Akışı

1. Ana Sayfa
2. Bakıcı Listesi
3. Bakıcı Detay
4. Rezervasyon Formu
5. Rezervasyonlarım
6. Canlı Takip / Bakım Raporu

### 6.3 Sipariş Akışı

1. Mağaza Ana Sayfa
2. Ürün Detay
3. Sepet
4. Adres Seçimi
5. Kupon ve Onay
6. Sipariş Detay
7. Sipariş Takip

### 6.4 Sahiplendirme Akışı

1. Sahiplendirme Listesi
2. İlan Detay
3. Başvuru Formu
4. Başvurularım
5. Başvuru Durumu

---

## 7. Word Raporu İçin Ekran Görüntüsü Önerisi

100 sayfalık rapor hedefinde her ekranı görsel olarak koymak raporu ağırlaştırabilir. En doğru seçim, ana akışları temsil eden ekranlardan örnek vermektir:

- Giriş / kayıt
- Ana sayfa
- Pet detay
- Veteriner arama
- Randevu oluşturma
- Bakıcı detay
- Rezervasyon formu
- Mesajlaşma
- Mağaza
- Sepet / checkout
- Admin dashboard
- Satıcı ürün yönetimi

Bu 12 ekran görüntüsü, raporu hem görsel hem de yönetilebilir tutar.
