import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/event_duration.dart';
import '../utils/event_type_style.dart';
import '../utils/map_config.dart';
import '../utils/maps_launcher.dart';
import '../widgets/report_dialog.dart';
import 'chat_room_screen.dart';
import 'edit_event_screen.dart';
import 'premium_screen.dart';
import 'photo_gallery_screen.dart';
import 'user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/comments_section.dart';
import '../utils/sound_player.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Map<String, dynamic> _event;
  bool _isJoined = false;
  bool _isLoading = false;
  bool _isLoadingDetail = true;
  List<dynamic> _participants = [];
  List<dynamic> _ratings = [];
  bool _showRatingForm = false;
  int _myRating = 0;
  TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Стартуем с того, что передали со списка (чтобы не было пустого экрана),
    // но is_joined в списке сходок не считается — поэтому сразу подгружаем
    // свежую карточку с сервера в _loadEventDetail().
    _event = Map<String, dynamic>.from(widget.event);
    _isJoined = widget.event['is_joined'] ?? false;
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEventDetail();
    await _loadParticipants();
    await _loadRatings();
  }

  // Настоящий источник правды по is_joined, average_rating, participants_count и т.д.
  // Список сходок (home) этого не содержит, поэтому при каждом открытии экрана
  // нужно спрашивать карточку события отдельно.
  Future<void> _loadEventDetail() async {
    setState(() => _isLoadingDetail = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/events/${widget.event['id']}',
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _event = response;
        _isJoined = response['is_joined'] ?? false;
      });
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasFavorite = _event['is_favorite'] == true;
    try {
      if (wasFavorite) {
        await ApiService.delete('/api/events/${widget.event['id']}/favorite', token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/events/${widget.event['id']}/favorite', {}, token: authProvider.accessToken);
      }
      if (mounted) setState(() => _event['is_favorite'] = !wasFavorite);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/events/${widget.event['id']}/participants',
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _participants = response is List ? response : [];
      });
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadRatings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/ratings/events/${widget.event['id']}',
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _ratings = response is List ? response : [];
      });
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  bool _isBoosted() {
    final until = _event['boosted_until'];
    if (until == null) return false;
    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _boostEvent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      final goPremium = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Только для Premium'),
          content: const Text('Поднимать сходку в топ ленты могут только подписчики CarSpot Premium.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Узнать больше')),
          ],
        ),
      );
      if (goPremium == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
      }
      return;
    }
    try {
      final response = await ApiService.post(
        '/api/events/${widget.event['id']}/boost',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      setState(() => _event = response);
      SoundPlayer.play(context, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сходка поднята в топ ленты на 24 часа 🚀')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _joinEvent() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/events/${widget.event['id']}/join',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ты присоединился! 🎉')),
      );
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveEvent() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/events/${widget.event['id']}/leave',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ты покинул сходку')),
      );
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEventScreen(event: _event)),
    );
    if (result == 'deleted') {
      if (mounted) Navigator.pop(context, true);
    } else if (result == true) {
      _loadData();
    }
  }

  Future<void> _openDirectChat(String userId, String username) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final room = await ApiService.post(
        '/api/chats/direct',
        {'user_id': userId},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: room['id'],
            title: room['title'] ?? username,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _submitRating() async {
    if (_myRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выбери оценку')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/ratings/events',
        {
          'event_id': widget.event['id'],
          'rating': _myRating,
          'review': _reviewController.text.isEmpty ? null : _reviewController.text,
          'atmosphere_rating': _myRating,
          'organization_rating': _myRating,
          'location_rating': _myRating,
        },
        token: authProvider.accessToken,
      );

      if (!mounted) return;
      setState(() {
        _showRatingForm = false;
        _myRating = 0;
        _reviewController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спасибо за оценку! ⭐')),
      );
      _loadRatings();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали сходки'),
        elevation: 0,
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: Icon(
              _event['is_favorite'] == true ? Icons.favorite : Icons.favorite_border,
              color: _event['is_favorite'] == true ? AppColors.red : null,
            ),
            tooltip: 'В избранное',
            onPressed: _toggleFavorite,
          ),
          if (_isJoined && _event['chat_room_id'] != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble),
              tooltip: 'Чат сходки',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      roomId: _event['chat_room_id'],
                      title: 'Чат: ${_event['title'] ?? 'сходка'}',
                    ),
                  ),
                );
              },
            ),
          if (_event['is_creator'] == true)
            IconButton(
              icon: Icon(Icons.rocket_launch, color: _isBoosted() ? Colors.amber : null),
              tooltip: _isBoosted() ? 'Сходка в топе' : 'Поднять в топ ленты (Premium)',
              onPressed: _isBoosted() ? null : _boostEvent,
            ),
          if (_event['is_creator'] == true)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Изменить сходку',
              onPressed: _openEdit,
            ),
          if (_event['is_creator'] != true)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Пожаловаться',
              onPressed: () => showReportDialog(context, targetType: 'event', targetId: _event['id']),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название и тип
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _event['title'] ?? 'Без названия',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_event['event_type'] ?? 'meetup'),
                ),
              ],
            ),
            if (_event['is_private'] == true) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.lock, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text('Закрытая сходка · только для клуба', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ],
            if (_event['is_cancelled'] == true || _event['is_active'] == false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_busy, size: 14, color: AppColors.red),
                  const SizedBox(width: 4),
                  Text(
                    _event['is_cancelled'] == true ? 'Сходка отменена' : 'Сходка завершилась',
                    style: const TextStyle(fontSize: 12, color: AppColors.red),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 15),

            // Рейтинг
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < ((_event['average_rating'] as num?) ?? 0).toInt() ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 20,
                  );
                }),
                const SizedBox(width: 10),
                Text(
                  '${_event['average_rating'] ?? 0} (${_event['ratings_count'] ?? 0} оценок)',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Информация
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Дата и время',
              value: '${_event['event_date']} ${_event['event_time']}'
                  '${_event['duration_minutes'] != null ? " · ${formatEventDuration(_event['duration_minutes'] as int)}" : ""}',
            ),
            const SizedBox(height: 10),

            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Место',
              value: '${_event['city']}, ${_event['location_name']}',
              trailing: (_event['latitude'] != null && _event['longitude'] != null)
                  ? IconButton(
                      icon: const Icon(Icons.directions, color: AppColors.blue),
                      tooltip: 'Маршрут в Google Maps',
                      onPressed: () => openDirections(
                        context,
                        (_event['latitude'] as num).toDouble(),
                        (_event['longitude'] as num).toDouble(),
                      ),
                    )
                  : null,
            ),
            if (_event['latitude'] != null && _event['longitude'] != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 160,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (_event['latitude'] as num).toDouble(),
                        (_event['longitude'] as num).toDouble(),
                      ),
                      initialZoom: defaultMapZoom,
                    ),
                    children: [
                      TileLayer(urlTemplate: osmTileUrlTemplate, userAgentPackageName: mapUserAgentPackageName),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              (_event['latitude'] as num).toDouble(),
                              (_event['longitude'] as num).toDouble(),
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              eventTypeIcon(_event['event_type']),
                              color: eventTypeColor(_event['event_type']),
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),

            _buildInfoCard(
              icon: Icons.people,
              title: 'Участники',
              value: '${_event['participants_count'] ?? 0}'
                  '${_onlineCount > 0 ? " ($_onlineCount онлайн)" : ""}',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoGalleryScreen(
                      eventId: _event['id'],
                      title: 'Фото сходки',
                    ),
                  ),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('Фото сходки${(_event['photos_count'] ?? 0) > 0 ? " (${_event['photos_count']})" : ""}'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Описание
            const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_event['description'] ?? 'Нет описания'),
            const SizedBox(height: 30),

            // Участники
            Row(
              children: [
                const Text('Участники', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(${_participants.length})', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            _participants.isEmpty
              ? const Text('Пока никто не присоединился')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final p = _participants[index];
                    final user = p['user'] as Map<String, dynamic>?;
                    final avatarUrl = user?['avatar_url'] as String?;
                    final username = user?['username'] as String? ?? 'Неизвестный';
                    final isVerified = user?['is_verified'] == true;
                    final isOnline = user?['is_online'] == true;
                    final rating = user?['average_rating'] ?? 0;
                    final userId = user?['id'] as String?;
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final isMe = userId != null && userId == authProvider.user?['id'];

                    return ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'U')
                                : null,
                          ),
                          // Зелёная точка "онлайн"
                          if (isOnline)
                            Positioned(
                              right: -2,
                              bottom: -2,
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
                      title: Row(
                        children: [
                          Flexible(child: Text(username, overflow: TextOverflow.ellipsis)),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.blue, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        isOnline
                            ? 'Онлайн · ⭐ $rating'
                            : '⭐ $rating',
                        style: TextStyle(color: isOnline ? Colors.green : Colors.grey),
                      ),
                      trailing: isMe || userId == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.blue),
                              tooltip: 'Написать',
                              onPressed: () => _openDirectChat(userId, username),
                            ),
                      onTap: userId == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
                              );
                            },
                    );
                  },
                ),
            const SizedBox(height: 30),

            // Рейтинги
            const Text('Отзывы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _ratings.isEmpty
              ? const Text('Нет отзывов')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ratings.length,
                  itemBuilder: (context, index) {
                    final rating = _ratings[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rating['username'] ?? 'Неизвестный'),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < (rating['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                      color: Colors.orange,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (rating['review'] != null) ...[
                              const SizedBox(height: 5),
                              Text(rating['review'], style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

            const SizedBox(height: 20),

            // Кнопки действия
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || _isLoadingDetail || _isEventOver)
                    ? null
                    : (_isJoined ? _leaveEvent : _joinEvent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isJoined ? AppColors.red : AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: (_isLoading || _isLoadingDetail)
                  ? AppLoader(size: 22, color: Colors.white)
                  : Text(
                      _isEventOver
                          ? (_event['is_cancelled'] == true ? 'Сходка отменена' : 'Сходка завершилась')
                          : (_isJoined ? 'Покинуть сходку' : 'Присоединиться'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
              ),
            ),

            const SizedBox(height: 15),

            // Кнопка оценки
            if (_isJoined)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showRatingForm = !_showRatingForm);
                  },
                  icon: const Icon(Icons.star),
                  label: Text(_showRatingForm ? 'Скрыть оценку' : 'Оценить сходку'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

            // Форма оценки
            if (_showRatingForm && _isJoined) ...[
              const SizedBox(height: 20),
              const Text('Оцени сходку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _myRating = index + 1),
                    child: Icon(
                      _myRating > index ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Твой отзыв (опционально)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Отправить оценку', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Комментарии
            const Text('Комментарии', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 340,
              child: CommentsSection(
                targetType: 'event',
                targetId: widget.event['id'].toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isEventOver => _event['is_cancelled'] == true || _event['is_active'] == false;

  int get _onlineCount => _participants.where((p) {
        final user = p['user'] as Map<String, dynamic>?;
        return user?['is_online'] == true;
      }).length;

  Widget _buildInfoCard({required IconData icon, required String title, required String value, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
