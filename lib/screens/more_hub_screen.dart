import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/section_background.dart';
import 'settings_screen.dart';
import 'faq_screen.dart';
import 'admin_panel_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Раздел "Ещё" — настройки, помощь, интерактивный тур по приложению и
/// админ-панель (только для админов). Вынесено в отдельный экран из общего
/// плоского меню (см. car_hub_screen.dart — тот же принцип группировки).
/// Быстрый доступ к настройкам также остаётся в AppBar главного экрана.
class MoreHubScreen extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onStartTour;

  const MoreHubScreen({
    Key? key,
    required this.isAdmin,
    required this.onStartTour,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home.section_other'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: Colors.blueGrey, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/settings.jpg'),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.settings,
                      label: context.t('home.menu_settings'),
                      color: Colors.grey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.help_outline,
                      label: context.t('home.menu_help'),
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.explore_outlined,
                      label: context.t('home.menu_tour'),
                      color: Colors.deepOrange,
                      onTap: onStartTour,
                    ),
                  ),
                  if (isAdmin)
                    SizedBox(
                      width: 78,
                      child: AnimatedMenuTile(
                        icon: Icons.admin_panel_settings,
                        label: context.t('home.menu_admin'),
                        color: AppColors.red,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
