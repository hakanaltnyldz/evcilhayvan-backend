# Yazılım Mühendisliği Final Teslim Paketi

## Dosya Sırası

Word dosyasını aşağıdaki sırayla birleştir:

1. `00_BIRLESIK_FINAL_RAPOR_DOSYA_SIRASI.md`
2. `01_ANA_RAPOR.md`
3. `02_KULLANIM_SENARYOLARI_VE_SOZLESMELER.md`
4. `04_GEREKSINIM_IZLENEBILIRLIK_VE_VERI_SOZLUGU.md`
5. `06_MALIYET_KESTIRIMI_VE_KAYNAK_PLANLAMA.md`
6. `03_TEST_RISK_PLAN_EKLERI.md`
7. `07_KURULUM_EGITIM_BAKIM_VE_OPERASYON_PLANI.md`
8. `08_GRAFIKLER_VE_DIYAGRAMLAR_KULLANIM_REHBERI.md`
9. UML diyagram görselleri
10. Uygulama ekran görüntüleri

`05_ORNEK_RAPOR_KARSILASTIRMA.md` hazırlık notudur; istenirse ekler bölümüne konulabilir.

## Diyagram Dosyaları

- `use_case_diagram.puml`
- `context_diagram.puml`
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

- `charts/maliyet_dagilimi_pie.mmd`
- `charts/rol_bazli_isgucu_pie.mmd`
- `charts/faz_sureleri_xy.mmd`
- `charts/modul_kapsam_yogunlugu_xy.mmd`
- `charts/proje_gantt.mmd`

## Çizilmiş Görsel Çıktılar

Word dosyasına doğrudan eklenebilecek SVG çıktıları:

- `rendered/charts/`
- `rendered/diagrams/`

`rendered/charts` klasöründe Mermaid grafiklerinin SVG çıktıları vardır. `rendered/diagrams` klasöründe UML ve sistem diyagramlarının SVG çizimleri vardır.

## Sayfa Hacmi İçin Öneri

Bu paket, doğrudan Word'e aktarıldığında zaten yüksek hacimli bir temel sunar. Aşağıdakileri eklediğinde 60-70 sayfa bandına rahat yaklaşır:

- Kapak, iç kapak, özet, abstract, içindekiler
- Şekiller listesi, tablolar listesi
- Her modül için 1-2 ekran görüntüsü
- UML diyagramlarının görsel çıktıları
- Kaynakça ve ekler

## Word Format Önerisi

- Yazı tipi: Times New Roman
- Boyut: 12 punto
- Satır aralığı: 1.5
- Kenar boşlukları: Normal
- Başlıklar: Word Heading stilleri ile verilmeli

## Dikkat

Teslim öncesi aşağıdaki alanları kişiselleştir:

- Ad soyad
- Öğrenci numarası
- Üniversite / bölüm bilgileri
- Ders yürütücüsü adı
- Gerekirse proje adı

İstersen bir sonraki adımda bunları doğrudan tek bir "son teslim" markdown dosyasında birleştirip Word düzenine daha da yakın hale getireyim.
