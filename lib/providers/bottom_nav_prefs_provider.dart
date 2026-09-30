import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Один раздел-кандидат для нижней навигации — иконка/подпись/id.
/// "Добавить" сюда не входит: это не раздел, а модальное действие,
/// которое всегда закреплено по центру панели (см. home_screen.dart).
class BottomNavSection {
  final String id;
  final IconData icon;
  final IconData activeIcon;
  final String labelKey; // ключ локализации, см. l10n_extensions.dart

  const BottomNavSection(this.id, this.icon, this.activeIcon, this.labelKey);
}

/// Все разделы, из которых можно собрать нижнюю панель — ровно в этом
/// порядке они показываются в экране настройки (BottomNavSettingsScreen).
const List<BottomNavSection> kBottomNavCandidates = [
  BottomNavSection('events', Icons.calendar_today_outlined, Icons.calendar_today, 'home.nav_events'),
  BottomNavSection('map', Icons.map_outlined, Icons.map, 'home.nav_map'),
  BottomNavSection('trips', Icons.route_outlined, Icons.route, 'home.nav_trips'),
  BottomNavSection('chats', Icons.chat_bubble_outline, Icons.chat_bubble, 'home.nav_chats'),
  BottomNavSection('garage', Icons.garage_outlined, Icons.garage, 'home.nav_garage'),
  BottomNavSection('profile', Icons.person_outline, Icons.person, 'home.nav_profile'),
];

/// Набор по умолчанию — то же самое, что было в приложении до появления
/// настройки (Лента/Карта/Чаты/Профиль), чтобы у существующих пользователей
/// после обновления ничего не поменялось, пока они сами не зайдут в настройки.
const List<String> kDefaultBottomNavSections = ['events', 'map', 'chats', 'profile'];

const String _prefsKey = 'bottom_nav_sections';

/// Какие 4 раздела показаны в нижней панели и в каком порядке — выбирает
/// пользователь в Настройках, хранится на устройстве. "Добавить" всегда
/// остаётся отдельной кнопкой по центру панели независимо от этого выбора.
class BottomNavPrefsProvider extends ChangeNotifier {
  List<String> _sections = List.of(kDefaultBottomNavSections);

  List<String> get sections => List.unmodifiable(_sections);

  BottomNavPrefsProvider() {
    _load();
  }

  bool _isValid(List<String>? saved) {
    if (saved == null || saved.length != 4) return false;
    final validIds = kBottomNavCandidates.map((s) => s.id).toSet();
    return saved.every(validIds.contains);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (_isValid(saved)) {
        _sections = saved!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setSections(List<String> sections) async {
    if (!_isValid(sections)) return;
    _sections = List.of(sections);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _sections);
    } catch (_) {}
  }
}
