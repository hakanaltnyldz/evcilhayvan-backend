# Ek F: Grafikler ve Diyagramlar Kullanım Rehberi

## 1. Amaç

Bu rehber, final raporuna eklenecek grafik ve diyagramların hangi bölümde kullanılacağını açıklar. Eski örnek raporlarda güçlü görülen tablo, grafik, ER/veri modeli, use case ve iş akışı yaklaşımı bu projeye uyarlanmıştır.

---

## 2. Rapor İçine Eklenecek Grafikler

### 2.1 Maliyet Dağılımı Grafiği

Kaynak dosya:

- `charts/maliyet_dagilimi_pie.mmd`

Kullanılacağı bölüm:

- `06_MALIYET_KESTIRIMI_VE_KAYNAK_PLANLAMA.md`
- "Maliyet Varsayımı" başlığından sonra

Grafiğin amacı:

- Projede maliyetin büyük kısmının insan kaynağından geldiğini göstermek
- Bulut, cihaz ve dokümantasyon giderlerinin toplam içindeki oranını görselleştirmek

### 2.2 Rol Bazlı İş Gücü Dağılımı Grafiği

Kaynak dosya:

- `charts/rol_bazli_isgucu_pie.mmd`

Kullanılacağı bölüm:

- Kaynak planı
- Proje ekibi ve roller

Grafiğin amacı:

- Backend, mobil, analiz, test ve operasyon rollerinin projedeki ağırlığını göstermek

### 2.3 Faz Bazlı Süre Dağılımı Grafiği

Kaynak dosya:

- `charts/faz_sureleri_xy.mmd`

Kullanılacağı bölüm:

- İş-zaman planı

Grafiğin amacı:

- Planlama, analiz, tasarım, test ve raporlama fazlarının sürelerini görselleştirmek

### 2.4 Modül Kapsam Yoğunluğu Grafiği

Kaynak dosya:

- `charts/modul_kapsam_yogunlugu_xy.mmd`

Kullanılacağı bölüm:

- Proje kapsamı
- Sistem genel tanımı

Grafiğin amacı:

- Hangi modüllerin daha yoğun gereksinim ve iş kuralı içerdiğini göstermek

### 2.5 Gantt Grafiği

Kaynak dosya:

- `charts/proje_gantt.mmd`

Kullanılacağı bölüm:

- Ayrıntılı proje planı

Grafiğin amacı:

- Teslim tarihine kadar planlanan fazları zaman çizelgesi üzerinde göstermek

---

## 3. Rapor İçine Eklenecek UML ve Sistem Diyagramları

### 3.1 Use Case Diyagramı

Kaynak dosya:

- `use_case_diagram.puml`

Kullanılacağı bölüm:

- Kullanım senaryoları
- Aktör analizi

### 3.2 Bağlam Diyagramı

Kaynak dosya:

- `context_diagram.puml`

Kullanılacağı bölüm:

- Sistem genel tanımı
- Mimari bakış

Bu diyagram, sistemi dış aktörler ve dış servislerle birlikte tek bakışta gösterir.

### 3.3 Veri Akış Diyagramı

Kaynak dosya:

- `data_flow_level0.puml`

Kullanılacağı bölüm:

- Sistem çözümleme
- Mantıksal model

Bu diyagram; kimlik, pet, hizmet, ticaret, mesaj ve admin süreçleri arasındaki veri akışlarını gösterir.

### 3.4 Deployment Diyagramı

Kaynak dosya:

- `deployment_diagram.puml`

Kullanılacağı bölüm:

- Mimari tasarım
- Dağıtık sistem açıklaması

### 3.5 Component Diyagramı

Kaynak dosya:

- `component_diagram.puml`

Kullanılacağı bölüm:

- Genel tasarım
- Ortak alt sistemler

### 3.6 Sınıf Diyagramı

Kaynak dosya:

- `class_diagram.puml`

Kullanılacağı bölüm:

- Nesneye dayalı tasarım
- Analiz ve tasarım sınıfları

### 3.7 MongoDB Görünüm / Veri Modeli Diyagramı

Kaynak dosya:

- `mongodb_view_diagram.puml`

Kullanılacağı bölüm:

- Veri tasarımı
- Veri sözlüğü

Bu diyagram, eski örneklerdeki `ER Diagram` veya `Database Diagram` bölümlerinin MongoDB tabanlı karşılığıdır.

### 3.8 Sequence Diyagramları

Kaynak dosyalar:

- `sequence_vet_appointment.puml`
- `sequence_order_flow.puml`
- `sequence_realtime_message.puml`

Kullanılacağı bölüm:

- Tasarım etkileşim diyagramları

Bu diyagramlar sırasıyla veteriner randevusu, sipariş oluşturma ve gerçek zamanlı mesajlaşma akışlarını gösterir.

### 3.9 Activity Diyagramları

Kaynak dosyalar:

- `activity_sitter_booking.puml`
- `activity_order_flow.puml`

Kullanılacağı bölüm:

- İş akışları
- Kullanım senaryosu detayları

### 3.10 State Diyagramları

Kaynak dosyalar:

- `state_appointment.puml`
- `state_order.puml`
- `state_sitter_booking.puml`

Kullanılacağı bölüm:

- Durum yönetimi
- İş kuralları

Bu diyagramlar sistemdeki durum bazlı nesnelerin yaşam döngüsünü gösterir. Özellikle randevu, sipariş ve bakıcı rezervasyonu gibi süreçlerde değerlidir.

---

## 4. Word İçin Önerilen Şekil Sırası

1. Şekil 1: Sistem Bağlam Diyagramı
2. Şekil 2: Use Case Diyagramı
3. Şekil 3: Veri Akış Diyagramı
4. Şekil 4: Deployment Diyagramı
5. Şekil 5: Component Diyagramı
6. Şekil 6: Sınıf Diyagramı
7. Şekil 7: MongoDB Veri Modeli Diyagramı
8. Şekil 8: Veteriner Randevusu Sequence Diyagramı
9. Şekil 9: Sipariş Sequence Diyagramı
10. Şekil 10: Mesajlaşma Sequence Diyagramı
11. Şekil 11: Bakıcı Rezervasyonu Activity Diyagramı
12. Şekil 12: Sipariş Activity Diyagramı
13. Şekil 13: Randevu Durum Diyagramı
14. Şekil 14: Sipariş Durum Diyagramı
15. Şekil 15: Bakıcı Rezervasyonu Durum Diyagramı
16. Şekil 16: Maliyet Dağılımı Grafiği
17. Şekil 17: Rol Bazlı İş Gücü Dağılımı
18. Şekil 18: Faz Bazlı Süre Grafiği
19. Şekil 19: Modül Kapsam Yoğunluğu Grafiği
20. Şekil 20: Gantt İş-Zaman Planı

---

## 5. Render Notu

PlantUML dosyaları `.puml`, Mermaid grafikleri `.mmd` uzantılıdır. Word'e eklemek için bu dosyalar görsele çevrilmelidir. Kullanılabilecek araçlar:

- PlantUML eklentisi
- Mermaid Live Editor
- VS Code PlantUML / Mermaid preview eklentileri
- draw.io import desteği

Görsele çevrildikten sonra her diyagramın altına kısa açıklama eklenmelidir. Diyagramların açıklamasız bırakılması rapor kalitesini düşürür.
