// lib/core/theme/theme_extensions.dart
//
// Dark-aware color helpers.
// Usage: context.cardColor, context.subtleBackground, etc.
// These automatically return the correct color for light OR dark mode.

import 'package:flutter/material.dart';
import 'app_palette.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // White in light → dark surface in dark
  Color get cardColor => isDark ? const Color(0xFF1E1C30) : Colors.white;

  // Soft background tints
  Color get subtleBackground =>
      isDark ? const Color(0xFF2A2843) : const Color(0xFFF4F3FF);

  // Store-specific soft blue panel
  Color get storeSoftColor =>
      isDark ? const Color(0xFF1A2040) : AppPalette.storeSoftBlue;

  // Divider / border
  Color get subtleBorder =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

  // Text on card
  Color get onCard =>
      isDark ? Colors.white : AppPalette.onBackground;

  // Secondary text
  Color get secondaryText =>
      isDark ? const Color(0xFFB0AECF) : AppPalette.onSurfaceVariant;

  // Input fill
  Color get inputFill =>
      isDark ? const Color(0xFF2A2843) : Colors.white;

  // Scaffold background
  Color get scaffoldBg =>
      isDark ? const Color(0xFF12111F) : AppPalette.background;
}
