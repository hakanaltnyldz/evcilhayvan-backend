# Ek K: API Sözleşmesi ve Endpoint Analizi

## 1. Amaç

Bu bölüm, mobil uygulama, admin paneli ve satıcı panelinin backend ile nasıl haberleşeceğini açıklayan API sözleşmesi özetini içerir. API sözleşmesi, istemci ve sunucu ekiplerinin aynı iş kuralları ve veri formatları üzerinden çalışmasını sağlar.

---

## 2. API Tasarım İlkeleri

1. Endpoint'ler kaynak odaklı adlandırılmalıdır.
2. Korumalı endpoint'lerde JWT doğrulaması yapılmalıdır.
3. Hata cevapları standart formatta dönmelidir.
4. Liste endpoint'leri sayfalama ve filtreleme desteklemelidir.
5. Kritik işlemler sunucu tarafında yeniden doğrulanmalıdır.

---

## 3. Standart Cevap Formatı

Başarılı cevap:

```json
{
  "success": true,
  "data": {},
  "message": "İşlem başarılı"
}
```

Hatalı cevap:

```json
{
  "success": false,
  "message": "İşlem başarısız",
  "code": "validation_error"
}
```

---

## 4. Auth Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| POST | `/api/auth/register` | Kullanıcı kaydı | Public |
| POST | `/api/auth/login` | Kullanıcı girişi | Public |
| GET | `/api/auth/me` | Oturum kullanıcısı | User |
| PATCH | `/api/auth/me` | Profil güncelleme | User |
| POST | `/api/auth/forgot-password` | Şifre sıfırlama | Public |

### Örnek Login İsteği

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

### İş Kuralları

- Hatalı giriş denemeleri sınırlandırılmalıdır.
- Şifre hashlenmiş olarak saklanmalıdır.
- Token süresi kontrol edilmelidir.

---

## 5. Pet ve İlan Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/pets` | Pet/ilan listesi | User |
| POST | `/api/pets` | Pet oluşturma | User |
| GET | `/api/pets/:id` | Pet detay | User |
| PATCH | `/api/pets/:id` | Pet güncelleme | Owner |
| DELETE | `/api/pets/:id` | Pet silme/pasifleştirme | Owner |
| GET | `/api/my-adverts` | Kullanıcının ilanları | User |

### İş Kuralları

- Kullanıcı yalnızca kendi petini düzenleyebilir.
- Pet ile ilişkili aktif süreçler silmeden önce kontrol edilmelidir.

---

## 6. Sahiplendirme Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| POST | `/api/adoption-applications` | Başvuru oluşturma | User |
| GET | `/api/adoption-applications/me` | Kullanıcının başvuruları | User |
| GET | `/api/adoption-applications/advert/:id` | İlan başvuruları | Owner |
| PATCH | `/api/adoption-applications/:id/status` | Kabul/red | Owner |

### İş Kuralları

- Kullanıcı kendi ilanına başvuramaz.
- Aynı ilana tekrar başvuru yapılamaz.

---

## 7. Veteriner ve Randevu Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/veterinaries` | Veteriner listesi | User |
| GET | `/api/veterinaries/nearby` | Yakın veterinerler | User |
| GET | `/api/veterinaries/:id` | Veteriner detay | User |
| POST | `/api/appointments` | Randevu oluşturma | User |
| GET | `/api/appointments/me` | Kullanıcı randevuları | User |
| GET | `/api/appointments/vet/:id/slots` | Müsait slotlar | User |
| PATCH | `/api/appointments/:id/status` | Randevu durumu | Vet/Admin |

### İş Kuralları

- Slot çakışması engellenmelidir.
- Geçmiş tarihe randevu alınmamalıdır.

---

## 8. Aşı ve Sağlık Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/vaccinations` | Aşı kayıtları | User |
| POST | `/api/vaccinations` | Aşı kaydı ekleme | User |
| PATCH | `/api/vaccinations/:id` | Aşı güncelleme | Owner |
| GET | `/api/health/:petId` | Sağlık kayıtları | Owner |
| POST | `/api/health` | Sağlık kaydı ekleme | Owner |

### İş Kuralları

- Sağlık verisi sadece pet sahibi tarafından görüntülenebilmelidir.
- Hatırlatma tercihleri dikkate alınmalıdır.

---

## 9. Bakıcı Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/pet-sitters` | Bakıcı listesi | User |
| GET | `/api/pet-sitters/:id` | Bakıcı detay | User |
| POST | `/api/pet-sitters` | Bakıcı profili | User |
| POST | `/api/sitter-bookings` | Rezervasyon oluşturma | User |
| GET | `/api/sitter-bookings/me` | Kullanıcı rezervasyonları | User |
| PATCH | `/api/sitter-bookings/:id/status` | Durum güncelleme | Sitter/Owner |

### İş Kuralları

- Tarih aralığı kontrol edilmelidir.
- Sadece ilgili bakıcı rezervasyon durumunu kabul/red yapabilmelidir.

---

## 10. Mesajlaşma Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/conversations` | Konuşma listesi | User |
| POST | `/api/conversations` | Konuşma oluşturma | User |
| GET | `/api/conversations/:id/messages` | Mesaj listesi | Participant |
| POST | `/api/conversations/:id/messages` | Mesaj gönderme | Participant |

### Socket Olayları

| Olay | Açıklama |
|---|---|
| `join:conversation` | Konuşma odasına katılma |
| `message:new` | Yeni mesaj yayını |
| `leave:conversation` | Odadan ayrılma |

---

## 11. Mağaza ve Sipariş Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/stores` | Mağaza listesi | User |
| GET | `/api/products` | Ürün listesi | User |
| GET | `/api/products/:id` | Ürün detay | User |
| POST | `/api/cart` | Sepete ekleme | User |
| GET | `/api/cart` | Sepet görüntüleme | User |
| POST | `/api/orders` | Sipariş oluşturma | User |
| GET | `/api/orders/me` | Kullanıcı siparişleri | User |
| PATCH | `/api/orders/:id/status` | Sipariş durumu | Seller/Admin |

### İş Kuralları

- Stok sunucu tarafında doğrulanmalıdır.
- Kupon kullanım limiti kontrol edilmelidir.
- Sipariş durumu state diyagramına uygun ilerlemelidir.

---

## 12. Admin Endpoint'leri

| Method | Endpoint | Açıklama | Yetki |
|---|---|---|---|
| GET | `/api/admin/users` | Kullanıcı listesi | Admin |
| GET | `/api/admin/reports` | Rapor listesi | Admin |
| PATCH | `/api/admin/users/:id/status` | Kullanıcı durumu | Admin |
| GET | `/api/admin/audit-logs` | Audit log | Admin |
| PATCH | `/api/admin/seller-applications/:id` | Satıcı başvurusu | Admin |

### İş Kuralları

- Tüm admin işlemleri audit log'a yazılmalıdır.
- Admin dışı roller erişememelidir.

---

## 13. API Hata Kodları

| Kod | Anlamı |
|---|---|
| `validation_error` | Girdi doğrulama hatası |
| `unauthorized` | Giriş yapılmamış |
| `forbidden` | Yetki yok |
| `not_found` | Kayıt bulunamadı |
| `conflict` | Çakışan kayıt |
| `rate_limit` | İstek sınırı aşıldı |
| `internal_error` | Sunucu hatası |

---

## 14. Sonuç

API sözleşmesi, mobil ve web istemcilerin backend ile tutarlı haberleşmesini sağlar. Bu bölüm rapora eklendiğinde sistemin yalnızca arayüz veya veri modeliyle değil, servis sözleşmeleriyle de analiz edildiği gösterilmiş olur.
