import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkModeKey = 'settings.dark_mode';
const _kThemeSelectedKey = 'settings.theme_selected';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kDarkModeKey) ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, newMode == ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, mode == ThemeMode.dark);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Whether the user has already chosen their theme on first launch.
/// Initialized in main() via override with the actual stored value.
final themeSelectedProvider = StateProvider<bool>((ref) => false);

Future<bool> loadThemeSelected() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kThemeSelectedKey) ?? false;
}

Future<void> markThemeSelected() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kThemeSelectedKey, true);
}
