# Birleşik Final Rapor Dosya Sırası

Bu dosya, bütün içeriğin tek Word raporu haline getirilmesi için nihai sırayı verir. Aşağıdaki dosyalar sırayla birleştirildiğinde kapsamlı final raporu oluşur.

## Ana Rapor Sırası

1. Kapak sayfası
2. İç kapak
3. Özet
4. Abstract
5. İçindekiler
6. Şekiller listesi
7. Tablolar listesi
8. `01_ANA_RAPOR.md`
9. `02_KULLANIM_SENARYOLARI_VE_SOZLESMELER.md`
10. `04_GEREKSINIM_IZLENEBILIRLIK_VE_VERI_SOZLUGU.md`
11. `06_MALIYET_KESTIRIMI_VE_KAYNAK_PLANLAMA.md`
12. `03_TEST_RISK_PLAN_EKLERI.md`
13. `07_KURULUM_EGITIM_BAKIM_VE_OPERASYON_PLANI.md`
14. `08_GRAFIKLER_VE_DIYAGRAMLAR_KULLANIM_REHBERI.md`
15. Kaynakça
16. Ekler

## Hazırlık Notu

`05_ORNEK_RAPOR_KARSILASTIRMA.md` dosyası final Word raporuna zorunlu olarak eklenmeyebilir. Bu dosya, hangi eski örnekten hangi yaklaşımın alındığını göstermek için hazırlık notudur. İstenirse ekler bölümüne "Örnek Rapor İnceleme Notu" olarak konulabilir.

## Diyagram Dosyaları

Rapor içine görsel olarak eklenecek diyagramlar:

- `context_diagram.puml`
- `use_case_diagram.puml`
- `data_flow_level0.puml`
- `deployment_diagram.puml`
- `component_diagram.puml`
- `class_diagram.puml`
- `mongodb_view_diagram.puml`
- `sequence_vet_appointment.puml`
- `sequence_order_flow.puml`
- `sequence_realtime_message.puml`
- `activity_sitter_booking.puml`
- `activity_order_flow.puml`
- `state_appointment.puml`
- `state_order.puml`
- `state_sitter_booking.puml`

## Grafik Dosyaları

Rapor içine görsel olarak eklenecek grafikler:

- `charts/maliyet_dagilimi_pie.mmd`
- `charts/rol_bazli_isgucu_pie.mmd`
- `charts/faz_sureleri_xy.mmd`
- `charts/modul_kapsam_yogunlugu_xy.mmd`
- `charts/proje_gantt.mmd`

## Hazır SVG Çıktıları

Word raporuna doğrudan eklenecek hazır görseller:

- Grafik SVG'leri: `rendered/charts`
- Diyagram SVG'leri: `rendered/diagrams`

Kaynak dosyalar `.puml` ve `.mmd` olarak korunmuştur. Hazır SVG'ler Word'e ekleme aşamasında kullanılmalıdır.

## Sayfa Hacmi

Bu içerik, Word ortamında 12 punto ve 1.5 satır aralığı ile düzenlendiğinde, diyagramlar ve ekran görüntüleriyle birlikte 60-70 sayfa bandına ulaşabilecek yapıdadır. Daha fazla sayfa gerekirse en mantıklı genişletme alanı ekran görüntüleri, arayüz açıklamaları ve her use case için ayrı activity diyagramıdır.
