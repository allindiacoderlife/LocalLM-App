import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitial()) {
    _listen();
  }

  static ThemeMode _loadInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final saved = box.get('theme_mode', defaultValue: 'system') as String;
      return _fromString(saved);
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static ThemeMode _fromString(String str) {
    switch (str.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _listen() {
    // Keep in sync with box if needed
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final box = Hive.box(AppConstants.settingsBox);
    final str = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.dark ? 'dark' : 'system');
    box.put('theme_mode', str);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(_loadInitial());

  static double _loadInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return (box.get('font_scale', defaultValue: 1.0) as num).toDouble();
    } catch (_) {
      return 1.0;
    }
  }

  void setFontScale(double scale) {
    state = scale;
    final box = Hive.box(AppConstants.settingsBox);
    box.put('font_scale', scale);
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier();
});
