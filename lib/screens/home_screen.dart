import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/gamification.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'garage_screen.dart';
import 'chats_list_screen.dart';
import 'clubs_list_screen.dart';
import 'businesses_list_screen.dart';
import 'events_map_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'premium_screen.dart';
import 'notifications_screen.dart';
import 'friends_list_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_panel_screen.dart';
import 'achievements_screen.dart';
import 'favorites_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/section_background.dart';
import '../widgets/neon_chip.dart';
import '../widgets/animated_counter.dart';
import '../widgets/stories_bar.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/animated_bottom_nav.dart';
import '../utils/sound_player.dart';
import '../utils/event_category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];
  bool _isLoading = false;
  int _unreadNotifications = 0;
  Timer? _notificationsTimer;
  String _searchQuery = '';
  String _selectedType = 'all';

  final List<String> _eventTypes = [
    'all', 'meetup', 'racing', 'drift', 'drag', 'offroad', 'show', 'cruise', 'track_day', 'charity'
  ];

  List<dynamic> _myClubs = [];
  List<dynamic> _myCars = [];
  Map<String, dynamic>? _referral;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadMyCars();
    Future.wait([_loadMyClubs(), _loadReferral()]).then((_) => _checkGamificationProgress());
    _loadUnreadNotifications();
    _notificationsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadNotifications());
  }

  @override
  void dispose() {
    _notificationsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await ApiService.get('/api/notifications/unread-count', token: authProvider.accessToken);
      if (mounted) setState(() => _unreadNotifications = (result['unread_count'] as int?) ?? 0);
    } catch (_) {
      // тихо игнорируем — счётчик не критичен
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadUnreadNotifications());
  }

  bool _isBoosted(dynamic until) {
    if (until == null) return false;
    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  int _accountAgeDays(dynamic createdAt) {
    if (createdAt == null) return 0;
    try {
      final created = DateTime.parse(createdAt.toString());
      return DateTime.now().difference(created).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Сравнивает текущий уровень/достижения с тем, что видели в прошлый раз
  /// (сохранено локально), и показывает уведомление при новом уровне или
  /// новом разблокированном достижении. Ничего не шлёт на сервер — всё
  /// считается из уже загруженной статистики профиля.
  Future<void> _checkGamificationProgress() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final isClubLeader = _myClubs.any((c) => c['role'] == 'owner' || c['role'] == 'admin');
    final referralsCount = (_referral?['referrals_count'] ?? 0) as int;

    final xp = computeXp(
      eventsAttended: (user['events_attended'] ?? 0) as int,
      eventsCreated: (user['events_created'] ?? 0) as int,
      carsCount: (user['cars_count'] ?? 0) as int,
      ratingsCount: (user['ratings_count'] ?? 0) as int,
      averageRating: ((user['average_rating'] ?? 0) as num).toDouble(),
      clubsCount: _myClubs.length,
      referralsCount: referralsCount,
      likesCount: (user['likes_count'] ?? 0) as int,
      isVerified: user['is_verified'] == true,
      isPremium: user['is_premium'] == true,
    );
    final stats = computeStats(xp);
    final achievements = buildAchievements(
      eventsAttended: (user['events_attended'] ?? 0) as int,
      eventsCreated: (user['events_created'] ?? 0) as int,
      carsCount: (user['cars_count'] ?? 0) as int,
      ratingsCount: (user['ratings_count'] ?? 0) as int,
      averageRating: ((user['average_rating'] ?? 0) as num).toDouble(),
      clubsCount: _myClubs.length,
      isClubLeader: isClubLeader,
      referralsCount: referralsCount,
      likesCount: (user['likes_count'] ?? 0) as int,
      isVerified: user['is_verified'] == true,
      isPremium: user['is_premium'] == true,
      accountAgeDays: _accountAgeDays(user['created_at']),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final initialized = prefs.getBool('gamification_initialized') ?? false;
      final unlockedNow = achievements.where((a) => a.unlocked).map((a) => a.title).toSet();

      if (!initialized) {
        // Первый запуск с этой функцией — фиксируем текущий прогресс без уведомлений,
        // чтобы не засыпать пользователя достижениями, которые он уже давно заслужил.
        await prefs.setStringList('unlocked_achievements', unlockedNow.toList());
        await prefs.setInt('seen_level', stats.level);
        await prefs.setBool('gamification_initialized', true);
        return;
      }

      final seenTitles = (prefs.getStringList('unlocked_achievements') ?? []).toSet();
      final seenLevel = prefs.getInt('seen_level') ?? 1;
      final newlyUnlocked = unlockedNow.difference(seenTitles);

      if (!mounted) return;

      if (stats.level > seenLevel) {
        SoundPlayer.play(context, AppSound.levelUp);
        await showCelebration(
          context,
          emoji: '🏁',
          title: 'Новый уровень ${stats.level}!',
          subtitle: stats.levelTitle,
        );
        await prefs.setInt('seen_level', stats.level);
      }

      if (newlyUnlocked.isNotEmpty) {
        for (final title in newlyUnlocked) {
          final a = achievements.firstWhere((x) => x.title == title);
          if (!mounted) return;
          SoundPlayer.play(context, AppSound.levelUp);
          await showCelebration(
            context,
            emoji: a.emoji,
            title: 'Новое достижение!',
            subtitle: a.title,
          );
        }
        await prefs.setStringList('unlocked_achievements', unlockedNow.union(seenTitles).toList());
      }
    } catch (e) {
      print('Ошибка гамификации: $e');
    }
  }

  Future<void> _loadMyClubs() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final myId = authProvider.user?['id'];
      if (myId == null) return;
      final response = await ApiService.get('/api/users/$myId/clubs', token: authProvider.accessToken);
      setState(() => _myClubs = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadMyCars() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/cars/my', token: authProvider.accessToken);
      setState(() => _myCars = response['cars'] ?? []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadReferral() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/users/me/referral', token: authProvider.accessToken);
      setState(() => _referral = response is Map<String, dynamic> ? response : null);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/events/?limit=100',
        token: authProvider.accessToken,
      );
      setState(() {
        _events = response['items'] ?? [];
        _filterEvents();
      });
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterEvents() {
    _filteredEvents = _events.where((event) {
      bool matchesSearch = event['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesType = _selectedType == 'all' || event['event_type'] == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    _filteredEvents.sort((a, b) => b['average_rating'].compareTo(a['average_rating']));
  }

  Future<void> _toggleEventFavorite(Map event) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasFavorite = event['is_favorite'] == true;
    setState(() => event['is_favorite'] = !wasFavorite);
    try {
      if (wasFavorite) {
        await ApiService.delete('/api/events/${event['id']}/favorite', token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/events/${event['id']}/favorite', {}, token: authProvider.accessToken);
      }
    } catch (e) {
      if (mounted) {
        setState(() => event['is_favorite'] = wasFavorite);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            SoundPlayer.play(context, AppSound.success);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🏁 Полный газ! Увидимся на трассе')),
            );
          },
          child: const Text('CarSpot'),
        ),
        elevation: 0,
        backgroundColor: AppColors.black,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Карта сходок',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventsMapScreen()),
                );
              },
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Уведомления',
                onPressed: _openNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SectionBackground(
            accent: _selectedIndex == 3 ? AppColors.blue : AppColors.red,
            glowAlignment: _selectedIndex == 3 ? Alignment.topLeft : Alignment.topRight,
            imageAsset: _selectedIndex == 3
                ? 'assets/backgrounds/profile.jpg'
                : 'assets/backgrounds/events.jpg',
          ),
          Theme(data: AppTheme.dark, child: _buildBody()),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.blue.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
                if (result == true) {
                  _loadEvents();
                }
              },
              backgroundColor: AppColors.blue,
              child: const Icon(Icons.add),
            ),
          )
        : null,
      // Нижняя навигация сведена к 4 самым частым разделам (было 7 — тесно
      // и терялось на маленьких экранах). Клубы, Настройки и Сервисы
      // переехали в аккуратную сетку быстрых действий на экране "Профиль",
      // рядом с "Друзьями" — так внизу остаётся только самое частое,
      // а остальное — на расстоянии одного тапа с анимацией нажатия.
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        items: const [
          NavBarItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Сходки'),
          NavBarItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: 'Гараж'),
          NavBarItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Чаты'),
          NavBarItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Профиль'),
        ],
        onTap: (index) {
          // У "Гаража" и "Чатов" свой AppBar (и своя кнопка "+" у гаража),
          // поэтому открываем их отдельным экраном, а не как вкладку —
          // иначе была бы двойная шапка. Подсветка текущей вкладки не меняется.
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GarageScreen()),
            ).then((_) => _loadMyCars());
            return;
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatsListScreen()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildEventsTab();
      case 3: return _buildProfileTab();
      default: return _buildEventsTab();
    }
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Истории (24ч)
        const StoriesBar(),

        // Поиск
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterEvents();
              });
            },
            decoration: InputDecoration(
              hintText: 'Поиск сходок...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        // Фильтр по типу
        SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            scrollDirection: Axis.horizontal,
            itemCount: eventCategories.length,
            itemBuilder: (context, index) {
              final c = eventCategories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NeonChip(
                  label: c.label,
                  icon: c.icon,
                  color: c.color,
                  selected: _selectedType == c.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedType = c.value;
                      _filterEvents();
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Список сходок
        Expanded(
          child: _isLoading
            ? Center(child: AppLoader())
            : _filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Сходок не найдено'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadEvents,
                        child: const Text('Обновить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.red,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              ((event['event_type'] as String?) ?? '').isNotEmpty
                                  ? (event['event_type'] as String)[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Row(
                            children: [
                              if (_isBoosted(event['boosted_until'])) ...[
                                const Text('🚀', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  event['title'] ?? 'Без названия',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${event['city']}, ${event['event_date']}\n'
                            'Участников: ${event['participants_count']}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _toggleEventFavorite(event),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    event['is_favorite'] == true ? Icons.favorite : Icons.favorite_border,
                                    color: event['is_favorite'] == true ? AppColors.red : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Text('⭐ ${event['average_rating']}'),
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
color: (event['is_joined'] ?? false) ? Colors.green : Colors.grey,                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
(event['is_joined'] ?? false) ? 'Участвую' : 'Нет',                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsScreen(event: event),
                              ),
                            ).then((_) {
                              _loadEvents();
                              _loadMyClubs();
                              _loadMyCars();
                              _loadReferral();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _miniCarCard(Map<String, dynamic> car) {
    final photoUrl = car['photo_url'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? Image.network(
                  photoUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _carPlaceholder(),
                )
              : _carPlaceholder(),
        ),
        title: Text('${car['make'] ?? ''} ${car['model'] ?? ''}'.trim()),
        subtitle: Text(
          [car['year']?.toString(), car['color'], car['license_plate']]
              .where((v) => v != null && v.toString().isNotEmpty)
              .join(' · '),
        ),
        trailing: (car['is_primary'] ?? false) ? const Icon(Icons.star, color: Colors.orange, size: 18) : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GarageScreen()),
        ).then((_) => _loadMyCars()),
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
    // Цвет подложки и текста берём от актуальной темы, а не хардкодим —
    // иначе на тёмном фоне (или в тёмной теме) текст сливается с плиткой.
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

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    if (user == null) return Center(child: AppLoader());

    final isClubLeader = _myClubs.any((c) => c['role'] == 'owner' || c['role'] == 'admin');
    final referralsCount = (_referral?['referrals_count'] ?? 0) as int;
    final isVerified = user['is_verified'] == true;
    final isPremium = user['is_premium'] == true;
    final accountAgeDays = _accountAgeDays(user['created_at']);
    final xp = computeXp(
      eventsAttended: (user['events_attended'] ?? 0) as int,
      eventsCreated: (user['events_created'] ?? 0) as int,
      carsCount: (user['cars_count'] ?? 0) as int,
      ratingsCount: (user['ratings_count'] ?? 0) as int,
      averageRating: ((user['average_rating'] ?? 0) as num).toDouble(),
      clubsCount: _myClubs.length,
      referralsCount: referralsCount,
      likesCount: (user['likes_count'] ?? 0) as int,
      isVerified: isVerified,
      isPremium: isPremium,
    );
    final stats = computeStats(xp);
    final achievements = buildAchievements(
      eventsAttended: (user['events_attended'] ?? 0) as int,
      eventsCreated: (user['events_created'] ?? 0) as int,
      carsCount: (user['cars_count'] ?? 0) as int,
      ratingsCount: (user['ratings_count'] ?? 0) as int,
      averageRating: ((user['average_rating'] ?? 0) as num).toDouble(),
      clubsCount: _myClubs.length,
      isClubLeader: isClubLeader,
      referralsCount: referralsCount,
      likesCount: (user['likes_count'] ?? 0) as int,
      isVerified: isVerified,
      isPremium: isPremium,
      accountAgeDays: accountAgeDays,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (user['avatar_url'] != null && (user['avatar_url'] as String).isNotEmpty)
                ? NetworkImage(user['avatar_url'])
                : null,
            child: (user['avatar_url'] == null || (user['avatar_url'] as String).isEmpty)
                ? Text(
                    (user['full_name'] as String?)?.substring(0, 1) ?? 'U',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user['full_name'] ?? 'Неизвестный',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (user['is_verified'] == true) ...[
                const SizedBox(width: 6),
                const Tooltip(message: 'Подтверждённый аккаунт', child: Icon(Icons.verified, color: AppColors.blue, size: 20)),
              ],
              if (user['is_admin'] == true) ...[
                const SizedBox(width: 6),
                const Tooltip(message: 'Администратор', child: Icon(Icons.shield, color: AppColors.red, size: 20)),
              ],
              if (user['is_premium'] == true) ...[
                const SizedBox(width: 6),
                const Tooltip(message: 'CarSpot Premium', child: Icon(Icons.workspace_premium, color: Colors.amber, size: 20)),
              ],
              if (_myClubs.isNotEmpty) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: '${_myClubs.first['name'] ?? 'Клуб'}',
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.blue.withOpacity(0.15),
                    backgroundImage: ((_myClubs.first['logo_url'] as String?) ?? '').isNotEmpty
                        ? NetworkImage(_myClubs.first['logo_url'])
                        : null,
                    child: ((_myClubs.first['logo_url'] as String?) ?? '').isEmpty
                        ? const Icon(Icons.groups, size: 12, color: AppColors.blue)
                        : null,
                  ),
                ),
              ],
            ],
          ),
          Text(
            '@${user['username'] ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${user['city'] ?? ''}, ${user['country'] ?? ''}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (result == true) setState(() {});
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Редактировать профиль'),
          ),

          const SizedBox(height: 6),
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
                        SoundPlayer.play(context, AppSound.click);
                        final jokes = [
                          '🔧 Ещё немного и ты уже мастер дрифта',
                          '🏁 Скоро обгонишь всех на трассе',
                          '⚡ Уровень растёт быстрее, чем цены на бензин',
                          '🚗 Продолжай в том же духе, гонщик',
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
                            'Уровень ${stats.level} · ${stats.levelTitle}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: cardText),
                          ),
                          AnimatedCountText(
                            end: stats.xp,
                            formatter: (v) => '${v.round()} XP всего',
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
                const SizedBox(height: 4),
                AnimatedCountText(
                  end: stats.xpIntoLevel,
                  formatter: (v) => '${v.round()} / ${stats.xpForNextLevel} XP до следующего уровня',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GarageScreen()),
                ).then((_) => _loadMyCars()),
                child: Column(children: [
                  AnimatedCountText(
                    end: (user['cars_count'] ?? 0) as num,
                    formatter: (v) => '${v.round()}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text('Авто', style: TextStyle(decoration: TextDecoration.underline)),
                ]),
              ),
              Column(children: [
                AnimatedCountText(
                  end: (user['events_attended'] ?? 0) as num,
                  formatter: (v) => '${v.round()}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text('Сходок'),
              ]),
              Column(children: [
                AnimatedCountText(
                  end: (user['average_rating'] ?? 0) as num,
                  formatter: (v) => '${v.toStringAsFixed(1)}⭐',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text('Рейтинг'),
              ]),
            ],
          ),

          // Сетка быстрых действий — сюда переехали "Друзья" (раньше жили
          // в Настройках), "Клубы", "Лидеры", "Сервисы" и "Настройки" из
          // прежней тесной нижней навигации. Каждая плитка — с тактильной
          // анимацией нажатия (см. AnimatedMenuTile).
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Меню', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cardText)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 78,
                child: AnimatedMenuTile(
                  icon: Icons.people,
                  label: 'Друзья',
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
                  label: 'Клубы',
                  color: AppColors.blue,
                  badge: _myClubs.isNotEmpty ? '${_myClubs.length}' : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClubsListScreen()),
                  ).then((_) => _loadMyClubs()),
                ),
              ),
              SizedBox(
                width: 78,
                child: AnimatedMenuTile(
                  icon: Icons.emoji_events,
                  label: 'Лидеры',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  ),
                ),
              ),
              SizedBox(
                width: 78,
                child: AnimatedMenuTile(
                  icon: Icons.bookmark,
                  label: 'Избранное',
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
                  label: 'Достижения',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AchievementsScreen(
                        achievements: achievements,
                        level: stats.level,
                        levelTitle: stats.levelTitle,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 78,
                child: AnimatedMenuTile(
                  icon: Icons.car_repair,
                  label: 'Сервисы',
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
                  icon: Icons.settings,
                  label: 'Настройки',
                  color: Colors.grey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ),
              if (user['is_admin'] == true)
                SizedBox(
                  width: 78,
                  child: AnimatedMenuTile(
                    icon: Icons.admin_panel_settings,
                    label: 'Админка',
                    color: AppColors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('О себе', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Text(user['bio'] ?? 'Нет информации', style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),

          if (_myCars.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Мои машины', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            ..._myCars.map((c) => _miniCarCard(c as Map<String, dynamic>)),
          ],

          if (_myClubs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Мои клубы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _myClubs.map<Widget>((c) {
                final role = c['role'] as String?;
                final roleLabel = role == 'owner' ? ' · владелец' : (role == 'admin' ? ' · админ' : '');
                return Chip(
                  avatar: const Icon(Icons.groups, size: 16, color: AppColors.blue),
                  label: Text('${c['name']}$roleLabel'),
                  backgroundColor: AppColors.blue.withOpacity(0.08),
                );
              }).toList(),
            ),
          ],

          // Раньше здесь была плитка на все 28 достижений сразу — теперь
          // только короткий превью открытых + переход на отдельный экран
          // с полным списком и прогрессом («7/10») по каждому — так профиль
          // не превращается в длинную простыню.
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AchievementsScreen(
                  achievements: achievements,
                  level: stats.level,
                  levelTitle: stats.levelTitle,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(Colors.amber.withOpacity(0.18), cardSurface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, color: Colors.amber, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Достижения · ${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: cardText),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: achievements.where((a) => a.unlocked).take(6).isEmpty
                              ? [
                                  Text(
                                    'Пока пусто — сходи на первую сходку!',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ]
                              : achievements
                                  .where((a) => a.unlocked)
                                  .take(6)
                                  .map((a) => Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Text(a.emoji, style: const TextStyle(fontSize: 18)),
                                      ))
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color.alphaBlend(Colors.green.withOpacity(0.28), cardSurface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Реферальная программа', style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      ),
                      child: const Text('Premium →'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_referral?['code'] != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '${_referral!['code']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.green),
                        tooltip: 'Скопировать код',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '${_referral!['code']}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Код скопирован')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else if (_referral == null) ...[
                  const Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Загружаем код...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Приглашено друзей: ${_referral?['referrals_count'] ?? 0}',
                  style: TextStyle(color: cardText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Поделись кодом — 10 друзей = месяц Premium бесплатно',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout, size: 18, color: AppColors.red),
            label: const Text('Выйти из аккаунта', style: TextStyle(color: AppColors.red, fontSize: 13)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
