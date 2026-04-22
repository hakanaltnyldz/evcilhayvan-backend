# Testing Guide

Bu proje icin temel test sirasi asagidaki gibi uygulanmali.

## 1. Backend

Calistirma:

```powershell
cd c:\Users\PC\Desktop\evcilhayvanoriginal\evcilhayvan
npm.cmd test
```

Kapsanan ana alanlar:

- auth ve token yenileme
- pet CRUD guvenlik kontrolleri
- veteriner review ownership
- coupon validation
- sitter booking, tracking, care report ve karsilikli review
- vet availability override
- admin stats, support, platform config ve moderation queue
- smoke seviyesinde store, product ve cart akisi

## 2. Admin Panel

Calistirma:

```powershell
cd c:\Users\PC\Desktop\evcilhayvanoriginal\evcilhayvan_admin
npm.cmd test
npm.cmd run build
```

Mevcut otomasyon:

- `PlatformSettings` veri yukleme ve kaydetme
- `ModerationQueue` listeleme ve aksiyon uygulama

## 3. Seller Panel

Calistirma:

```powershell
cd c:\Users\PC\Desktop\evcilhayvanoriginal\evcilhayvan_seller
npm.cmd test
npm.cmd run build
```

Mevcut otomasyon:

- `Dashboard` ozet veri ve son siparisler
- `Orders` liste filtreleme

## 4. Flutter Widget Testleri

Calistirma:

```powershell
cd c:\Users\PC\Desktop\evcilhayvanoriginal\evcilhayvan_mobil2
flutter test
```

Mevcut otomasyon:

- temel ortak widget render testi
- care report detail UI
- sitter financials UI
- vet earnings UI

## 5. Flutter Integration Testleri

Android emulator veya fiziksel cihaz gerekir.

Ornek komutlar:

```powershell
cd c:\Users\PC\Desktop\evcilhayvanoriginal\evcilhayvan_mobil2
flutter devices
flutter test integration_test/pet_feed_ui_test.dart
flutter test integration_test/sitter_financials_ui_test.dart
```

Not:

- Bu makinede test yazildi ama calistirilamadi; cunku desteklenen bagli Android/iOS cihaz yoktu.

## Manual Regression Checklist

### User

- giris, kayit, email verify, refresh token
- ana sayfa filtreleme, empty state, ilan detayina gecis
- mesaj listesi arama ve okunmamis siralama
- store urun inceleme ve sepete ekleme
- sitter rezervasyon olusturma
- vet randevu olusturma

### Seller

- seller login
- dashboard kartlari ve son siparisler
- orders filtreleme ve detay modal
- iade ekranlari varsa return actionlari
- analytics sayfasi grafik ve empty state

### Admin

- dashboard revenue ve growth kartlari
- returns sayfasi
- orders iade sekmesi
- vets ve sitters detail panel
- platform settings kaydetme
- moderation queue actionlari

### Vet

- clinic panel acilis
- availability override kaydetme
- review panel goruntuleme
- appointment detail clinical record
- prescription olusturma
- earnings screen

### Sitter

- dashboard KPI kartlari
- financials screen
- incoming booking accept/reject
- active booking tracking
- care report olusturma ve detay goruntuleme
- portfolio ekle/sil/kapak sec
- completed booking sonrasi musteri degerlendirme

## Onerilen CI Sirasi

1. `evcilhayvan`: `npm.cmd test`
2. `evcilhayvan_admin`: `npm.cmd test && npm.cmd run build`
3. `evcilhayvan_seller`: `npm.cmd test && npm.cmd run build`
4. `evcilhayvan_mobil2`: `flutter test`
5. cihaz varsa `integration_test` suite'leri
