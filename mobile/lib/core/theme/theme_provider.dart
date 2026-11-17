import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'app_theme_mode_preference';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_kThemeModeKey);
      if (savedMode == 'dark') {
        state = ThemeMode.dark;
      } else if (savedMode == 'system') {
        state = ThemeMode.system;
      } else {
        // Default to light mode for crisp and consistent visual experience
        state = ThemeMode.light;
      }
    } catch (_) {
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.system
              ? 'system'
              : 'light';
      await prefs.setString(_kThemeModeKey, modeString);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
