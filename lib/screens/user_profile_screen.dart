import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/gamification.dart';
import '../utils/cosmetics.dart';
import '../widgets/equipped_avatar.dart';
import 'profile_boost_screen.dart';
import '../widgets/report_dialog.dart';
import 'car_detail_screen.dart';
import 'chat_room_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_loader.dart';
import '../utils/sound_player.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Публичный профиль пользователя (не свой): машины, клубы, статистика.
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _user;
  List<dynamic> _cars = [];
  List<dynamic> _clubs = [];
  bool _isLoading = true;

  // Друзья: none | friends | pending_sent | pending_received
  String _friendStatus = 'none';
  String? _friendshipId;
  bool _friendActionLoading = false;

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];
  bool get _isMe => widget.userId == _myId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await Future.wait([
        ApiService.get('/api/users/${widget.userId}', token: authProvider.accessToken),
        ApiService.get('/api/users/${widget.userId}/cars', token: authProvider.accessToken),
        ApiService.get('/api/users/${widget.userId}/clubs', token: authProvider.accessToken),
      ]);
      setState(() {
        _user = results[0] as Map<String, dynamic>;
        _cars = results[1] is List ? results[1] as List : [];
        _clubs = results[2] is List ? results[2] as List : [];
      });
      if (!_isMe) {
        try {
          final fs = await ApiService.get('/api/friends/status/${widget.userId}', token: authProvider.accessToken);
          if (mounted && fs is Map<String, dynamic>) {
            setState(() {
              _friendStatus = (fs['status'] as String?) ?? 'none';
              _friendshipId = fs['friendship_id'] as String?;
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleProfileLike() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post('/api/users/${widget.userId}/like', {}, token: authProvider.accessToken);
      if (!mounted) return;
      setState(() {
        _user!['is_liked'] = result['liked'];
        _user!['likes_count'] = result['likes_count'];
      });
      SoundPlayer.play(context, AppSound.click);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    }
  }

  Future<void> _openChat() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final room = await ApiService.post(
        '/api/chats/direct',
        {'user_id': widget.userId},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(roomId: room['id'], title: room['title'] ?? _user?['username'] ?? context.t('user_profile.chat_default_title')),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _friendActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post(
        '/api/friends/request/${widget.userId}',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _friendStatus = (result['status'] as String?) ?? 'pending_sent';
        _friendshipId = result['friendship_id'] as String?;
      });
      SoundPlayer.play(context, AppSound.click);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _friendActionLoading = false);
    }
  }

  Future<void> _acceptFriendRequest() async {
    if (_friendshipId == null) return;
    setState(() => _friendActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.post(
        '/api/friends/$_friendshipId/accept',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _friendStatus = (result['status'] as String?) ?? 'friends';
      });
      SoundPlayer.play(context, AppSound.click);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _friendActionLoading = false);
    }
  }

  Future<void> _declineOrCancelFriendRequest() async {
    if (_friendshipId == null) return;
    final fid = _friendshipId!;
    setState(() => _friendActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/friends/$fid/decline', {}, token: authProvider.accessToken);
      setState(() {
        _friendStatus = 'none';
        _friendshipId = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _friendActionLoading = false);
    }
  }

  Future<void> _removeFriend() async {
    if (_friendshipId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('user_profile.remove_friend_title')),
        content: Text(context.tArgs('user_profile.remove_friend_content', {'name': (_user?['username'] as String?) ?? context.t('user_profile.default_user')})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('common.delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || _friendshipId == null) return;
    final fid = _friendshipId!;
    setState(() => _friendActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/friends/$fid', token: authProvider.accessToken);
      setState(() {
        _friendStatus = 'none';
        _friendshipId = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('user_profile.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _friendActionLoading = false);
    }
  }

  Widget _friendButton() {
    if (_friendActionLoading) {
      return const SizedBox(
        height: 46,
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    switch (_friendStatus) {
      case 'friends':
        return SizedBox(
          height: 46,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _removeFriend,
            icon: const Icon(Icons.how_to_reg, color: AppColors.blue),
            label: Text(context.t('user_profile.friends_label')),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      case 'pending_sent':
        return SizedBox(
          height: 46,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _declineOrCancelFriendRequest,
            icon: const Icon(Icons.hourglass_top, color: Colors.grey),
            label: Text(context.t('user_profile.pending_sent_label')),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      case 'pending_received':
        return SizedBox(
          height: 46,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _acceptFriendRequest,
                  icon: const Icon(Icons.check),
                  label: Text(context.t('user_profile.accept_label')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _declineOrCancelFriendRequest,
                  icon: const Icon(Icons.close, color: AppColors.red),
                  label: Text(context.t('user_profile.decline_label')),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return SizedBox(
          height: 46,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendFriendRequest,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(context.t('user_profile.add_friend_label')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
    }
  }

  Widget _stat(num value, String label, {String Function(num)? formatter}) {
    final fmt = formatter ?? (v) => v.round().toString();
    return Column(
      children: [
        AnimatedCountText(
          end: value,
          formatter: fmt,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _carCard(Map<String, dynamic> car) {
    final photoUrl = car['photo_url'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car['id'])),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? Image.network(
                  resolveImageUrl(photoUrl),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _carPlaceholder(),
                )
              : _carPlaceholder(),
        ),
        title: Text('${car['make'] ?? ''} ${car['model'] ?? ''}'.trim(), overflow: TextOverflow.ellipsis, maxLines: 1),
        subtitle: Text(
          [car['year']?.toString(), car['color'], car['license_plate']]
              .where((v) => v != null && v.toString().isNotEmpty)
              .join(' · '),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: (car['is_primary'] ?? false) ? const Icon(Icons.star, color: Colors.orange, size: 18) : null,
      ),
    );
  }

  Widget _carPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade200,
      child: const Icon(Icons.directions_car, color: Colors.grey),
    );
  }

  Widget _achievementBadge(Achievement a) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    return Tooltip(
      message: '${a.title}\n${a.description}',
      child: Opacity(
        opacity: a.unlocked ? 1.0 : 0.45,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: a.unlocked ? Color.alphaBlend(Colors.amber.withOpacity(0.22), baseSurface) : baseSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: a.unlocked ? Colors.amber : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Text(a.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                a.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    GamificationStats? stats;
    List<Achievement> achievements = const [];
    if (_user != null) {
      final isClubLeader = _clubs.any((c) => c['role'] == 'owner' || c['role'] == 'admin');
      final isVerified = _user!['is_verified'] == true;
      final isPremium = _user!['is_premium'] == true;
      int accountAgeDays = 0;
      try {
        final createdAt = _user!['created_at'];
        if (createdAt != null) {
          accountAgeDays = DateTime.now().difference(DateTime.parse(createdAt.toString())).inDays;
        }
      } catch (_) {}
      final xp = computeXp(
        eventsAttended: (_user!['events_attended'] ?? 0) as int,
        eventsCreated: (_user!['events_created'] ?? 0) as int,
        carsCount: (_user!['cars_count'] ?? 0) as int,
        ratingsCount: (_user!['ratings_count'] ?? 0) as int,
        averageRating: ((_user!['average_rating'] ?? 0) as num).toDouble(),
        clubsCount: _clubs.length,
        referralsCount: 0,
        likesCount: (_user!['likes_count'] ?? 0) as int,
        isVerified: isVerified,
        isPremium: isPremium,
        bonusXp: (_user!['xp'] ?? 0) as int,
      );
      stats = computeStats(xp);
      achievements = buildAchievements(
        eventsAttended: (_user!['events_attended'] ?? 0) as int,
        eventsCreated: (_user!['events_created'] ?? 0) as int,
        carsCount: (_user!['cars_count'] ?? 0) as int,
        ratingsCount: (_user!['ratings_count'] ?? 0) as int,
        averageRating: ((_user!['average_rating'] ?? 0) as num).toDouble(),
        clubsCount: _clubs.length,
        isClubLeader: isClubLeader,
        referralsCount: 0,
        likesCount: (_user!['likes_count'] ?? 0) as int,
        isVerified: isVerified,
        isPremium: isPremium,
        accountAgeDays: accountAgeDays,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user != null ? '@${_user!['username']}' : context.t('user_profile.title_fallback'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
        actions: [
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.bolt, color: Colors.amber),
              tooltip: context.t('profile_boost.title'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileBoostScreen())),
            ),
          if (!_isMe)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: context.t('user_profile.report_tooltip'),
              onPressed: () => showReportDialog(context, targetType: 'user', targetId: widget.userId),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: AppLoader())
          : _user == null
              ? Center(child: Text(context.t('user_profile.user_not_found')))
              : RefreshIndicator(
                  color: AppColors.red,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              EquippedAvatar(
                                avatarUrl: _user!['avatar_url'] as String?,
                                fallbackLetter: (_user!['username'] as String).isNotEmpty
                                    ? _user!['username'][0].toUpperCase()
                                    : 'U',
                                radius: 45,
                                equippedFrame: _user!['equipped_frame'] as String?,
                                equippedBadge: _user!['equipped_badge'] as String?,
                                isOnline: _user!['is_online'] == true,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _user!['full_name'] ?? _user!['username'],
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: nameColorFor(_user!['equipped_name_color'] as String?),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_user!['is_verified'] == true) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(message: context.t('user_profile.verified_tooltip'), child: const Icon(Icons.verified, color: AppColors.blue, size: 20)),
                                  ],
                                  if (_user!['is_admin'] == true) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(message: context.t('user_profile.admin_tooltip'), child: const Icon(Icons.shield, color: AppColors.red, size: 20)),
                                  ],
                                  if (_user!['is_premium'] == true) ...[
                                    const SizedBox(width: 6),
                                    const Tooltip(message: 'CarSpot Premium', child: Icon(Icons.workspace_premium, color: Colors.amber, size: 20)),
                                  ],
                                  if (_clubs.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: '${_clubs.first['name'] ?? context.t('user_profile.club_fallback')}',
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.blue.withOpacity(0.15),
                                        backgroundImage: ((_clubs.first['logo_url'] as String?) ?? '').isNotEmpty
                                            ? NetworkImage(resolveImageUrl(_clubs.first['logo_url']))
                                            : null,
                                        child: ((_clubs.first['logo_url'] as String?) ?? '').isEmpty
                                            ? const Icon(Icons.groups, size: 12, color: AppColors.blue)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text('@${_user!['username']}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 4),
                              if ((_user!['city'] ?? '').toString().isNotEmpty ||
                                  (_user!['country'] ?? '').toString().isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      [_user!['city'], _user!['country']]
                                          .where((v) => v != null && v.toString().isNotEmpty)
                                          .join(', '),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!_isMe)
                          SizedBox(
                            height: 46,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openChat,
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: Text(context.t('user_profile.write_message_label')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.blue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _toggleProfileLike,
                                  icon: AnimatedScale(
                                    scale: _user!['is_liked'] == true ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    child: Icon(
                                      _user!['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                                      color: AppColors.red,
                                    ),
                                  ),
                                  label: Text('${_user!['likes_count'] ?? 0}'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!_isMe) ...[
                          const SizedBox(height: 10),
                          _friendButton(),
                        ],
                        const SizedBox(height: 20),

                        if (stats != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(AppColors.blue.withOpacity(0.25), cardSurface),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onLongPress: () {
                                        HapticFeedback.mediumImpact();
                                        final jokes = [
                                          context.t('user_profile.joke_1'),
                                          context.t('user_profile.joke_2'),
                                          context.t('user_profile.joke_3'),
                                        ];
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(jokes[Random().nextInt(jokes.length)])),
                                        );
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: AnimatedCountText(
                                          end: stats.level,
                                          formatter: (v) => '${v.round()}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tArgs('user_profile.level_title', {'level': '${stats.level}', 'title': '${stats.levelTitle}'}),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: cardText),
                                          ),
                                          AnimatedCountText(
                                            end: stats.xp,
                                            formatter: (v) => context.tArgs('user_profile.xp_total', {'xp': '${v.round()}'}),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: stats.progress,
                                    minHeight: 8,
                                    backgroundColor: AppColors.blue.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat((_user!['cars_count'] ?? 0) as num, context.t('user_profile.stat_cars')),
                            _stat((_user!['events_attended'] ?? 0) as num, context.t('user_profile.stat_meetups')),
                            _stat((_user!['average_rating'] ?? 0) as num, context.t('user_profile.stat_rating'), formatter: (v) => '${v.toStringAsFixed(1)}⭐'),
                          ],
                        ),

                        if ((_user!['bio'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
                              final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.steel),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.t('user_profile.about_title'), style: TextStyle(fontWeight: FontWeight.w800, color: cardText)),
                                    const SizedBox(height: 8),
                                    Text(_user!['bio'], style: TextStyle(color: cardText.withOpacity(0.85))),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        if (_clubs.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(context.t('user_profile.clubs_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _clubs.map<Widget>((c) {
                              final role = c['role'] as String?;
                              final roleLabel = role == 'owner' ? ' · ${context.t('user_profile.role_owner')}' : (role == 'admin' ? ' · ${context.t('user_profile.role_admin')}' : '');
                              return Chip(
                                avatar: const Icon(Icons.groups, size: 16, color: AppColors.blue),
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text('${c['name']}$roleLabel', overflow: TextOverflow.ellipsis),
                                ),
                                backgroundColor: AppColors.blue.withOpacity(0.08),
                              );
                            }).toList(),
                          ),
                        ],

                        if (_cars.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(context.t('user_profile.garage_section_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._cars.map((c) => _carCard(c as Map<String, dynamic>)),
                        ],

                        const SizedBox(height: 20),
                        Text(context.t('user_profile.achievements_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: achievements.map((a) => _achievementBadge(a)).toList(),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}
