import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/section_background.dart';
import 'sos_screen.dart';
import 'hazards_screen.dart';
import 'businesses_list_screen.dart';
import 'my_points_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Раздел "Безопасность" — SOS, дорожные опасности, автосервисы, мои точки.
/// Вынесено в отдельный экран из общего плоского меню (см.
/// car_hub_screen.dart — тот же принцип группировки).
class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home.section_safety'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/services.jpg'),
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
                      icon: Icons.sos,
                      label: 'SOS',
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SosScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.warning_amber_rounded,
                      label: context.t('home.menu_road_hazards'),
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HazardsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.car_repair,
                      label: context.t('home.menu_services'),
                      color: AppColors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusinessesListScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.pin_drop,
                      label: context.t('home.menu_my_points'),
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPointsScreen()),
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
