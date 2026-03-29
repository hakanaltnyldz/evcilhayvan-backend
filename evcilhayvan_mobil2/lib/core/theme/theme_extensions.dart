// lib/core/theme/theme_extensions.dart
//
// Dark-aware color helpers — Plant Shop Green.
// Usage: context.cardColor, context.subtleBackground, etc.

import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // White in light → dark green surface in dark
  Color get cardColor => isDark ? const Color(0xFF1E2E28) : Colors.white;

  // Soft background tints
  Color get subtleBackground =>
      isDark ? const Color(0xFF1A2E24) : const Color(0xFFF4FAF6);

  // Store-specific soft panel
  Color get storeSoftColor =>
      isDark ? const Color(0xFF1A2E24) : const Color(0xFFD8F3DC);

  // Divider / border
  Color get subtleBorder =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

  // Text on card
  Color get onCard =>
      isDark ? Colors.white : const Color(0xFF1B4332);

  // Secondary text
  Color get secondaryText =>
      isDark ? const Color(0xFF95D5B2) : Colors.grey.shade600;

  // Input fill
  Color get inputFill =>
      isDark ? const Color(0xFF1A2E24) : Colors.white;

  // Scaffold background
  Color get scaffoldBg =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF4FAF6);
}
