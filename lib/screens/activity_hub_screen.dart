import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/gamification.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/section_background.dart';
import 'my_bookings_screen.dart';
import 'favorites_screen.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Раздел "Моя активность" — мои записи, избранное, достижения, челленджи.
/// Вынесено в отдельный экран из общего плоского меню (см.
/// car_hub_screen.dart — тот же принцип группировки).
class ActivityHubScreen extends StatelessWidget {
  final List<Achievement> achievements;
  final int level;
  final String levelTitle;

  const ActivityHubScreen({
    Key? key,
    required this.achievements,
    required this.level,
    required this.levelTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home.section_my_activity'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: Colors.amber, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/events.jpg'),
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
                      icon: Icons.event_available,
                      label: context.t('home.menu_my_bookings'),
                      color: Colors.tealAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.bookmark,
                      label: context.t('home.menu_favorites'),
                      color: AppColors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.military_tech,
                      label: context.t('home.menu_achievements'),
                      color: Colors.amber,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AchievementsScreen(
                            achievements: achievements,
                            level: level,
                            levelTitle: levelTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.flag,
                      label: context.t('home.menu_challenges'),
                      color: Colors.deepOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChallengesScreen()),
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
