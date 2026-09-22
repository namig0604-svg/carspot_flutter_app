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
import '../l10n/l10n_extensions.dart';

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
        title: Text(context.t('common.settings'), overflow: TextOverflow.ellipsis, maxLines: 1),
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
                title: Text(context.t('settings.premium_subscription')),
                subtitle: Text(
                  context.watch<AuthProvider>().user?['is_premium'] == true
                      ? context.t('settings.premium_active')
                      : context.t('settings.premium_promo'),
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
              title: context.t('settings.admin_section_title'),
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: AppColors.blue),
                  title: Text(context.t('settings.admin_panel_link')),
                  subtitle: Text(context.t('settings.admin_panel_subtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  ),
                ),
              ],
            ),
          _sectionCard(
            title: context.t('settings.appearance_section_title'),
            children: [
              RadioListTile<ThemeMode>(
                title: Text(context.t('settings.theme_system')),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.t('settings.theme_light')),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.t('settings.theme_dark')),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (v) => themeProvider.setThemeMode(v!),
              ),
            ],
          ),

          _sectionCard(
            title: context.t('settings.notifications_label'),
            subtitle: context.t('settings.notifications_section_subtitle'),
            children: [
              SwitchListTile(
                title: Text(context.t('settings.notifications_label')),
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              SwitchListTile(
                title: Text(context.t('settings.event_reminders')),
                value: settings.eventReminders,
                onChanged: settings.notificationsEnabled ? settings.setEventReminders : null,
              ),
              SwitchListTile(
                title: Text(context.t('settings.sound_effects')),
                subtitle: Text(context.t('settings.sound_effects_subtitle')),
                value: settings.soundEffectsEnabled,
                onChanged: settings.setSoundEffectsEnabled,
              ),
            ],
          ),

          _sectionCard(
            title: context.t('settings.language_region_section_title'),
            subtitle: context.t('settings.language_section_subtitle'),
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.t('settings.interface_language')),
                subtitle: Text(settings.languageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPicker(
                  context,
                  title: context.t('settings.interface_language'),
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
                title: Text(context.t('settings.country_used')),
                subtitle: Text(settings.country),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPicker(
                  context,
                  title: context.t('settings.country_used'),
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
