# Ek I: Genişletilmiş Test Senaryoları

## 1. Amaç

Bu bölüm, sistemin test kapsamını modül bazlı olarak genişletir. Önceki test planında temel senaryolar verilmişti; burada pozitif, negatif, güvenlik, entegrasyon ve kullanıcı kabul testleri daha ayrıntılı sunulmuştur.

---

## 2. Test Kategorileri

| Kategori | Açıklama |
|---|---|
| Pozitif test | Beklenen doğru kullanım |
| Negatif test | Hatalı veya eksik veri |
| Yetki testi | Rol ve erişim sınırları |
| Entegrasyon testi | Modüller arası veri akışı |
| Kullanılabilirlik testi | Kullanıcı görev tamamlama |
| Regresyon testi | Yeni değişiklik sonrası eski akışlar |
| Performans testi | Yanıt süresi ve yük davranışı |

---

## 3. Kimlik Doğrulama Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| AUTH-01 | Geçerli bilgilerle kayıt | Hesap oluşur | Pozitif |
| AUTH-02 | Kayıtlı e-posta ile kayıt | Hata döner | Negatif |
| AUTH-03 | Zayıf şifre ile kayıt | Sistem kabul etmez | Negatif |
| AUTH-04 | Geçerli bilgilerle giriş | Token üretilir | Pozitif |
| AUTH-05 | Yanlış şifre ile giriş | Hata mesajı gösterilir | Negatif |
| AUTH-06 | Token olmadan korumalı endpoint | 401 döner | Yetki |
| AUTH-07 | Standart kullanıcı admin endpoint ister | 403 döner | Yetki |
| AUTH-08 | Çok sayıda başarısız giriş | Rate limit devreye girer | Güvenlik |
| AUTH-09 | Süresi dolmuş token | Yeniden giriş istenir | Regresyon |
| AUTH-10 | Çıkış sonrası token kullanımı | Erişim engellenir | Güvenlik |

---

## 4. Pet ve İlan Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| PET-01 | Pet profili oluşturma | Pet kaydı oluşur | Pozitif |
| PET-02 | Eksik ad ile pet oluşturma | Hata verilir | Negatif |
| PET-03 | Geçersiz yaş girme | Hata verilir | Negatif |
| PET-04 | Pet fotoğrafı yükleme | Fotoğraf URL oluşur | Entegrasyon |
| PET-05 | Başkasının petini güncelleme | Erişim reddedilir | Yetki |
| PET-06 | Sahiplendirme ilanı açma | İlan yayınlanır | Pozitif |
| PET-07 | Eksik açıklama ile ilan | Kayıt engellenir | Negatif |
| PET-08 | Pasif ilanı görüntüleme | Duruma göre gizlenir | Regresyon |
| PET-09 | Favoriye ekleme | Favori kaydı oluşur | Pozitif |
| PET-10 | Aynı favoriyi tekrar ekleme | Tek kayıt korunur | Negatif |

---

## 5. Sahiplendirme Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| ADOPT-01 | İlan detayından başvuru | Başvuru oluşur | Pozitif |
| ADOPT-02 | Kendi ilanına başvuru | Sistem engeller | Negatif |
| ADOPT-03 | Aynı ilana ikinci başvuru | Tekrar engellenir | Negatif |
| ADOPT-04 | İlan sahibi başvuruyu kabul eder | Durum kabul olur | Pozitif |
| ADOPT-05 | İlan sahibi başvuruyu reddeder | Durum red olur | Pozitif |
| ADOPT-06 | Başvuru sonrası bildirim | Bildirim gider | Entegrasyon |
| ADOPT-07 | Pasif ilana başvuru | Başvuru alınmaz | Regresyon |
| ADOPT-08 | Başvuran başvurusunu görür | Liste doğru gelir | Kullanıcı kabul |

---

## 6. Veteriner ve Randevu Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| VET-01 | Konumla veteriner arama | Yakın klinikler listelenir | Pozitif |
| VET-02 | Konum izni reddi | Manuel arama sunulur | Negatif |
| VET-03 | Veteriner detay açma | Klinik bilgileri gelir | Pozitif |
| VET-04 | Boş slota randevu | Randevu oluşur | Pozitif |
| VET-05 | Dolu slota randevu | Sistem engeller | Negatif |
| VET-06 | Geçmiş tarihe randevu | Sistem engeller | Negatif |
| VET-07 | Pet seçmeden randevu | Sistem uyarır | Negatif |
| VET-08 | Randevu onay bildirimi | Kullanıcıya bildirim gider | Entegrasyon |
| VET-09 | Veteriner randevu durumunu günceller | Durum değişir | Pozitif |
| VET-10 | Yetkisiz randevu güncelleme | Erişim reddedilir | Yetki |

---

## 7. Aşı ve Sağlık Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| HEALTH-01 | Aşı kaydı ekleme | Kayıt oluşur | Pozitif |
| HEALTH-02 | Sonraki tarih geçmişte | Sistem engeller | Negatif |
| HEALTH-03 | Kilo kaydı ekleme | Sağlık kaydı oluşur | Pozitif |
| HEALTH-04 | Başkasının pet sağlık kaydı | Erişim reddedilir | Yetki |
| HEALTH-05 | Hatırlatma tercihi kapalı | Bildirim gönderilmez | Entegrasyon |
| HEALTH-06 | Aşı takvimini görüntüleme | Kayıtlar listelenir | Kullanıcı kabul |

---

## 8. Bakıcı Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| SITTER-01 | Bakıcı profili oluşturma | Profil oluşur | Pozitif |
| SITTER-02 | Eksik hizmet türü | Sistem uyarır | Negatif |
| SITTER-03 | Bakıcı listesi görüntüleme | Liste gelir | Pozitif |
| SITTER-04 | Rezervasyon oluşturma | Durum beklemede olur | Pozitif |
| SITTER-05 | Geçersiz tarih aralığı | Sistem engeller | Negatif |
| SITTER-06 | Çakışan rezervasyon | Sistem engeller | Negatif |
| SITTER-07 | Bakıcı kabul eder | Durum kabul olur | Pozitif |
| SITTER-08 | Bakıcı reddeder | Durum red olur | Pozitif |
| SITTER-09 | Hizmet başlatılır | Durum aktif olur | Entegrasyon |
| SITTER-10 | Hizmet tamamlanır | Durum tamamlandı olur | Pozitif |

---

## 9. Mesajlaşma Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| MSG-01 | Konuşma başlatma | Conversation oluşur | Pozitif |
| MSG-02 | Mesaj gönderme | Mesaj kaydedilir | Pozitif |
| MSG-03 | Alıcı çevrim içiyken mesaj | Socket ile gelir | Entegrasyon |
| MSG-04 | Alıcı çevrim dışıyken mesaj | Push bildirimi gider | Entegrasyon |
| MSG-05 | Yetkisiz konuşmaya erişim | Sistem engeller | Yetki |
| MSG-06 | Boş mesaj gönderme | Sistem uyarır | Negatif |
| MSG-07 | Medya mesajı | Dosya yüklenir | Entegrasyon |
| MSG-08 | Engellenen kullanıcıya mesaj | Sistem engeller | Güvenlik |

---

## 10. Mağaza ve Sipariş Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| STORE-01 | Ürün listeleme | Ürünler gelir | Pozitif |
| STORE-02 | Filtreleme | Sonuçlar filtrelenir | Pozitif |
| STORE-03 | Sepete ürün ekleme | Sepet güncellenir | Pozitif |
| STORE-04 | Stoktan fazla adet | Sistem engeller | Negatif |
| STORE-05 | Kupon uygulama | Tutar güncellenir | Pozitif |
| STORE-06 | Süresi dolmuş kupon | Hata verilir | Negatif |
| STORE-07 | Adres olmadan sipariş | Sistem engeller | Negatif |
| STORE-08 | Sipariş oluşturma | Sipariş numarası oluşur | Pozitif |
| STORE-09 | Sipariş durumu takip | Güncel durum görünür | Kullanıcı kabul |
| STORE-10 | Satıcı başka mağaza siparişi görür | Erişim reddedilir | Yetki |

---

## 11. Admin ve Satıcı Panel Testleri

| ID | Test | Beklenen Sonuç | Tür |
|---|---|---|---|
| PANEL-01 | Admin giriş | Dashboard açılır | Pozitif |
| PANEL-02 | Standart kullanıcı admin paneli | Erişim reddedilir | Yetki |
| PANEL-03 | Raporlanan içerik listeleme | Liste gelir | Pozitif |
| PANEL-04 | İçerik kaldırma | İçerik pasif olur | Pozitif |
| PANEL-05 | Admin işlemi loglanır | Audit kaydı oluşur | Entegrasyon |
| PANEL-06 | Satıcı ürün ekler | Ürün oluşur | Pozitif |
| PANEL-07 | Negatif fiyat girilir | Sistem engeller | Negatif |
| PANEL-08 | Satıcı sipariş durumu günceller | Durum değişir | Pozitif |
| PANEL-09 | Satıcı başvuru durumu izler | Güncel durum görünür | Kullanıcı kabul |
| PANEL-10 | Admin satıcı başvurusunu onaylar | Rol güncellenir | Entegrasyon |

---

## 12. Performans ve Regresyon Testleri

| ID | Test | Beklenen Sonuç |
|---|---|---|
| PERF-01 | Ana sayfa liste yükleme | Kabul edilebilir sürede yüklenir |
| PERF-02 | Yakın veteriner sorgusu | Konum indeksleriyle hızlı döner |
| PERF-03 | Mesaj listesi açma | Sayfalama ile yüklenir |
| PERF-04 | Ürün listesi filtreleme | Gecikme makul kalır |
| REG-01 | Tema değişimi sonrası ekranlar | Layout bozulmaz |
| REG-02 | Dil değişimi sonrası metinler | Doğru dil görünür |
| REG-03 | Oturum süresi dolduğunda işlem | Girişe yönlendirilir |
| REG-04 | API hata verdiğinde UI | Anlaşılır hata gösterir |

---

## 13. Kullanıcı Kabul Testleri

| ID | Kullanıcı Görevi | Başarı Kriteri |
|---|---|---|
| UAT-01 | Kullanıcı kayıt olup giriş yapar | Ana sayfaya ulaşır |
| UAT-02 | Kullanıcı pet profili oluşturur | Pet listesinde görünür |
| UAT-03 | Kullanıcı veteriner randevusu alır | Randevu listesinde görünür |
| UAT-04 | Kullanıcı bakıcı rezervasyonu yapar | Beklemede durum oluşur |
| UAT-05 | Kullanıcı ürün siparişi verir | Sipariş numarası alır |
| UAT-06 | Satıcı ürün ekler | Ürün mağazada görünür |
| UAT-07 | Admin raporlu içeriği kaldırır | İçerik pasifleşir |
| UAT-08 | Kullanıcı mesaj gönderir | Alıcı mesajı alır |

---

## 14. Test Kapsam Özeti

Bu genişletilmiş test setinde 90'a yakın test maddesi tanımlanmıştır. Testlerin amacı yalnızca doğru çalışan senaryoları doğrulamak değil; güvenlik, yetki, veri doğruluğu, hata mesajları ve kullanıcı kabul akışlarını da kapsamaktır.
