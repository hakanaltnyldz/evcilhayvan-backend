import 'package:flutter/material.dart';

/// Plant Shop — Yeşil Palet
/// Tüm AppPalette referansları artık yeşil tonlarını döndürür.
class AppPalette {
  AppPalette._();

  /// Ana marka rengi — koyu yeşil.
  static const Color primary = Color(0xFF2D6A4F);

  /// Vurgu / buton rengi — orta yeşil.
  static const Color secondary = Color(0xFF52B788);

  /// Üçüncül yeşil ton.
  static const Color tertiary = Color(0xFF40916C);

  /// Uygulama arka plan rengi — çok açık yeşil.
  static const Color background = Color(0xFFF4FAF6);

  /// Kart yüzeyi.
  static const Color surface = Color(0xFFFFFFFF);

  /// Koyu arka planda metin.
  static const Color onBackground = Color(0xFF1B4332);

  /// İkincil metin / inaktif element.
  static const Color onSurfaceVariant = Color(0xFF52B788);

  /// Hero section gradient.
  static const List<Color> heroGradient = [
    Color(0xFF1B4332),
    Color(0xFF2D6A4F),
    Color(0xFF52B788),
  ];

  /// Arka plan gradient.
  static const List<Color> backgroundGradient = [
    Color(0xFFF4FAF6),
    Color(0xFFEDF7F0),
    Color(0xFFD8F3DC),
  ];

  /// Aksiyon buton / chip gradient.
  static const List<Color> accentGradient = [
    Color(0xFF52B788),
    Color(0xFF74C69D),
  ];

  /// AppBar koyu arka plan rengi — tüm ekranlarda tutarlı kullanım için.
  static const Color appBarDark = Color(0xFF1B4332);

  /// Mağaza primary — yeşil.
  static const Color storePrimary = Color(0xFF2D6A4F);

  /// Mağaza secondary — açık yeşil.
  static const Color storeSecondary = Color(0xFF52B788);

  /// Mağaza accent — accent yeşil.
  static const Color storeAccent = Color(0xFF74C69D);

  /// Mağaza soft panel arka planı.
  static const Color storeSoftBlue = Color(0xFFD8F3DC);

  /// Mağaza pembe panel (artık açık yeşil).
  static const Color storeSoftPink = Color(0xFFD8F3DC);

  /// Mağaza arka plan gradient.
  static const List<Color> storeBackground = [
    Color(0xFFF4FAF6),
    Color(0xFFEDF7F0),
    Color(0xFFD8F3DC),
  ];

  /// Ürün kart gradient.
  static const List<Color> storeCardGradient = [
    Color(0xFF2D6A4F),
    Color(0xFF52B788),
  ];

  /// Sıcak gradient — yeşil tonlar.
  static const List<Color> storeWarmGradient = [
    Color(0xFF40916C),
    Color(0xFF52B788),
  ];

  /// Serin gradient — koyu→orta yeşil.
  static const List<Color> storeCoolGradient = [
    Color(0xFF1B4332),
    Color(0xFF2D6A4F),
  ];
}
