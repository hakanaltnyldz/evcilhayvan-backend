import 'package:flutter/material.dart';

/// Centralized color definitions for the entire application.
///
/// Keeping the palette in a single file makes it easier to tweak the
/// brand feel without hunting through multiple widgets.
class AppPalette {
  AppPalette._();

  /// Vibrant royal purple used for primary actions and highlights.
  static const Color primary = Color(0xFF6C63FF);

  /// Energetic coral accent that pairs nicely with the primary purple.
  static const Color secondary = Color(0xFFFF7A59);

  /// Fresh emerald tone for success states and tertiary emphasis.
  static const Color tertiary = Color(0xFF2BB673);

  /// Soft lavender wash for backgrounds.
  static const Color background = Color(0xFFF4F3FF);

  /// Card surfaces are ever-so-slightly tinted to stand out from the background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Deep charcoal used for text on light backgrounds.
  static const Color onBackground = Color(0xFF1E1B3A);

  /// Muted indigo for supporting text.
  static const Color onSurfaceVariant = Color(0xFF6E6A96);

  /// Palette used to create subtle gradients around the app.
  static const List<Color> heroGradient = [
    Color(0xFF6C63FF),
    Color(0xFF8F7DFF),
    Color(0xFFFFA29E),
  ];

  /// Gradient used for backgrounds behind large sections.
  static const List<Color> backgroundGradient = [
    Color(0xFFF4F3FF),
    Color(0xFFF9F6FF),
    Color(0xFFFFF3F0),
  ];

  /// Gradient designed for floating action buttons and chips.
  static const List<Color> accentGradient = [
    Color(0xFFFF7A59),
    Color(0xFFFF8F6B),
  ];

  /// Store (mağaza) temasına özel canlı ama pastel renkler.
  static const Color storePrimary = Color(0xFF7C7BFF); // pastel mor
  static const Color storeSecondary = Color(0xFFFFB86C); // pastel turuncu
  static const Color storeAccent = Color(0xFF5FD9C1); // mint yeşil
  static const Color storeSoftBlue = Color(0xFFE6F2FF);
  static const Color storeSoftPink = Color(0xFFFFEAF4);

  /// Mağaza ekranlarında kullanılacak arka plan gradyanı.
  static const List<Color> storeBackground = [
    Color(0xFFF7F5FF),
    Color(0xFFEAF7FF),
    Color(0xFFFFF4EC),
  ];

  /// Ürün kartları için hafif gradyan.
  static const List<Color> storeCardGradient = [
    Color(0xFF7C7BFF),
    Color(0xFF5FD9C1),
  ];

  /// Banner ve aksiyon butonlarında kullanılabilecek sıcak gradyan.
  static const List<Color> storeWarmGradient = [
    Color(0xFFFFB86C),
    Color(0xFFFF8FA2),
  ];

  /// Serin tonlarda gradyan (mavi-yeşil).
  static const List<Color> storeCoolGradient = [
    Color(0xFF11998e),
    Color(0xFF38ef7d),
  ];
}
