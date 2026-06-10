# Ek C: Gereksinim İzlenebilirlik Matrisi ve Veri Sözlüğü

## 1. Amaç

Bu ekin amacı, proje gereksinimlerinin daha sistematik ve denetlenebilir biçimde sunulmasıdır. Yazılım mühendisliğinde gereksinimlerin yalnızca metin halinde sıralanması yeterli değildir; her gereksinimin hangi modüle, hangi kullanım senaryosuna ve hangi test alanına karşılık geldiğinin görülebilmesi gerekir. Buna ek olarak, veri sözlüğü bölümü ile sistemdeki temel varlıkların anlamı ve kritik alanları açıklanır.

---

## 2. İşlevsel Gereksinim Matrisi

| Gereksinim ID | Gereksinim Tanımı | Öncelik | Modül | İlgili Use Case |
|---|---|---|---|---|
| FR-01 | Sistem kullanıcı kaydı oluşturabilmelidir | Must | Auth | UC-01 |
| FR-02 | Sistem kullanıcı girişini desteklemelidir | Must | Auth | UC-02 |
| FR-03 | Sistem rol bazlı yetkilendirme yapmalıdır | Must | Auth/Admin | UC-02, UC-15 |
| FR-04 | Kullanıcı profil bilgilerini güncelleyebilmelidir | Must | Profil | UC-02 |
| FR-05 | Kullanıcı pet profili oluşturabilmelidir | Must | Pet | UC-03 |
| FR-06 | Kullanıcı pet profilini güncelleyebilmelidir | Must | Pet | UC-03 |
| FR-07 | Kullanıcı sahiplendirme ilanı oluşturabilmelidir | Must | İlan | UC-04 |
| FR-08 | Kullanıcı sahiplendirme ilanlarına başvurabilmelidir | Must | İlan | UC-05 |
| FR-09 | İlan sahibi başvuruları görüntüleyebilmelidir | Should | İlan | UC-05 |
| FR-10 | Kullanıcı eşleştirme profillerini listeleyebilmelidir | Should | Eşleştirme | - |
| FR-11 | Kullanıcı eşleştirme isteği gönderebilmelidir | Should | Eşleştirme | - |
| FR-12 | Kullanıcı yakındaki veterinerleri görebilmelidir | Must | Veteriner | UC-06 |
| FR-13 | Kullanıcı veteriner detaylarını görüntüleyebilmelidir | Must | Veteriner | UC-06 |
| FR-14 | Kullanıcı veteriner randevusu oluşturabilmelidir | Must | Randevu | UC-07 |
| FR-15 | Veteriner randevu durumunu güncelleyebilmelidir | Should | Randevu | UC-07 |
| FR-16 | Kullanıcı pet için aşı kaydı ekleyebilmelidir | Should | Aşı | UC-08 |
| FR-17 | Sistem yaklaşan aşılar için hatırlatma oluşturabilmelidir | Should | Aşı/Bildirim | UC-08 |
| FR-18 | Kullanıcı bakıcı profillerini listeleyebilmelidir | Must | Bakıcı | UC-10 |
| FR-19 | Kullanıcı bakıcı rezervasyonu oluşturabilmelidir | Must | Bakıcı | UC-10 |
| FR-20 | Bakıcı rezervasyon talebini kabul veya reddedebilmelidir | Should | Bakıcı | UC-10 |
| FR-21 | Kullanıcı uygulama içi mesaj gönderebilmelidir | Must | Mesajlaşma | UC-11 |
| FR-22 | Sistem yeni mesajı gerçek zamanlı iletebilmelidir | Must | Mesajlaşma/Socket | UC-11 |
| FR-23 | Kullanıcı kayıp/bulunan hayvan ilanı açabilmelidir | Should | Kayıp/Bulunan | UC-12 |
| FR-24 | Kullanıcı ürünleri listeleyebilmelidir | Must | Mağaza | UC-13 |
| FR-25 | Kullanıcı ürünü sepete ekleyebilmelidir | Must | Mağaza | UC-13 |
| FR-26 | Kullanıcı sipariş oluşturabilmelidir | Must | Mağaza/Sipariş | UC-13 |
| FR-27 | Kullanıcı kupon uygulayabilmelidir | Could | Kupon | UC-13 |
| FR-28 | Satıcı ürün ekleyebilmelidir | Must | Seller | UC-14 |
| FR-29 | Satıcı ürün bilgilerini güncelleyebilmelidir | Must | Seller | UC-14 |
| FR-30 | Satıcı siparişlerini görüntüleyebilmelidir | Must | Seller | UC-14 |
| FR-31 | Admin raporlanan içerikleri inceleyebilmelidir | Must | Admin | UC-15 |
| FR-32 | Admin içerik kaldırma işlemi yapabilmelidir | Must | Admin | UC-15 |
| FR-33 | Admin kullanıcı kısıtlama işlemi yapabilmelidir | Should | Admin | UC-15 |
| FR-34 | Sistem admin işlemlerini audit log'a yazmalıdır | Should | Admin/Audit | UC-15 |
| FR-35 | Kullanıcı etkinlik listelerini görüntüleyebilmelidir | Could | Etkinlik | UC-16 |
| FR-36 | Kullanıcı etkinliğe katılım bildirebilmelidir | Could | Etkinlik | UC-16 |

---

## 3. İşlevsel Olmayan Gereksinim Matrisi

| NFR ID | Gereksinim | Ölçüm / Kabul Kriteri | Doğrulama Yöntemi |
|---|---|---|---|
| NFR-01 | Sistem internet üzerinden erişilebilir olmalıdır | Uygulama dış ağdan erişebilmelidir | Yayın testi |
| NFR-02 | Yetkisiz erişim engellenmelidir | Korunmalı endpoint'lerde 401/403 | Güvenlik testi |
| NFR-03 | Şifreler güvenli saklanmalıdır | Hashlenmiş saklama | Kod/DB incelemesi |
| NFR-04 | İstek suistimali sınırlandırılmalıdır | Rate limit uygulanır | API testi |
| NFR-05 | Kritik akışlar mobilde anlaşılır olmalıdır | Kullanıcı görevini tamamlayabilmeli | Kullanılabilirlik testi |
| NFR-06 | Konum tabanlı sorgular anlamlı sürede dönmelidir | Yakın arama kabul edilebilir hızda | Performans testi |
| NFR-07 | Mesajlaşma gecikmesi düşük olmalıdır | Mesaj kabul edilebilir sürede görünür | Gerçek zaman testi |
| NFR-08 | Sistem yeni modüllere açık olmalıdır | Modüler yapı korunmalı | Mimari inceleme |
| NFR-09 | Log ve audit kaydı tutulmalıdır | Kritik işlemler loglanmalı | Operasyon testi |
| NFR-10 | Hata mesajları kullanıcı dostu olmalıdır | Anlaşılır hata metinleri | Arayüz testi |
| NFR-11 | Sistem çoklu rol desteklemelidir | Kullanıcı/satıcı/admin ayrışmalı | Rol testi |
| NFR-12 | Veritabanı merkezi ve sürdürülebilir olmalıdır | Bulut DB üzerinden çalışmalı | Ortam incelemesi |
| NFR-13 | Dosya yükleme güvenli olmalıdır | Tür/boyut doğrulama | Negatif test |
| NFR-14 | Bildirim altyapısı devreye alınabilir olmalıdır | Push akışları desteklenmeli | Entegrasyon testi |
| NFR-15 | Arayüz yerelleştirilebilir olmalıdır | TR/EN desteği | UI testi |

---

## 4. Gereksinim İzlenebilirlik Matrisi

| Gereksinim | Use Case | Test Örneği | İlgili Modül |
|---|---|---|---|
| FR-01 | UC-01 | T-01, T-02 | Auth |
| FR-02 | UC-02 | T-03, T-04 | Auth |
| FR-03 | UC-02, UC-15 | T-05, T-35 | Auth/Admin |
| FR-05 | UC-03 | T-06, T-07 | Pet |
| FR-07 | UC-04 | T-08 | İlan |
| FR-08 | UC-05 | T-09, T-10 | İlan |
| FR-12 | UC-06 | T-11 | Veteriner |
| FR-14 | UC-07 | T-12, T-13 | Randevu |
| FR-16 | UC-08 | T-14, T-15 | Aşı |
| FR-19 | UC-10 | T-17, T-18 | Bakıcı |
| FR-20 | UC-10 | T-19, T-20 | Bakıcı |
| FR-21 | UC-11 | T-21, T-22 | Mesajlaşma |
| FR-22 | UC-11 | T-23 | Socket |
| FR-23 | UC-12 | - | Kayıp/Bulunan |
| FR-25 | UC-13 | T-26 | Sepet |
| FR-26 | UC-13 | T-27, T-30 | Sipariş |
| FR-27 | UC-13 | T-28, T-29 | Kupon |
| FR-28 | UC-14 | - | Seller |
| FR-31 | UC-15 | T-31, T-32 | Admin |
| FR-34 | UC-15 | T-34 | Audit |
| FR-36 | UC-16 | - | Etkinlik |

Bu tablo, analiz ile test arasındaki köprüyü açıkça göstermektedir. Değerlendirme sırasında bu tip izlenebilirlik tabloları rapora ciddi ağırlık katar.

---

## 5. Veri Sözlüğü

### 5.1 User

| Alan | Açıklama |
|---|---|
| userId | Kullanıcı benzersiz kimliği |
| name | Kullanıcının görünen adı |
| email | Giriş için kullanılan benzersiz e-posta |
| passwordHash | Hashlenmiş parola |
| role | Kullanıcı rolü |
| notificationPreferences | Bildirim tercihleri |
| createdAt | Oluşturulma zamanı |

### 5.2 Pet

| Alan | Açıklama |
|---|---|
| petId | Pet benzersiz kimliği |
| ownerId | Pet sahibi kullanıcı kimliği |
| name | Pet adı |
| species | Tür bilgisi |
| breed | Irk bilgisi |
| gender | Cinsiyet |
| age | Yaş |
| photos | Fotoğraf listesi |
| location | Konum bilgisi |

### 5.3 Veterinary

| Alan | Açıklama |
|---|---|
| vetId | Veteriner/klinik kimliği |
| clinicName | Klinik adı |
| address | Adres bilgisi |
| location | Koordinat bilgisi |
| services | Verilen hizmetler |
| rating | Ortalama puan |
| workingHours | Çalışma saatleri |

### 5.4 Appointment

| Alan | Açıklama |
|---|---|
| appointmentId | Randevu kimliği |
| userId | Randevuyu oluşturan kullanıcı |
| petId | İlgili pet |
| vetId | İlgili veteriner |
| dateTime | Tarih-saat |
| status | Randevu durumu |
| note | Kullanıcı notu |

### 5.5 VaccinationRecord

| Alan | Açıklama |
|---|---|
| recordId | Aşı kaydı kimliği |
| petId | İlgili pet |
| vaccineName | Aşı adı |
| appliedDate | Uygulanma tarihi |
| nextDueDate | Sonraki tarih |
| status | Tamamlandı/bekleniyor |

### 5.6 HealthRecord

| Alan | Açıklama |
|---|---|
| recordId | Sağlık kaydı kimliği |
| petId | İlgili pet |
| weight | Kilo bilgisi |
| symptom | Belirti/not |
| medication | İlaç bilgisi |
| createdAt | Kayıt tarihi |

### 5.7 PetSitter

| Alan | Açıklama |
|---|---|
| sitterId | Bakıcı kimliği |
| userId | Kullanıcı bağlantısı |
| serviceTypes | Hizmet türleri |
| dailyPrice | Günlük veya hizmet bazlı ücret |
| location | Konum bilgisi |
| availability | Müsaitlik durumu |
| rating | Ortalama puan |

### 5.8 SitterBooking

| Alan | Açıklama |
|---|---|
| bookingId | Rezervasyon kimliği |
| ownerId | Hizmet alan kullanıcı |
| sitterId | Bakıcı kimliği |
| petId | İlgili pet |
| startDate | Başlangıç |
| endDate | Bitiş |
| status | Rezervasyon durumu |
| note | Ek not |

### 5.9 Store

| Alan | Açıklama |
|---|---|
| storeId | Mağaza kimliği |
| sellerId | Satıcı kullanıcı kimliği |
| name | Mağaza adı |
| description | Açıklama |
| rating | Ortalama puan |

### 5.10 Product

| Alan | Açıklama |
|---|---|
| productId | Ürün kimliği |
| storeId | Bağlı mağaza |
| categoryId | Kategori |
| name | Ürün adı |
| price | Satış fiyatı |
| stock | Stok miktarı |
| images | Görseller |
| active | Yayın durumu |

### 5.11 Order

| Alan | Açıklama |
|---|---|
| orderId | Sipariş kimliği |
| userId | Siparişi veren kullanıcı |
| orderNumber | Takip numarası |
| items | Sipariş kalemleri |
| totalAmount | Toplam tutar |
| addressId | Teslimat adresi |
| status | Sipariş durumu |
| createdAt | Oluşturma tarihi |

### 5.12 Conversation

| Alan | Açıklama |
|---|---|
| conversationId | Konuşma kimliği |
| participantIds | Katılımcı kullanıcılar |
| lastMessage | Son mesaj özeti |
| updatedAt | Son güncelleme |

### 5.13 Message

| Alan | Açıklama |
|---|---|
| messageId | Mesaj kimliği |
| conversationId | Bağlı konuşma |
| senderId | Gönderen kullanıcı |
| content | Mesaj içeriği |
| attachments | Medya ekleri |
| createdAt | Gönderim zamanı |

### 5.14 AdoptionApplication

| Alan | Açıklama |
|---|---|
| applicationId | Başvuru kimliği |
| advertId / petId | İlgili ilan veya pet |
| applicantId | Başvuran kullanıcı |
| message | Başvuru açıklaması |
| status | Beklemede/kabul/red |
| createdAt | Oluşturulma zamanı |

### 5.15 LostFoundPet

| Alan | Açıklama |
|---|---|
| lostFoundId | İlan kimliği |
| ownerId | Oluşturan kullanıcı |
| type | Kayıp veya bulundu |
| description | Açıklama |
| location | Koordinat |
| status | Açık/çözüldü |

### 5.16 AuditLog

| Alan | Açıklama |
|---|---|
| auditId | Log kimliği |
| actorId | İşlemi yapan kullanıcı |
| action | Yapılan işlem |
| targetType | Etkilenen nesne tipi |
| targetId | Etkilenen nesne kimliği |
| createdAt | Zaman damgası |

---

## 6. Durum Alanları İçin Örnek Yaşam Döngüleri

### 6.1 Appointment Status

- `pending`
- `confirmed`
- `completed`
- `cancelled`

### 6.2 SitterBooking Status

- `pending`
- `accepted`
- `rejected`
- `active`
- `completed`
- `cancelled`

### 6.3 Order Status

- `pending`
- `paid` veya `confirmed`
- `preparing`
- `shipped`
- `delivered`
- `cancelled`

Bu durum alanları, tasarım etkileşim diyagramları ve test senaryoları için temel oluşturmaktadır.

---

## 7. Son Not

Bu ek, projenin soyut düzeyde anlatılmasını değil, gereksinimlerin takip edilebilir hale getirilmesini hedeflemektedir. Final raporlarında en sık görülen eksikliklerden biri, "özellik anlatımı" ile "gereksinim mühendisliği" arasındaki farkın bulanıklaşmasıdır. Bu dosya o açığı kapatmak için hazırlanmıştır.
