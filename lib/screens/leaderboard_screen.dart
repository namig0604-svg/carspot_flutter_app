import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/gamification.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/section_background.dart';
import 'club_detail_screen.dart';
import 'user_profile_screen.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/cosmetics.dart';
import '../widgets/equipped_avatar.dart';

/// Таблица лидеров: два таба — рейтинг пользователей по опыту (XP, считается
/// на клиенте, как и раньше) и рейтинг клубов по активности (считается на
/// сервере: живые счётчики участников/сходок + средняя оценка сходок).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _rows = [];

  bool _isLoadingClubs = false;
  List<dynamic> _clubRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _loadClubs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/users/?limit=200', token: authProvider.accessToken);
      final users = response is List ? response : [];

      final rows = users.map((u) {
        final user = u as Map<String, dynamic>;
        final xp = computeXp(
          eventsAttended: (user['events_attended'] ?? 0) as int,
          eventsCreated: (user['events_created'] ?? 0) as int,
          carsCount: (user['cars_count'] ?? 0) as int,
          ratingsCount: (user['ratings_count'] ?? 0) as int,
          averageRating: ((user['average_rating'] ?? 0) as num).toDouble(),
          clubsCount: 0,
          referralsCount: 0,
          likesCount: (user['likes_count'] ?? 0) as int,
          isVerified: user['is_verified'] == true,
          isPremium: user['is_premium'] == true,
          bonusXp: (user['xp'] ?? 0) as int,
        );
        final stats = computeStats(xp);
        return {'user': user, 'stats': stats};
      }).toList();

      rows.sort((a, b) => (b['stats'] as GamificationStats).xp.compareTo((a['stats'] as GamificationStats).xp));

      setState(() => _rows = rows);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('leaderboard.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoadingClubs = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/clubs/leaderboard?limit=100', token: authProvider.accessToken);
      setState(() => _clubRows = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('leaderboard.error_with_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoadingClubs = false);
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // золото
      case 2:
        return const Color(0xFFC0C0C0); // серебро
      case 3:
        return const Color(0xFFCD7F32); // бронза
      default:
        return AppColors.blue;
    }
  }

  Widget _rankBadge(int rank) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _rankColor(rank),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildUsersTab() {
    final myId = Provider.of<AuthProvider>(context, listen: false).user?['id'];

    return _isLoading
        ? Center(child: AppFullLoader())
        : RefreshIndicator(
            color: AppColors.red,
            backgroundColor: AppColors.surface(context),
            onRefresh: _load,
            child: _rows.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(context.t('leaderboard.no_users'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final rank = index + 1;
                      final user = _rows[index]['user'] as Map<String, dynamic>;
                      final stats = _rows[index]['stats'] as GamificationStats;
                      final isMe = user['id'] == myId;
                      final avatarUrl = user['avatar_url'] as String?;
                      final username = (user['username'] as String?) ?? '?';
                      final topThree = rank <= 3;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Color.alphaBlend(AppColors.blue.withOpacity(0.22), AppColors.surface(context))
                              : (topThree
                                  ? Color.alphaBlend(_rankColor(rank).withOpacity(0.15), AppColors.surface(context))
                                  : AppColors.surface(context)),
                          borderRadius: BorderRadius.circular(12),
                          border: topThree ? Border.all(color: _rankColor(rank).withOpacity(0.6)) : null,
                        ),
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              EquippedAvatar(
                                avatarUrl: avatarUrl,
                                fallbackLetter: username.isNotEmpty ? username[0].toUpperCase() : '?',
                                radius: 20,
                                equippedFrame: user['equipped_frame'] as String?,
                                equippedBadge: user['equipped_badge'] as String?,
                              ),
                              Positioned(left: -4, top: -4, child: _rankBadge(rank)),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user['full_name'] ?? username,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: nameColorFor(user['equipped_name_color'] as String?),
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Text(context.t('leaderboard.you_tag'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            context.tArgs('leaderboard.level_line', {'level': '${stats.level}', 'title': context.t(stats.levelTitleKey)}),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.tArgs('leaderboard.xp_suffix', {'xp': '${stats.xp}'}),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'] as String)),
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  Widget _buildClubsTab() {
    return _isLoadingClubs
        ? Center(child: AppFullLoader())
        : RefreshIndicator(
            color: AppColors.red,
            backgroundColor: AppColors.surface(context),
            onRefresh: _loadClubs,
            child: _clubRows.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(context.t('leaderboard.no_clubs'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _clubRows.length,
                    itemBuilder: (context, index) {
                      final rank = index + 1;
                      final club = _clubRows[index] as Map<String, dynamic>;
                      final logoUrl = club['logo_url'] as String?;
                      final name = (club['name'] as String?) ?? '?';
                      final topThree = rank <= 3;
                      final membersCount = club['members_count'] ?? 0;
                      final eventsCount = club['events_count'] ?? 0;
                      final avgRating = ((club['average_rating'] ?? 0) as num).toDouble();

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: topThree
                              ? Color.alphaBlend(_rankColor(rank).withOpacity(0.15), AppColors.surface(context))
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: topThree ? Border.all(color: _rankColor(rank).withOpacity(0.6)) : null,
                        ),
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.red.withOpacity(0.15),
                                backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                                    ? NetworkImage(resolveImageUrl(logoUrl))
                                    : null,
                                child: (logoUrl == null || logoUrl.isEmpty)
                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                                    : null,
                              ),
                              Positioned(left: -4, top: -4, child: _rankBadge(rank)),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (club['is_verified'] == true) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 16, color: AppColors.blue),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            context.tArgs('leaderboard.club_stats_line', {'members': '$membersCount', 'events': '$eventsCount'}) +
                            '${avgRating > 0 ? ' · ★${avgRating.toStringAsFixed(1)}' : ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.tArgs('leaderboard.points_suffix', {'score': '${club['score'] ?? 0}'}),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.red),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club['id'] as String)),
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('leaderboard.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: context.t('leaderboard.tab_users')),
            Tab(text: context.t('leaderboard.tab_clubs')),
          ],
        ),
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topLeft, imageAsset: 'assets/backgrounds/events.jpg'),
          TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(),
              _buildClubsTab(),
            ],
          ),
        ],
      ),
    );
  }
}
