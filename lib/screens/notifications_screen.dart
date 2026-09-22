import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import 'club_detail_screen.dart';
import 'event_details_screen.dart';
import 'user_profile_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Лента уведомлений: заявки в друзья, лайки профиля, кто присоединился
/// к сходке, комментарии — всё в одном месте.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/notifications/', token: authProvider.accessToken);
      final items = response is Map<String, dynamic> && response['items'] is List ? response['items'] as List : [];
      setState(() => _items = items);
      await ApiService.post('/api/notifications/read-all', {}, token: authProvider.accessToken);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('notifications.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add_alt_1;
      case 'friend_accepted':
        return Icons.how_to_reg;
      case 'profile_like':
        return Icons.favorite;
      case 'event_join':
        return Icons.directions_car;
      case 'comment_event':
      case 'comment_photo':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'profile_like':
        return AppColors.red;
      case 'friend_request':
      case 'friend_accepted':
        return AppColors.blue;
      case 'event_join':
        return Colors.green;
      default:
        return Colors.amber;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return context.t('notifications.time_now');
      if (diff.inMinutes < 60) return context.tArgs('notifications.time_minutes', {'count': '${diff.inMinutes}'});
      if (diff.inHours < 24) return context.tArgs('notifications.time_hours', {'count': '${diff.inHours}'});
      return context.tArgs('notifications.time_days', {'count': '${diff.inDays}'});
    } catch (_) {
      return '';
    }
  }

  void _openTarget(Map<String, dynamic> n) {
    final targetType = n['target_type'] as String?;
    final targetId = n['target_id'] as String?;
    final actor = n['actor'] as Map<String, dynamic>?;

    if (targetType == 'event' && targetId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: {'id': targetId})));
    } else if (targetType == 'club' && targetId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: targetId)));
    } else if (actor != null && actor['id'] != null) {
      // заявки в друзья / лайки — ведём в профиль того, кто это сделал
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: actor['id'] as String)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('notifications.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/chats.jpg'),
          Theme(
            data: AppTheme.dark,
            child: _isLoading
                ? Center(child: AppLoader())
                : RefreshIndicator(
                    color: AppColors.red,
                    backgroundColor: AppColors.surfaceDark,
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(context.t('notifications.empty'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final n = _items[index] as Map<String, dynamic>;
                              final type = (n['type'] as String?) ?? '';
                              final isRead = n['is_read'] == true;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _colorFor(type).withOpacity(0.15),
                                  child: Icon(_iconFor(type), color: _colorFor(type)),
                                ),
                                title: Text(
                                  (n['message'] as String?) ?? '',
                                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                                ),
                                subtitle: Text(_formatTime((n['created_at'] as String?) ?? '')),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                                      )
                                    : null,
                                onTap: () => _openTarget(n),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
