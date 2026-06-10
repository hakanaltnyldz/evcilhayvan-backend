# Ek G: Modül Bazlı Detaylı Analiz

## 1. Amaç

Bu bölüm, Evcil Hayvan Hizmet, Sosyal Ağ ve E-Ticaret Platformu'nun ana modüllerini ayrı ayrı analiz eder. Amaç, sistemi yalnızca genel mimari üzerinden anlatmak yerine her modülün amacı, aktörleri, iş kuralları, veri girdileri, çıktıları, hata durumları ve test ilişkileri ile açıklanmasını sağlamaktır.

Bu yaklaşım raporu gereksiz tekrarlarla büyütmez; her modülün yazılım mühendisliği açısından hangi sorumluluğu taşıdığını görünür hale getirir.

---

## 2. Modül Listesi

| Kod | Modül | Temel Sorumluluk |
|---|---|---|
| M-01 | Kimlik Doğrulama ve Yetkilendirme | Kullanıcı hesabı, giriş, rol ve güvenlik |
| M-02 | Kullanıcı ve Profil Yönetimi | Kullanıcı bilgileri, tercihler ve hesap ayarları |
| M-03 | Pet Yönetimi | Evcil hayvan profili, ilan ve detay yönetimi |
| M-04 | Sahiplendirme ve Başvuru | Sahiplendirme ilanı ve aday başvuru süreci |
| M-05 | Eşleştirme | Çiftleştirme/eşleşme profilleri ve istekler |
| M-06 | Mesajlaşma | Kullanıcılar arası gerçek zamanlı iletişim |
| M-07 | Veteriner ve Randevu | Veteriner bulma, detay ve randevu |
| M-08 | Aşı ve Sağlık Günlüğü | Aşı, kilo, ilaç ve sağlık kayıtları |
| M-09 | Pet Bakıcı ve Rezervasyon | Bakıcı bulma, rezervasyon ve hizmet takibi |
| M-10 | Kayıp/Bulunan Hayvan | Konum tabanlı kayıp/bulunan ilanları |
| M-11 | Sosyal Akış ve Etkinlik | Gönderi, yorum, etkinlik ve topluluk |
| M-12 | Mağaza, Sepet ve Sipariş | E-ticaret, ürün, sepet, sipariş |
| M-13 | Satıcı Paneli | Mağaza, ürün, sipariş ve kupon yönetimi |
| M-14 | Admin ve Moderasyon | Platform denetimi, rapor, kullanıcı yönetimi |
| M-15 | Bildirim ve Arka Plan İşleri | Push bildirim, hatırlatma ve zamanlanmış işler |

---

## 3. M-01 Kimlik Doğrulama ve Yetkilendirme

### Amaç

Kullanıcıların sisteme güvenli şekilde kayıt olması, giriş yapması, oturumunun korunması ve rolüne göre yetkilendirilmesini sağlar.

### Aktörler

- Ziyaretçi
- Kayıtlı kullanıcı
- Admin
- Satıcı
- Veteriner
- Pet bakıcısı

### İşlevler

- Kayıt olma
- Giriş yapma
- Token üretme ve doğrulama
- Rol kontrolü
- Şifre sıfırlama
- Oturum süresi yönetimi

### İş Kuralları

1. E-posta benzersiz olmalıdır.
2. Şifre düz metin saklanmamalıdır.
3. Admin kaynaklarına yalnızca admin rolü erişebilmelidir.
4. Satıcı paneline yalnızca onaylı satıcı erişebilmelidir.
5. Token geçersizse kullanıcı tekrar girişe yönlendirilmelidir.

### Veri Girdileri

- E-posta
- Şifre
- Ad soyad
- Rol bilgisi
- Doğrulama kodu

### Veri Çıktıları

- Access token
- Kullanıcı profili
- Rol bilgisi
- Hata mesajı

### Hata Durumları

- Yanlış şifre
- Kayıtlı e-posta
- Geçersiz token
- Yetkisiz erişim
- Rate limit aşımı

### İlgili Testler

- T-01, T-02, T-03, T-04, T-05

---

## 4. M-02 Kullanıcı ve Profil Yönetimi

### Amaç

Kullanıcının kişisel profilini, iletişim bilgilerini, bildirim tercihlerini ve hesap ayarlarını yönetmesini sağlar.

### Aktörler

- Kayıtlı kullanıcı
- Admin

### İşlevler

- Profil görüntüleme
- Profil güncelleme
- Bildirim tercihlerini düzenleme
- Tema ve dil tercihi
- Kullanıcı engelleme veya şikayet etme

### İş Kuralları

1. Kullanıcı yalnızca kendi profilini güncelleyebilir.
2. Admin gerekli durumlarda kullanıcı durumunu değiştirebilir.
3. Bildirim tercihleri kullanıcı hesabıyla ilişkili saklanmalıdır.
4. Dil ve tema tercihleri cihaz veya hesap bazında korunmalıdır.

### Veri Girdileri

- Ad soyad
- Telefon
- Profil fotoğrafı
- Bildirim tercihleri
- Dil ve tema seçimi

### Veri Çıktıları

- Güncel profil
- Tercih bilgileri
- İşlem sonucu

### Hata Durumları

- Yetkisiz profil erişimi
- Geçersiz telefon formatı
- Fotoğraf yükleme hatası

### İlgili Testler

- Profil güncelleme testi
- Bildirim tercihi testi
- Yetkisiz profil erişim testi

---

## 5. M-03 Pet Yönetimi

### Amaç

Kullanıcının evcil hayvan profillerini oluşturması, güncellemesi ve ilgili ilan/hizmet süreçlerinde kullanmasını sağlar.

### Aktörler

- Kayıtlı kullanıcı
- Admin

### İşlevler

- Pet ekleme
- Pet düzenleme
- Pet detay görüntüleme
- Fotoğraf yükleme
- Konum bilgisi ekleme
- Pet sağlık kartına geçiş

### İş Kuralları

1. Her pet bir kullanıcıya bağlı olmalıdır.
2. Pet silinirse ilişkili aktif ilan ve başvurular kontrol edilmelidir.
3. Tür, cinsiyet ve yaş gibi alanlar doğrulanmalıdır.
4. Fotoğraf boyutu ve türü kısıtlanmalıdır.

### Veri Girdileri

- Pet adı
- Tür
- Cins
- Yaş
- Cinsiyet
- Fotoğraf
- Konum

### Veri Çıktıları

- Pet listesi
- Pet detay sayfası
- Sağlık ve ilan bağlantıları

### Hata Durumları

- Eksik zorunlu alan
- Geçersiz tür bilgisi
- Yetkisiz düzenleme
- Medya yükleme hatası

### İlgili Testler

- T-06, T-07

---

## 6. M-04 Sahiplendirme ve Başvuru

### Amaç

Kullanıcıların sahiplendirme ilanı açmasını ve diğer kullanıcıların bu ilanlara başvuru yapmasını sağlar.

### Aktörler

- İlan sahibi
- Başvuran kullanıcı
- Admin

### İşlevler

- Sahiplendirme ilanı oluşturma
- Başvuru gönderme
- Başvuru listeleme
- Başvuru kabul/red
- İlan durumunu güncelleme

### İş Kuralları

1. Kullanıcı kendi ilanına başvuramaz.
2. Aynı kullanıcı aynı ilana birden fazla başvuru yapamaz.
3. İlan pasifse başvuru alınamaz.
4. Kabul edilen başvuru sonrası ilan kapatılabilir.

### Veri Girdileri

- Pet seçimi
- İlan açıklaması
- Başvuru mesajı
- Başvuru durumu

### Veri Çıktıları

- İlan listesi
- Başvuru listesi
- Bildirim
- Başvuru durumu

### Hata Durumları

- İlan bulunamadı
- Başvuru tekrarı
- Yetkisiz başvuru durumu değiştirme

### İlgili Testler

- T-08, T-09, T-10

---

## 7. M-05 Eşleştirme

### Amaç

Evcil hayvanların çiftleştirme veya uygun eşleşme amacıyla profil bazlı görüntülenmesi ve istek gönderilmesini sağlar.

### Aktörler

- Pet sahibi
- Eşleşme isteği alan kullanıcı

### İşlevler

- Eşleşme profili görüntüleme
- Beğenme veya geçme
- Eşleşme isteği gönderme
- Gelen/giden istekleri listeleme
- İsteği kabul veya reddetme

### İş Kuralları

1. Kullanıcı kendi petine istek gönderemez.
2. Pasif pet profilleri eşleştirmede görünmemelidir.
3. Aynı petler arasında tekrar eden istekler sınırlandırılmalıdır.
4. Engellenen kullanıcılar eşleştirme akışında görünmemelidir.

### Veri Girdileri

- Pet profili
- Eşleşme tercihi
- Beğeni/geçme aksiyonu

### Veri Çıktıları

- Önerilen profiller
- Eşleşme isteği durumu
- Bildirim

### Hata Durumları

- Profil bulunamadı
- Tekrar eden istek
- Yetkisiz işlem

---

## 8. M-06 Mesajlaşma

### Amaç

Kullanıcıların ilan, başvuru, randevu, bakım veya sipariş süreçleriyle ilişkili olarak gerçek zamanlı iletişim kurmasını sağlar.

### Aktörler

- Kayıtlı kullanıcı
- Satıcı
- Bakıcı
- Veteriner

### İşlevler

- Konuşma başlatma
- Mesaj gönderme
- Mesaj listeleme
- Socket odasına katılma
- Çevrim içi/çevrim dışı durum
- Push bildirim fallback

### İş Kuralları

1. Kullanıcı yalnızca tarafı olduğu konuşmaya mesaj gönderebilir.
2. Engellenen kullanıcılar arasında mesajlaşma sınırlandırılmalıdır.
3. Mesaj veritabanına kaydedilmeden alıcıya başarılı sonucu gösterilmemelidir.
4. Alıcı çevrim dışıysa push bildirim tetiklenebilir.

### Veri Girdileri

- Konuşma kimliği
- Mesaj içeriği
- Ek dosya
- Gönderen kullanıcı

### Veri Çıktıları

- Mesaj listesi
- Okundu/iletildi durumu
- Bildirim

### Hata Durumları

- Konuşma bulunamadı
- Yetkisiz konuşma erişimi
- Socket bağlantısı kopması
- Medya gönderim hatası

### İlgili Diyagram

- `sequence_realtime_message`

---

## 9. M-07 Veteriner ve Randevu

### Amaç

Kullanıcının konumuna yakın veterinerleri bulması, klinik detaylarını incelemesi ve randevu almasını sağlar.

### Aktörler

- Kullanıcı
- Veteriner
- Admin

### İşlevler

- Yakın veterinerleri listeleme
- Veteriner detay görüntüleme
- Müsait slot sorgulama
- Randevu oluşturma
- Randevu durumu güncelleme
- Veteriner yorumu

### İş Kuralları

1. Geçmiş tarihe randevu oluşturulamaz.
2. Aynı slot için çakışan randevu alınamaz.
3. Randevu oluşturmak için kullanıcının pet profili olmalıdır.
4. Veteriner pasifse yeni randevu alınamaz.

### Veri Girdileri

- Konum
- Veteriner kimliği
- Pet kimliği
- Tarih-saat
- Randevu notu

### Veri Çıktıları

- Veteriner listesi
- Slot listesi
- Randevu durumu
- Bildirim

### Hata Durumları

- Konum izni yok
- Slot dolu
- Veteriner bulunamadı
- Pet seçilmedi

### İlgili Testler

- T-11, T-12, T-13

---

## 10. M-08 Aşı ve Sağlık Günlüğü

### Amaç

Pet sağlık geçmişinin, aşı kayıtlarının, kilo değişimlerinin ve bakım notlarının merkezi olarak tutulmasını sağlar.

### Aktörler

- Kullanıcı
- Veteriner

### İşlevler

- Aşı kaydı ekleme
- Sonraki aşı tarihi belirleme
- Sağlık kaydı ekleme
- Kilo takibi
- Hatırlatma üretme

### İş Kuralları

1. Sonraki aşı tarihi uygulama tarihinden önce olamaz.
2. Sağlık kayıtları ilgili pet ile ilişkilendirilmelidir.
3. Hatırlatma tercihi kapalıysa push gönderilmemelidir.
4. Kullanıcı başkasına ait pet sağlık kaydına erişemez.

### Veri Girdileri

- Aşı adı
- Uygulama tarihi
- Sonraki tarih
- Kilo
- İlaç/not

### Veri Çıktıları

- Aşı takvimi
- Sağlık geçmişi
- Grafiksel kilo değişimi
- Hatırlatma

### Hata Durumları

- Geçersiz tarih
- Yetkisiz pet erişimi
- Eksik aşı adı

---

## 11. M-09 Pet Bakıcı ve Rezervasyon

### Amaç

Kullanıcının güvenilir pet bakıcısı bulmasını, rezervasyon oluşturmasını ve hizmet durumunu takip etmesini sağlar.

### Aktörler

- Kullanıcı
- Pet bakıcısı
- Admin

### İşlevler

- Bakıcı listesi
- Bakıcı detay
- Bakıcı profili oluşturma
- Rezervasyon oluşturma
- Rezervasyon kabul/red
- Canlı hizmet durumu
- Bakım raporu

### İş Kuralları

1. Geçmiş tarihli rezervasyon oluşturulamaz.
2. Başlangıç tarihi bitiş tarihinden sonra olamaz.
3. Bakıcı pasifse rezervasyon alınamaz.
4. Aktif hizmette durum değişiklikleri loglanmalıdır.

### Veri Girdileri

- Bakıcı kimliği
- Pet kimliği
- Hizmet türü
- Tarih aralığı
- Hizmet notu

### Veri Çıktıları

- Rezervasyon durumu
- Bakıcı bildirimi
- Canlı takip durumu
- Bakım raporu

### Hata Durumları

- Tarih çakışması
- Bakıcı bulunamadı
- Yetkisiz durum güncelleme

---

## 12. M-10 Kayıp/Bulunan Hayvan

### Amaç

Kayıp veya bulunan hayvan ilanlarının konum tabanlı olarak yayınlanmasını sağlar.

### Aktörler

- Kullanıcı
- Admin

### İşlevler

- Kayıp ilanı oluşturma
- Bulunan ilanı oluşturma
- Harita üzerinde görüntüleme
- Yakındaki ilanları listeleme
- İlanı çözüldü olarak işaretleme

### İş Kuralları

1. İlan tipi kayıp veya bulundu olmalıdır.
2. Konum bilgisi yoksa yakınlık sıralaması yapılamaz.
3. Çözülen ilanlar arama sonuçlarında farklı gösterilmelidir.
4. Uygunsuz ilanlar admin tarafından kaldırılabilir.

### Veri Girdileri

- İlan tipi
- Açıklama
- Fotoğraf
- Konum
- İletişim tercihi

### Veri Çıktıları

- Harita marker'ları
- Yakın ilan listesi
- İlan durumu

### Hata Durumları

- Konum alınamadı
- Eksik açıklama
- Fotoğraf yükleme hatası

---

## 13. M-11 Sosyal Akış ve Etkinlik

### Amaç

Kullanıcıların pet odaklı sosyal gönderiler paylaşmasını, yorum yapmasını, etkinlik oluşturmasını ve toplulukla etkileşim kurmasını sağlar.

### Aktörler

- Kullanıcı
- Admin

### İşlevler

- Gönderi oluşturma
- Gönderi beğenme
- Yorum yapma
- Etkinlik oluşturma
- Etkinliğe katılma
- İçerik şikayeti

### İş Kuralları

1. Uygunsuz içerikler şikayet edilebilir.
2. Kullanıcı aynı etkinliğe bir kez katılabilir.
3. Kontenjan doluysa katılım alınamaz.
4. Silinen gönderiler sosyal akışta görünmemelidir.

### Veri Girdileri

- Gönderi metni
- Görsel
- Yorum
- Etkinlik tarihi
- Etkinlik konumu

### Veri Çıktıları

- Sosyal akış
- Yorum listesi
- Etkinlik katılım bilgisi
- Şikayet kaydı

### Hata Durumları

- İçerik boş
- Etkinlik tarihi geçmiş
- Kontenjan dolu

---

## 14. M-12 Mağaza, Sepet ve Sipariş

### Amaç

Kullanıcıların evcil hayvan ürünlerini görüntülemesi, sepete eklemesi, kupon kullanması ve sipariş oluşturmasını sağlar.

### Aktörler

- Kullanıcı
- Satıcı
- Admin

### İşlevler

- Ürün listeleme
- Ürün detay
- Sepete ekleme
- Adres seçme
- Kupon uygulama
- Sipariş oluşturma
- Sipariş takip

### İş Kuralları

1. Stok yoksa sipariş oluşturulamaz.
2. Kupon süresi dolmuşsa uygulanamaz.
3. Adres olmadan sipariş tamamlanamaz.
4. Sipariş durumları belirli sırayla ilerlemelidir.

### Veri Girdileri

- Ürün kimliği
- Adet
- Kupon kodu
- Adres
- Sipariş notu

### Veri Çıktıları

- Sepet özeti
- Toplam tutar
- Sipariş numarası
- Sipariş durumu

### Hata Durumları

- Stok yetersiz
- Kupon geçersiz
- Adres eksik
- Ödeme/sipariş onay hatası

---

## 15. M-13 Satıcı Paneli

### Amaç

Satıcıların mağaza profili, ürünleri, siparişleri, kuponları ve satış performansını yönetmesini sağlar.

### Aktörler

- Satıcı
- Admin

### İşlevler

- Satıcı başvurusu
- Mağaza profili düzenleme
- Ürün ekleme/düzenleme
- Sipariş listeleme
- Sipariş durumu güncelleme
- Kupon oluşturma
- Satış analitiği

### İş Kuralları

1. Satıcı yalnızca kendi mağazasındaki ürünleri yönetebilir.
2. Ürün fiyatı ve stok negatif olamaz.
3. Sipariş durumu geriye dönük keyfi değiştirilememelidir.
4. Satıcı başvurusu admin onayına bağlı olabilir.

### Veri Girdileri

- Mağaza adı
- Ürün bilgileri
- Fiyat/stok
- Kupon koşulları
- Sipariş durumu

### Veri Çıktıları

- Satıcı dashboard
- Ürün listesi
- Sipariş listesi
- Kupon listesi

---

## 16. M-14 Admin ve Moderasyon

### Amaç

Platformun güvenli, düzenli ve sürdürülebilir çalışması için kullanıcı, içerik, satıcı, veteriner ve şikayet süreçlerini yönetir.

### Aktörler

- Admin

### İşlevler

- Kullanıcı listeleme
- İçerik denetleme
- Şikayet inceleme
- Satıcı başvurusu değerlendirme
- Veteriner doğrulama
- Raporlama
- Audit log inceleme

### İş Kuralları

1. Admin işlemleri audit log'a yazılmalıdır.
2. İçerik kaldırma kararı gerekçeli olmalıdır.
3. Kullanıcı kısıtlama işlemi geri alınabilir olmalıdır.
4. Kritik işlemler yalnızca yetkili admin tarafından yapılmalıdır.

### Veri Girdileri

- Moderasyon kararı
- Kullanıcı durumu
- Şikayet notu
- Onay/red gerekçesi

### Veri Çıktıları

- Moderasyon kuyruğu
- Audit log
- Raporlar
- Yönetim dashboard

---

## 17. M-15 Bildirim ve Arka Plan İşleri

### Amaç

Mesaj, randevu, sipariş, aşı, rezervasyon ve sistem olaylarının kullanıcılara zamanında iletilmesini sağlar.

### Aktörler

- Sistem
- Kullanıcı
- Firebase FCM

### İşlevler

- Push bildirim gönderme
- Aşı hatırlatma
- Randevu hatırlatma
- Sipariş durum bildirimi
- Rezervasyon bildirimi
- Doğum günü veya ilan süresi hatırlatma

### İş Kuralları

1. Kullanıcının bildirim tercihi dikkate alınmalıdır.
2. Başarısız bildirimler loglanmalıdır.
3. Aynı olay için tekrar eden bildirim gönderimi sınırlandırılmalıdır.
4. Arka plan işleri sunucu yükünü aşırı artırmamalıdır.

### Veri Girdileri

- Olay tipi
- Kullanıcı cihaz token'ı
- Bildirim tercihi
- Zamanlanmış görev bilgisi

### Veri Çıktıları

- Push bildirimi
- Bildirim logu
- Hatırlatma kaydı

---

## 18. Modül Önceliklendirme

| Modül | MVP Önceliği | Gerekçe |
|---|---|---|
| Kimlik doğrulama | Çok yüksek | Tüm sistemin giriş noktasıdır |
| Pet yönetimi | Çok yüksek | Platformun ana veri varlığıdır |
| Veteriner/randevu | Yüksek | Kullanıcı değeri yüksektir |
| Bakıcı/rezervasyon | Yüksek | Hizmet platformu karakterini güçlendirir |
| Mağaza/sipariş | Yüksek | Ticari modül sağlar |
| Mesajlaşma | Yüksek | Aktörler arası iletişim gerekir |
| Admin | Yüksek | Güvenlik ve moderasyon için zorunludur |
| Sosyal akış | Orta | Topluluk etkisi sağlar |
| Etkinlik | Orta | Yan değer üretir |
| Gelişmiş analitik | Düşük | MVP sonrası genişletilebilir |

---

## 19. Sonuç

Bu modül bazlı analiz, sistemin tek bir uygulama gibi değil, birbirine bağlı alt sistemlerden oluşan dağıtık bir platform olarak tasarlandığını gösterir. Her modülün aktörleri, iş kuralları ve hata durumları ayrı ele alındığında hem test planı hem de UML diyagramları daha tutarlı hale gelir.
