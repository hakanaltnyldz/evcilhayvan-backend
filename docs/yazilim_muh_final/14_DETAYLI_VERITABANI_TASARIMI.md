# Ek L: Detaylı Veritabanı Tasarımı

## 1. Amaç

Bu bölüm, sistemin veri modelini daha ayrıntılı açıklar. MongoDB belge tabanlı yapı kullanıldığı için klasik ilişkisel tablo mantığı yerine koleksiyon, belge, referans ve indeks yaklaşımı benimsenmiştir.

---

## 2. Veritabanı Tasarım İlkeleri

1. Her ana iş nesnesi ayrı koleksiyonla temsil edilmelidir.
2. Sık sorgulanan alanlarda indeks kullanılmalıdır.
3. Kullanıcı sahipliği gerektiren verilerde `ownerId`, `userId` veya benzeri referans tutulmalıdır.
4. Durum alanları kontrollü değerlerden oluşmalıdır.
5. Audit gerektiren işlemler loglanmalıdır.
6. Konum tabanlı veriler GeoJSON formatına uygun saklanmalıdır.

---

## 3. Koleksiyon Grupları

| Grup | Koleksiyonlar |
|---|---|
| Kullanıcı | users, addresses, auditlogs |
| Pet | pets, healthrecords, vaccinationrecords |
| İlan | adoptionapplications, matchrequests, interactions, favorites |
| Hizmet | veterinaries, appointments, petsitters, sitterbookings |
| Sosyal | posts, comments, events, eventattendances |
| Ticaret | stores, products, categories, cartitems, orders, coupons |
| İletişim | conversations, messages, supporttickets |
| Moderasyon | userreports, auditlogs |

---

## 4. Temel Koleksiyon Tanımları

### 4.1 users

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Kullanıcı kimliği |
| name | String | Evet | Ad soyad |
| email | String | Evet | Benzersiz e-posta |
| passwordHash | String | Evet | Hashlenmiş şifre |
| role | String | Evet | user/admin/seller/vet |
| notificationPreferences | Object | Hayır | Bildirim tercihleri |
| createdAt | Date | Evet | Oluşturulma tarihi |

Önerilen indeksler:

- `email` unique
- `role`

### 4.2 pets

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Pet kimliği |
| ownerId | ObjectId | Evet | Kullanıcı referansı |
| name | String | Evet | Pet adı |
| species | String | Evet | Tür |
| breed | String | Hayır | Irk |
| gender | String | Hayır | Cinsiyet |
| age | Number | Hayır | Yaş |
| photos | Array | Hayır | Fotoğraf URL'leri |
| location | GeoJSON | Hayır | Konum |
| status | String | Evet | Aktif/pasif |

Önerilen indeksler:

- `ownerId`
- `species`
- `location` 2dsphere

### 4.3 adoptionapplications

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Başvuru kimliği |
| petId | ObjectId | Evet | İlgili pet |
| applicantId | ObjectId | Evet | Başvuran kullanıcı |
| ownerId | ObjectId | Evet | İlan sahibi |
| message | String | Hayır | Başvuru mesajı |
| status | String | Evet | pending/accepted/rejected |
| createdAt | Date | Evet | Başvuru tarihi |

Önerilen indeksler:

- `petId`
- `applicantId`
- `status`

### 4.4 veterinaries

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Veteriner kimliği |
| clinicName | String | Evet | Klinik adı |
| address | String | Hayır | Adres |
| location | GeoJSON | Evet | Konum |
| services | Array | Hayır | Hizmet listesi |
| workingHours | Object | Hayır | Çalışma saatleri |
| rating | Number | Hayır | Ortalama puan |

Önerilen indeksler:

- `location` 2dsphere
- `clinicName`

### 4.5 appointments

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Randevu kimliği |
| userId | ObjectId | Evet | Kullanıcı |
| petId | ObjectId | Evet | Pet |
| vetId | ObjectId | Evet | Veteriner |
| dateTime | Date | Evet | Randevu zamanı |
| status | String | Evet | pending/confirmed/completed/cancelled |
| note | String | Hayır | Kullanıcı notu |

Önerilen indeksler:

- `userId`
- `vetId, dateTime`
- `status`

### 4.6 vaccinationrecords

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Kayıt kimliği |
| petId | ObjectId | Evet | Pet |
| vaccineName | String | Evet | Aşı adı |
| appliedDate | Date | Hayır | Uygulama tarihi |
| nextDueDate | Date | Hayır | Sonraki tarih |
| status | String | Evet | due/done |

Önerilen indeksler:

- `petId`
- `nextDueDate`

### 4.7 petsitters

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Bakıcı kimliği |
| userId | ObjectId | Evet | Kullanıcı |
| serviceTypes | Array | Evet | Hizmet türleri |
| location | GeoJSON | Hayır | Konum |
| rating | Number | Hayır | Ortalama puan |
| active | Boolean | Evet | Aktiflik |

Önerilen indeksler:

- `userId`
- `location` 2dsphere
- `active`

### 4.8 sitterbookings

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Rezervasyon kimliği |
| ownerId | ObjectId | Evet | Pet sahibi |
| sitterId | ObjectId | Evet | Bakıcı |
| petId | ObjectId | Evet | Pet |
| startDate | Date | Evet | Başlangıç |
| endDate | Date | Evet | Bitiş |
| status | String | Evet | pending/accepted/active/completed/cancelled |

Önerilen indeksler:

- `ownerId`
- `sitterId`
- `startDate, endDate`

### 4.9 stores

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Mağaza kimliği |
| sellerId | ObjectId | Evet | Satıcı |
| name | String | Evet | Mağaza adı |
| description | String | Hayır | Açıklama |
| rating | Number | Hayır | Ortalama puan |
| active | Boolean | Evet | Aktiflik |

### 4.10 products

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Ürün kimliği |
| storeId | ObjectId | Evet | Mağaza |
| categoryId | ObjectId | Hayır | Kategori |
| name | String | Evet | Ürün adı |
| price | Number | Evet | Fiyat |
| stock | Number | Evet | Stok |
| images | Array | Hayır | Görseller |
| active | Boolean | Evet | Yayın durumu |

Önerilen indeksler:

- `storeId`
- `categoryId`
- `price`
- `active`

### 4.11 orders

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Sipariş kimliği |
| userId | ObjectId | Evet | Sipariş sahibi |
| orderNumber | String | Evet | Takip numarası |
| items | Array | Evet | Sipariş kalemleri |
| totalAmount | Number | Evet | Toplam tutar |
| addressId | ObjectId | Evet | Teslimat adresi |
| status | String | Evet | pending/confirmed/preparing/shipped/delivered |

Önerilen indeksler:

- `userId`
- `orderNumber` unique
- `status`

### 4.12 conversations

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Konuşma kimliği |
| participants | Array | Evet | Katılımcılar |
| lastMessage | Object | Hayır | Son mesaj özeti |
| updatedAt | Date | Evet | Güncelleme zamanı |

### 4.13 messages

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Mesaj kimliği |
| conversationId | ObjectId | Evet | Konuşma |
| senderId | ObjectId | Evet | Gönderen |
| content | String | Hayır | Mesaj içeriği |
| attachments | Array | Hayır | Ek dosyalar |
| createdAt | Date | Evet | Gönderim zamanı |

Önerilen indeksler:

- `conversationId, createdAt`
- `senderId`

### 4.14 auditlogs

| Alan | Tip | Zorunlu | Açıklama |
|---|---|---|---|
| _id | ObjectId | Evet | Log kimliği |
| actorId | ObjectId | Evet | İşlemi yapan |
| action | String | Evet | İşlem tipi |
| targetType | String | Evet | Etkilenen nesne |
| targetId | ObjectId | Hayır | Etkilenen kayıt |
| createdAt | Date | Evet | Zaman |

---

## 5. Veri Güvenliği İlkeleri

1. Şifreler hashlenmiş saklanmalıdır.
2. Hassas alanlar loglara yazılmamalıdır.
3. Admin işlemleri audit log ile izlenmelidir.
4. Konum verileri yalnızca ihtiyaç duyulan süreçlerde kullanılmalıdır.
5. Kullanıcı silme veya veri talebi için prosedür tanımlanmalıdır.

---

## 6. Veri Bütünlüğü Kuralları

| Kural | Açıklama |
|---|---|
| Sahiplik kontrolü | Kullanıcı yalnızca kendi verisini düzenleyebilir |
| Durum geçişi | Randevu, sipariş ve rezervasyon durumları kontrollü ilerler |
| Referans kontrolü | Silinen kullanıcı/pet ilişkili kayıtları etkiler |
| Tekillik | E-posta ve sipariş numarası benzersizdir |
| Tarih mantığı | Başlangıç tarihi bitişten sonra olamaz |

---

## 7. Sonuç

Bu veritabanı tasarımı, sistemin çok modüllü yapısına uygun olacak biçimde koleksiyon tabanlı kurgulanmıştır. MongoDB esnekliği sayesinde modüller genişletilebilir; ancak veri bütünlüğü, yetkilendirme ve indeksleme kuralları doğru uygulanmadığında sistem güvenilirliği azalır. Bu nedenle veri modeli yalnızca teknik kayıt yapısı değil, iş kurallarının kalıcılığını sağlayan temel katman olarak değerlendirilmelidir.
