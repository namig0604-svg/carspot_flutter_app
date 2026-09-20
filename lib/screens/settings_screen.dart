import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'admin_panel_screen.dart';
import 'premium_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Widget _sectionCard({required String title, String? subtitle, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, subtitle == null ? 8 : 2),
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, {required String title, required List<Widget> children}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(child: Column(children: children)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAdmin = context.watch<AuthProvider>().user?['is_admin'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/settings.jpg'),
          Theme(data: AppTheme.dark, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'CarSpot Premium',
            children: [
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: const Text('Premium подписка'),
                subtitle: Text(
                  context.watch<AuthProvider>().user?['is_premium'] == true
                      ? 'Подписка активна'
                      : '14 дней бесплатно, автосервисы, больше машин и другое',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
              ),
            ],
          ),
          // "Друзья" и "Таблица лидеров" переехали в сетку быстрых действий
          // на экране "Профиль" — здесь остаются только настройки самого
          // приложения, чтобы этот экран не дублировал навигацию.
          if (isAdmin)
            _sectionCard(
              title: 'Администрирование',
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: AppColors.blue),
                  title: const Text('Админ-панель'),
                  subtitle: const Text('Жалобы и блокировка пользователей'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  ),
                ),
              ],
            ),
          _sectionCard(
            title: 'Оформление',
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Системная'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Светлая'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Тёмная'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
            ],
          ),

          _sectionCard(
            title: 'Уведомления',
            subtitle: 'Пуш-уведомления по-настоящему заработают после подключения сервиса рассылки — пока это твои личные настройки в приложении.',
            children: [
              SwitchListTile(
                title: const Text('Уведомления'),
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              SwitchListTile(
                title: const Text('Напоминания о сходках'),
                value: settings.eventReminders,
                onChanged: settings.notificationsEnabled ? settings.setEventReminders : null,
              ),
              SwitchListTile(
                title: const Text('Звуковые эффекты'),
                subtitle: const Text('Звук лайков, загрузок, новых уровней и достижений'),
                value: settings.soundEffectsEnabled,
                onChanged: settings.setSoundEffectsEnabled,
              ),
            ],
          ),

          _sectionCard(
            title: 'Язык и регион',
            subtitle: 'Полный перевод интерфейса на выбранный язык добавим отдельным обновлением.',
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Язык интерфейса'),
                subtitle: Text(settings.languageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPicker(
                  context,
                  title: 'Язык интерфейса',
                  children: kSupportedLanguages.entries
                      .map(
                        (e) => RadioListTile<String>(
                          title: Text(e.value),
                          value: e.key,
                          groupValue: settings.languageCode,
                          onChanged: (v) {
                            settings.setLanguageCode(v!);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Страна использования'),
                subtitle: Text(settings.country),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPicker(
                  context,
                  title: 'Страна использования',
                  children: kSupportedCountries
                      .map(
                        (c) => RadioListTile<String>(
                          title: Text(c),
                          value: c,
                          groupValue: settings.country,
                          onChanged: (v) {
                            settings.setCountry(v!);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      )),
        ],
      ),
    );
  }
}
