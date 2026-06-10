# Ek J: Genişletilmiş Risk Yönetimi

## 1. Amaç

Bu bölüm, projenin teknik, operasyonel, güvenlik, veri, kullanıcı deneyimi ve bakım risklerini ayrıntılı olarak ele alır. Amaç yalnızca riskleri listelemek değil; her risk için etki, olasılık, önlem ve izleme göstergesi belirlemektir.

---

## 2. Risk Sınıfları

| Risk Sınıfı | Açıklama |
|---|---|
| Teknik risk | Mimari, kod, entegrasyon ve performans sorunları |
| Güvenlik riski | Yetkisiz erişim, veri sızıntısı, kötüye kullanım |
| Veri riski | Veri kaybı, tutarsızlık, yanlış ilişki |
| Operasyonel risk | Deploy, bakım, yedekleme ve izleme problemleri |
| Kullanıcı riski | Kullanılabilirlik ve kullanıcı hataları |
| Proje yönetimi riski | Takvim, kapsam, kaynak ve maliyet sapmaları |

---

## 3. Risk Matrisi

| ID | Risk | Sınıf | Olasılık | Etki | Önlem |
|---|---|---|---|---|---|
| R-01 | Gereksinimlerin sürekli değişmesi | Proje | Orta | Yüksek | Değişiklik yönetimi |
| R-02 | Kapsamın aşırı büyümesi | Proje | Yüksek | Yüksek | MVP önceliklendirme |
| R-03 | Backend ve mobil API uyumsuzluğu | Teknik | Orta | Yüksek | API sözleşmesi |
| R-04 | Socket bağlantı kopmaları | Teknik | Yüksek | Orta | Reconnect ve push fallback |
| R-05 | MongoDB sorgularında yavaşlama | Teknik | Orta | Yüksek | İndeksleme |
| R-06 | Konum servisinin hata vermesi | Teknik | Orta | Orta | Manuel konum seçimi |
| R-07 | Bildirimlerin ulaşmaması | Teknik | Orta | Orta | Bildirim logu ve retry |
| R-08 | Dosya yükleme güvenlik açığı | Güvenlik | Orta | Yüksek | Tür/boyut doğrulama |
| R-09 | Yetkisiz admin erişimi | Güvenlik | Düşük | Çok yüksek | Rol bazlı erişim |
| R-10 | Kullanıcı şifresinin sızması | Güvenlik | Düşük | Çok yüksek | Hashleme ve gizli log politikası |
| R-11 | Başkasının pet verisine erişim | Güvenlik | Orta | Yüksek | Sahiplik kontrolü |
| R-12 | Sipariş stok tutarsızlığı | Veri | Orta | Yüksek | Sunucu tarafı stok kontrolü |
| R-13 | Randevu slot çakışması | Veri | Orta | Yüksek | Atomik slot doğrulama |
| R-14 | Bakıcı rezervasyon çakışması | Veri | Orta | Yüksek | Tarih aralığı kontrolü |
| R-15 | Yanlış bildirim gönderimi | Veri | Düşük | Orta | Olay-kullanıcı eşleştirme testi |
| R-16 | Veritabanı yedeğinin alınmaması | Operasyon | Düşük | Çok yüksek | Otomatik yedekleme |
| R-17 | Deploy sonrası servis çalışmaması | Operasyon | Orta | Yüksek | Health check |
| R-18 | Ortam değişkeni hatası | Operasyon | Orta | Yüksek | Ortam kontrol listesi |
| R-19 | Kullanıcı konum izni vermez | Kullanıcı | Yüksek | Orta | Manuel konum akışı |
| R-20 | Çok karmaşık arayüz | Kullanıcı | Orta | Orta | Kullanılabilirlik testi |
| R-21 | Satıcının yanlış stok girmesi | Kullanıcı | Orta | Orta | Form doğrulama |
| R-22 | Adminin hatalı moderasyon kararı | Operasyon | Düşük | Yüksek | Gerekçe ve audit log |
| R-23 | Test kapsamının yetersiz kalması | Kalite | Orta | Yüksek | Traceability matrisi |
| R-24 | Mobil cihazlar arası uyumsuzluk | Teknik | Orta | Orta | Farklı ekran testleri |
| R-25 | Dış servis kota aşımı | Operasyon | Düşük | Orta | Kota izleme |
| R-26 | Push token geçersizliği | Teknik | Orta | Orta | Token yenileme |
| R-27 | Medya depolama maliyet artışı | Operasyon | Orta | Orta | Görsel sıkıştırma |
| R-28 | Kullanıcı verisi silme talebi | Hukuki | Düşük | Yüksek | Veri silme prosedürü |
| R-29 | Şikayet sürecinin kötüye kullanılması | Güvenlik | Orta | Orta | Rapor güven skoru |
| R-30 | Çoklu rol karmaşası | Teknik | Orta | Yüksek | Rol matrisi ve test |

---

## 4. Risk Önceliklendirme

En kritik ilk 5 risk:

1. Yetkisiz admin erişimi
2. Kullanıcı verisi sızıntısı
3. Randevu ve rezervasyon çakışmaları
4. API ve istemci uyumsuzluğu
5. Veritabanı yedekleme eksikliği

Bu risklerin ortak özelliği, oluşmaları halinde yalnızca tek ekranı değil sistem güvenilirliğini doğrudan etkilemeleridir.

---

## 5. Risk İzleme Göstergeleri

| Gösterge | İzlenen Risk |
|---|---|
| 401/403 hata sayısı | Yetkisiz erişim |
| 5xx hata oranı | Sunucu kararlılığı |
| Ortalama API yanıt süresi | Performans |
| Başarısız bildirim oranı | Bildirim altyapısı |
| Tekrarlanan randevu hataları | Slot çakışması |
| Sipariş iptal oranı | Stok ve operasyon |
| Şikayet sayısı | Moderasyon ihtiyacı |
| Crash oranı | Mobil kararlılık |

---

## 6. Risk Azaltma Stratejisi

1. Kritik iş kuralları istemciye bırakılmamalı, sunucu tarafında uygulanmalıdır.
2. Her rol için ayrı yetki testi yapılmalıdır.
3. Randevu, rezervasyon ve sipariş gibi durumlu süreçlerde state diyagramları referans alınmalıdır.
4. Dış servis entegrasyonlarında fallback senaryosu bulunmalıdır.
5. Admin işlemleri audit log ile izlenebilir olmalıdır.
6. Yedekleme ve geri yükleme planı raporda ve operasyon prosedüründe yer almalıdır.

---

## 7. Sonuç

Bu risk yönetimi yaklaşımı, projenin yalnızca geliştirilebilir değil, sürdürülebilir ve denetlenebilir bir sistem olarak ele alındığını gösterir. Özellikle dağıtık sistemlerde risk yönetimi, test planı ve mimari tasarım kadar önemlidir.
