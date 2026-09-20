import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Языки, которые можно выбрать в настройках. Полный перевод интерфейса
/// на все эти языки — отдельная большая задача на будущее; сейчас выбор
/// сохраняется и будет использован, когда локализация появится.
const Map<String, String> kSupportedLanguages = {
  'ru': 'Русский',
  'uk': 'Українська',
  'be': 'Беларуская',
  'kk': 'Қазақша',
  'uz': "O'zbekcha",
  'az': 'Azərbaycanca',
  'hy': 'Հայերեն',
  'ky': 'Кыргызча',
  'tg': 'Тоҷикӣ',
  'tk': 'Türkmençe',
  'ro': 'Română (Молдова)',
};

const List<String> kSupportedCountries = [
  'Россия',
  'Украина',
  'Беларусь',
  'Казахстан',
  'Узбекистан',
  'Азербайджан',
  'Армения',
  'Грузия',
  'Кыргызстан',
  'Таджикистан',
  'Туркменистан',
  'Молдова',
  'Другая',
];

/// Настройки уведомлений и язык/регион — сохраняются на устройстве.
class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _eventReminders = true;
  bool _soundEffectsEnabled = true;
  String _languageCode = 'ru';
  String _country = 'Россия';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get eventReminders => _eventReminders;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  String get languageCode => _languageCode;
  String get country => _country;
  String get languageName => kSupportedLanguages[_languageCode] ?? 'Русский';

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _eventReminders = prefs.getBool('event_reminders') ?? true;
      _soundEffectsEnabled = prefs.getBool('sound_effects_enabled') ?? true;
      _languageCode = prefs.getString('language_code') ?? 'ru';
      _country = prefs.getString('country_pref') ?? 'Россия';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _saveBool('notifications_enabled', value);
  }

  Future<void> setEventReminders(bool value) async {
    _eventReminders = value;
    notifyListeners();
    await _saveBool('event_reminders', value);
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    _soundEffectsEnabled = value;
    notifyListeners();
    await _saveBool('sound_effects_enabled', value);
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    notifyListeners();
    await _saveString('language_code', code);
  }

  Future<void> setCountry(String country) async {
    _country = country;
    notifyListeners();
    await _saveString('country_pref', country);
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}
