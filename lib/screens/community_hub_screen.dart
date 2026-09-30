import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/section_background.dart';
import 'friends_list_screen.dart';
import 'clubs_list_screen.dart';
import 'forum_categories_screen.dart';
import 'part_listings_screen.dart';
import 'car_listings_screen.dart';
import 'car_of_week_screen.dart';
import 'convoy_screen.dart';
import 'leaderboard_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Раздел "Сообщество" — друзья, клубы, форум, маркетплейс, объявления,
/// авто недели, конвой, лидеры. Вынесено в отдельный экран из общего
/// плоского меню на главном экране (см. car_hub_screen.dart — тот же
/// принцип группировки).
class CommunityHubScreen extends StatelessWidget {
  final List<dynamic> myClubs;
  final VoidCallback onClubsChanged;

  const CommunityHubScreen({
    Key? key,
    required this.myClubs,
    required this.onClubsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home.section_community'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/clubs.jpg'),
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
                      icon: Icons.people,
                      label: context.t('home.menu_friends'),
                      color: AppColors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FriendsListScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.groups,
                      label: context.t('home.menu_clubs'),
                      color: AppColors.blue,
                      badge: myClubs.isNotEmpty ? '${myClubs.length}' : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClubsListScreen()),
                      ).then((_) => onClubsChanged()),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.forum,
                      label: context.t('home.menu_forum'),
                      color: Colors.deepOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForumCategoriesScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.storefront,
                      label: context.t('home.menu_marketplace'),
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartListingsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.sell_outlined,
                      label: context.t('home.menu_car_listings'),
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarListingsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.how_to_vote,
                      label: context.t('home.menu_car_of_week'),
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarOfWeekScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.route,
                      label: context.t('home.menu_convoy'),
                      color: AppColors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConvoyScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.emoji_events,
                      label: context.t('home.menu_leaders'),
                      color: Colors.amber,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
