import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_room_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<dynamic> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/chats/', token: authProvider.accessToken);
      setState(() => _rooms = response is List ? response : []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('chats_list.error_message', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _roomTitle(Map<String, dynamic> room) {
    final title = room['title'] as String?;
    if (title != null && title.isNotEmpty) return title;
    switch (room['room_type']) {
      case 'event':
        return context.t('chats_list.event_chat');
      case 'club':
        return context.t('chats_list.club_chat');
      default:
        return context.t('chats_list.direct_chat');
    }
  }

  IconData _roomIcon(String? type) {
    switch (type) {
      case 'event':
        return Icons.directions_car;
      case 'club':
        return Icons.groups;
      default:
        return Icons.person;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('chats_list.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/chats.jpg'),
          Theme(data: AppTheme.dark, child: _isLoading
          ? Center(child: AppLoader())
          : RefreshIndicator(
              color: AppColors.red,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _loadRooms,
              child: _rooms.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(context.t('chats_list.empty_title'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              context.t('chats_list.empty_subtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final room = _rooms[index] as Map<String, dynamic>;
                        final unread = (room['unread_count'] as int?) ?? 0;
                        final onlineCount = (room['other_online_count'] as int?) ?? 0;
                        final hasUnread = unread > 0;
                        return ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.blue.withOpacity(0.15),
                                child: Icon(_roomIcon(room['room_type'] as String?), color: AppColors.blue),
                              ),
                              if (onlineCount > 0)
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            _roomTitle(room),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Text(
                            room['last_message_text'] ?? context.t('chats_list.no_messages'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              color: hasUnread ? AppColors.textOnDark : Colors.grey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(room['last_message_at'] as String?),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              if (hasUnread) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  roomId: room['id'],
                                  title: _roomTitle(room),
                                ),
                              ),
                            ).then((_) => _loadRooms());
                          },
                        );
                      },
                    ),
            )),
        ],
      ),
    );
  }
}
