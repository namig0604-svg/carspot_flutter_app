import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Тема приложения (светлая/тёмная/системная), сохраняется на устройстве.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  // По умолчанию — тёмная тема (в духе NFS Underground), пока пользователь
  // не выберет свою в настройках.
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.dark;
      }
      notifyListeners();
    } catch (_) {
      // Если shared_preferences недоступен (например, приватный режим браузера) —
      // просто остаёмся на системной теме.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString(_prefsKey, value);
    } catch (_) {}
  }
}
