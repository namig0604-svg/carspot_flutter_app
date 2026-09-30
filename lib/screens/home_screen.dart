import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/gamification.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'garage_screen.dart';
import 'chats_list_screen.dart';
import 'clubs_list_screen.dart';
import 'businesses_list_screen.dart';
import 'business_form_screen.dart';
import 'events_map_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'premium_screen.dart';
import 'notifications_screen.dart';
import 'friends_list_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_panel_screen.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import '../widgets/onboarding_tour.dart';
import 'favorites_screen.dart';
import 'my_points_screen.dart';
import 'forum_categories_screen.dart';
import 'my_bookings_screen.dart';
import 'parking_screen.dart';
import 'maintenance_screen.dart';
import 'car_documents_screen.dart';
import 'car_expenses_screen.dart';
import 'fuel_tracker_screen.dart';
import 'car_listings_screen.dart';
import 'car_of_week_screen.dart';
import 'convoy_screen.dart';
import 'sos_screen.dart';
import 'vin_decoder_screen.dart';
import 'ai_diagnosis_screen.dart';
import 'car_report_screen.dart';
import 'maintenance_forecast_screen.dart';
import 'car_hub_screen.dart';
import 'community_hub_screen.dart';
import 'activity_hub_screen.dart';
import 'safety_hub_screen.dart';
import 'more_hub_screen.dart';
import 'daily_login_dialog.dart';
import '../widgets/challenges_banner.dart';
import 'hazards_screen.dart';
import 'part_listings_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/section_background.dart';
import '../widgets/neon_chip.dart';
import '../widgets/animated_counter.dart';
import '../widgets/stories_bar.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/weather_alert_banner.dart';
import '../widgets/animated_bottom_nav.dart';
import 'faq_screen.dart';
import '../utils/sound_player.dart';
import '../utils/event_category.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/cosmetics.dart';
import '../widgets/equipped_avatar.dart';
import '../utils/event_date.dart';

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
  String _sortMode = 'recommended';
  int _eventsTotal = 0;
  int _businessesTotal = 0;

  final List<String> _eventTypes = [
    'all', 'meetup', 'racing', 'drift', 'drag', 'offroad', 'show', 'cruise', 'track_day', 'charity'
  ];

  List<dynamic> _myClubs = [];
  List<dynamic> _myCars = [];
  Map<String, dynamic>? _referral;

  // Ключи для интерактивного тура по приложению (onboarding_tour.dart) —
  // подсвечивают реальные виджеты нижней навигации и колокольчика уведомлений.
  final GlobalKey _tourNavBarKey = GlobalKey();
  final GlobalKey _tourNotificationsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadMyCars();
    _loadBusinessesTotal();
    Future.wait([_loadMyClubs(), _loadReferral()]).then((_) => _checkGamificationProgress());
    _loadUnreadNotifications();
    _notificationsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadNotifications());
    // Интерактивный тур — только если флаг взведён (см. onboarding_flags.dart),
    // то есть ровно один раз для только что установившего приложение нового
    // пользователя, после первого кадра с реальными виджетами.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowOnboardingTour(context, _tourSteps());
    });
    // Автопоказ ежедневной награды — только если её ещё не забрали сегодня
    // (showDailyLoginDialog сам молча ничего не делает, если уже забрано).
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) showDailyLoginDialog(context, onlyIfClaimable: true);
    });
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

  /// Шаги интерактивного тура по приложению — см. onboarding_tour.dart.
  /// Первый и последний шаги без цели (просто центрированная карточка),
  /// остальные подсвечивают реальные пункты нижней навигации (все пять
  /// используют один и тот же _tourNavBarKey — ширина бара делится на
  /// количество пунктов, см. AnimatedBottomNav) и колокольчик уведомлений.
  List<TourStep> _tourSteps() {
    return [
      const TourStep(
        titleKey: 'onboarding_tour.step_welcome_title',
        bodyKey: 'onboarding_tour.step_welcome_body',
      ),
      TourStep(
        targetKey: _tourNavBarKey,
        segmentIndex: 0,
        segmentCount: 5,
        titleKey: 'onboarding_tour.step_feed_title',
        bodyKey: 'onboarding_tour.step_feed_body',
      ),
      TourStep(
        targetKey: _tourNavBarKey,
        segmentIndex: 1,
        segmentCount: 5,
        titleKey: 'onboarding_tour.step_map_title',
        bodyKey: 'onboarding_tour.step_map_body',
      ),
      TourStep(
        targetKey: _tourNavBarKey,
        segmentIndex: 2,
        segmentCount: 5,
        titleKey: 'onboarding_tour.step_add_title',
        bodyKey: 'onboarding_tour.step_add_body',
      ),
      TourStep(
        targetKey: _tourNavBarKey,
        segmentIndex: 3,
        segmentCount: 5,
        titleKey: 'onboarding_tour.step_chats_title',
        bodyKey: 'onboarding_tour.step_chats_body',
      ),
      TourStep(
        targetKey: _tourNavBarKey,
        segmentIndex: 4,
        segmentCount: 5,
        titleKey: 'onboarding_tour.step_profile_title',
        bodyKey: 'onboarding_tour.step_profile_body',
      ),
      TourStep(
        targetKey: _tourNotificationsKey,
        titleKey: 'onboarding_tour.step_notifications_title',
        bodyKey: 'onboarding_tour.step_notifications_body',
      ),
      const TourStep(
        titleKey: 'onboarding_tour.step_final_title',
        bodyKey: 'onboarding_tour.step_final_body',
      ),
    ];
  }

  /// Крупная карточка-категория на главном экране (редизайн меню: раньше
  /// было ~19 мелких иконок плоским списком, теперь 5 смысловых разделов,
  /// каждый открывает отдельный экран со своим функционалом — см.
  /// car_hub_screen.dart и соседние *_hub_screen.dart).
  Widget _categoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cardText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.65)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cardText.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
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
      bonusXp: (user['xp'] ?? 0) as int,
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
          title: context.tArgs('home.new_level_title', {'level': '${stats.level}'}),
          subtitle: context.t(stats.levelTitleKey),
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
            title: context.t('home.new_achievement_title'),
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
      final Position? position = await determineCurrentPosition();
      var endpoint = '/api/events/?limit=100&sort=$_sortMode';
      if (position != null) {
        endpoint += '&latitude=${position.latitude}&longitude=${position.longitude}';
      }
      final response = await ApiService.get(
        endpoint,
        token: authProvider.accessToken,
      );
      setState(() {
        _events = response['items'] ?? [];
        _eventsTotal = (response['total'] as num?)?.toInt() ?? _events.length;
        _filterEvents();
      });
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusinessesTotal() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/businesses/?limit=1', token: authProvider.accessToken);
      if (mounted) setState(() => _businessesTotal = (response['total'] as num?)?.toInt() ?? 0);
    } catch (_) {
      // Счётчик не критичен для работы экрана — тихо оставляем 0.
    }
  }

  void _filterEvents() {
    _filteredEvents = _events.where((event) {
      bool matchesSearch = event['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesType = _selectedType == 'all' || event['event_type'] == _selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  void _setSortMode(String mode) {
    if (_sortMode == mode) return;
    HapticFeedback.selectionClick();
    setState(() => _sortMode = mode);
    _loadEvents();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('home.error_snackbar', {'error': '$e'}))));
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
              SnackBar(content: Text(context.t('home.easter_egg_message'))),
            );
          },
          child: const Text('CarSpot'),
        ),
        elevation: 0,
        backgroundColor: AppColors.black,
        actions: [
          // Быстрый доступ к настройкам прямо из AppBar вкладки "Профиль" —
          // раньше настройки было видно только проскроллив весь список меню
          // до конца, теперь так их видно сразу.
          if (_selectedIndex == 4)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.t('home.menu_settings'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: context.t('daily_login.title'),
            onPressed: () => showDailyLoginDialog(context),
          ),
          Stack(
            key: _tourNotificationsKey,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: context.t('home.tooltip_notifications'),
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
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          SectionBackground(
            accent: _selectedIndex == 4 ? AppColors.blue : AppColors.red,
            glowAlignment: _selectedIndex == 4 ? Alignment.topLeft : Alignment.topRight,
            imageAsset: _selectedIndex == 4
                ? 'assets/backgrounds/profile.jpg'
                : 'assets/backgrounds/events.jpg',
          ),
          _buildBody(),
        ],
      ),
      // Нижняя навигация в духе референса: Лента / Карта / Добавить / Чаты /
      // Профиль — 5 пунктов вместо прежних 4. "Карта" и "Добавить" всегда
      // открывают отдельный экран/шторку (не меняют текущую вкладку), как
      // раньше это делали "Гараж" и "Чаты". Гараж переехал в сетку быстрых
      // действий на экране "Профиль" — там же, где Клубы/Сервисы/Форум и т.д.
      bottomNavigationBar: AnimatedBottomNav(
        key: _tourNavBarKey,
        currentIndex: _selectedIndex,
        items: [
          NavBarItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: context.t('home.nav_events')),
          NavBarItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: context.t('home.nav_map')),
          NavBarItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: context.t('home.nav_add')),
          NavBarItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: context.t('home.nav_chats')),
          NavBarItem(icon: Icons.person_outline, activeIcon: Icons.person, label: context.t('home.nav_profile')),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsMapScreen()),
            );
            return;
          }
          if (index == 2) {
            _showCreateSheet();
            return;
          }
          if (index == 3) {
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
      case 4: return _buildProfileTab();
      default: return _buildEventsTab();
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.blue, child: const Icon(Icons.calendar_today, color: Colors.white)),
                title: Text(context.t('home.create_event_option')),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                  );
                  if (result == true) _loadEvents();
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.red, child: const Icon(Icons.car_repair, color: Colors.white)),
                title: Text(context.t('home.create_business_option')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessFormScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Истории (24ч)
        const StoriesBar(),

        // Поиск — пилюля, как на карточках-референсах
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterEvents();
              });
            },
            style: TextStyle(color: AppColors.onSurface(context)),
            decoration: InputDecoration(
              hintText: context.t('home.search_hint'),
              hintStyle: TextStyle(color: AppColors.textMuted(context)),
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted(context)),
              filled: true,
              fillColor: AppColors.surfaceAlt(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: AppColors.blue.withOpacity(0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: AppColors.blue.withOpacity(0.4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(color: AppColors.blue, width: 1.6),
              ),
            ),
          ),
        ),

        // Вкладки сортировки (Популярные / Новые / Ближайшие) — отражают
        // sort=popular|new|recommended на бэкенде (GET /api/events/).
        _buildSortTabs(),
        const SizedBox(height: 10),

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
                  label: context.t(c.labelKey),
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

        // Заголовок секции списка — лёгкий текстовый лейбл вместо тяжёлой
        // цветной плашки (упрощение визуала стартового экрана).
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.t('home.section_soon'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMuted(context)),
                ),
              ),
              Text(
                '${_filteredEvents.length}',
                style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ),

        // Список сходок
        Expanded(
          child: _isLoading
            ? Center(child: AppFullLoader())
            : _filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.t('home.no_events_found')),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadEvents,
                        child: Text(context.t('home.refresh')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.blue,
                  backgroundColor: AppColors.surface(context),
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      final catColor = eventCategoryColor(event['event_type']);
                      final coverUrl = event['cover_url'] as String?;
                      final joined = event['is_joined'] ?? false;
                      final favorite = event['is_favorite'] == true;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
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
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: (coverUrl != null && coverUrl.isNotEmpty)
                                        ? Image.network(
                                            resolveImageUrl(coverUrl),
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _eventThumbFallback(catColor, event['event_type']),
                                          )
                                        : _eventThumbFallback(catColor, event['event_type']),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (_isBoosted(event['boosted_until'])) ...[
                                              const Text('🚀', style: TextStyle(fontSize: 12)),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                event['title'] ?? context.t('home.untitled_event'),
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () => _toggleEventFavorite(event),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(
                                                  favorite ? Icons.favorite : Icons.favorite_border,
                                                  color: favorite ? AppColors.red : AppColors.textMuted(context),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted(context)),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                '${event['city']} · ${formatEventDateTime(event['event_date'], event['event_time'] as String?)}',
                                                style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: joined ? AppColors.blue.withOpacity(0.16) : AppColors.surfaceAlt(context),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: joined ? AppColors.blue.withOpacity(0.5) : AppColors.border(context)),
                                              ),
                                              child: Text(
                                                joined ? context.t('home.status_joined') : context.t('home.status_not_joined'),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: joined ? AppColors.blue : AppColors.textMuted(context),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                            const SizedBox(width: 2),
                                            Text('${event['average_rating']}', style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
                                            const SizedBox(width: 8),
                                            Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textMuted(context)),
                                            const SizedBox(width: 2),
                                            Text('${event['participants_count']}', style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSortTabs() {
    final modes = [
      ('recommended', context.t('home.sort_nearest'), Icons.near_me),
      ('popular', context.t('home.sort_popular'), Icons.trending_up),
      ('new', context.t('home.sort_new'), Icons.auto_awesome),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: modes.map((m) {
          final selected = _sortMode == m.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _setSortMode(m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.blueBright, AppColors.blue],
                          )
                        : null,
                    color: selected ? null : AppColors.surfaceAlt(context),
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: AppColors.border(context)),
                    boxShadow: selected
                        ? [BoxShadow(color: AppColors.blue.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.$3, size: 15, color: selected ? Colors.white : AppColors.textMuted(context)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          m.$2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.textMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Заглушка превью сходки без обложки — цветной квадрат с иконкой категории.
  Widget _eventThumbFallback(Color color, String? type) {
    return Container(
      width: 72,
      height: 72,
      color: color.withOpacity(0.18),
      child: Icon(eventCategoryIcon(type), color: color, size: 28),
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

    if (user == null) return Center(child: AppFullLoader());

    final isClubLeader = _myClubs.any((c) => c['role'] == 'owner' || c['role'] == 'admin');
    final referralsCount = (_referral?['referrals_count'] ?? 0) as int;
    final isVerified = user['is_verified'] == true;
    final isPremium = user['is_premium'] == true;
    // ИИ-диагностика и PDF-отчёт — эксклюзив тарифа Max (не любой Premium).
    final isMaxTier = user['premium_tier'] == 'max';
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
      bonusXp: (user['xp'] ?? 0) as int,
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
          EquippedAvatar(
            avatarUrl: user['avatar_url'] as String?,
            fallbackLetter: (user['full_name'] as String?)?.substring(0, 1) ?? 'U',
            radius: 50,
            equippedFrame: user['equipped_frame'] as String?,
            equippedBadge: user['equipped_badge'] as String?,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user['full_name'] ?? context.t('home.unknown_user'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: nameColorFor(user['equipped_name_color'] as String?),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user['is_verified'] == true) ...[
                const SizedBox(width: 6),
                Tooltip(message: context.t('home.tooltip_verified'), child: const Icon(Icons.verified, color: AppColors.blue, size: 20)),
              ],
              if (user['is_admin'] == true) ...[
                const SizedBox(width: 6),
                Tooltip(message: context.t('home.tooltip_admin'), child: const Icon(Icons.shield, color: AppColors.red, size: 20)),
              ],
              if (user['is_premium'] == true) ...[
                const SizedBox(width: 6),
                const Tooltip(message: 'CarSpot Premium', child: Icon(Icons.workspace_premium, color: Colors.amber, size: 20)),
              ],
              if (_myClubs.isNotEmpty) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: '${_myClubs.first['name'] ?? context.t('home.club_fallback')}',
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.blue.withOpacity(0.15),
                    backgroundImage: ((_myClubs.first['logo_url'] as String?) ?? '').isNotEmpty
                        ? NetworkImage(resolveImageUrl(_myClubs.first['logo_url']))
                        : null,
                    child: ((_myClubs.first['logo_url'] as String?) ?? '').isEmpty
                        ? const Icon(Icons.groups, size: 12, color: AppColors.blue)
                        : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Юзернейм и локация выводятся поверх фонового фото профиля, где
          // просто приглушённого текста (AppColors.textMuted) недостаточно —
          // контраст "плавает" в зависимости от яркости фото под ним. Кладём
          // текст на собственную полупрозрачную "плашку" в цвет карточек
          // текущей темы, чтобы он был читаем при любом фото и любой теме.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cardSurface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${user['username'] ?? ''}',
                  style: TextStyle(color: cardText.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: cardText.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      '${user['city'] ?? ''}, ${user['country'] ?? ''}',
                      style: TextStyle(color: cardText.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
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
            label: Text(context.t('home.edit_profile')),
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
                          context.t('home.joke_drift'),
                          context.t('home.joke_race'),
                          context.t('home.joke_gas_price'),
                          context.t('home.joke_keep_going'),
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
                            context.tArgs('home.level_label', {'level': '${stats.level}', 'title': context.t(stats.levelTitleKey)}),
                            style: TextStyle(fontWeight: FontWeight.bold, color: cardText),
                          ),
                          AnimatedCountText(
                            end: stats.xp,
                            formatter: (v) => context.tArgs('home.xp_total', {'xp': '${v.round()}'}),
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
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
                  formatter: (v) => context.tArgs('home.xp_to_next_level', {'current': '${v.round()}', 'next': '${stats.xpForNextLevel}'}),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
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
                  Text(context.t('home.stat_cars'), style: const TextStyle(decoration: TextDecoration.underline)),
                ]),
              ),
              Column(children: [
                AnimatedCountText(
                  end: (user['events_attended'] ?? 0) as num,
                  formatter: (v) => '${v.round()}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(context.t('home.stat_events')),
              ]),
              Column(children: [
                AnimatedCountText(
                  end: (user['average_rating'] ?? 0) as num,
                  formatter: (v) => '${v.toStringAsFixed(1)}⭐',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(context.t('home.stat_rating')),
              ]),
            ],
          ),

          const SizedBox(height: 20),
          const WeatherAlertBanner(),
          const SizedBox(height: 12),
          const ChallengesBanner(),

          // Меню сгруппировано в 5 крупных категорий (раньше было ~19
          // мелких иконок плоским списком). Тап по категории открывает
          // отдельный экран с её функционалом — см. car_hub_screen.dart и
          // соседние *_hub_screen.dart. Быстрый доступ к настройкам также
          // остаётся в AppBar этой вкладки (иконка-шестерёнка рядом с
          // колокольчиком уведомлений).
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(context.t('home.menu_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cardText)),
          ),
          const SizedBox(height: 14),
          _categoryCard(
            context,
            icon: Icons.directions_car,
            title: context.t('home.section_my_car'),
            subtitle: context.t('home.section_my_car_subtitle'),
            color: Colors.cyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarHubScreen(
                  myCars: _myCars,
                  isMaxTier: isMaxTier,
                  onCarsChanged: _loadMyCars,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _categoryCard(
            context,
            icon: Icons.groups,
            title: context.t('home.section_community'),
            subtitle: context.t('home.section_community_subtitle'),
            color: AppColors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityHubScreen(
                  myClubs: _myClubs,
                  onClubsChanged: _loadMyClubs,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _categoryCard(
            context,
            icon: Icons.emoji_events,
            title: context.t('home.section_my_activity'),
            subtitle: context.t('home.section_my_activity_subtitle'),
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityHubScreen(
                  achievements: achievements,
                  level: stats.level,
                  levelTitle: context.t(stats.levelTitleKey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _categoryCard(
            context,
            icon: Icons.shield,
            title: context.t('home.section_safety'),
            subtitle: context.t('home.section_safety_subtitle'),
            color: AppColors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyHubScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _categoryCard(
            context,
            icon: Icons.more_horiz,
            title: context.t('home.section_other'),
            subtitle: context.t('home.section_other_subtitle'),
            color: Colors.blueGrey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MoreHubScreen(
                  isAdmin: user['is_admin'] == true,
                  onStartTour: () => showOnboardingTour(context, _tourSteps()),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('home.about_title'), style: TextStyle(fontWeight: FontWeight.w800, color: cardText)),
                const SizedBox(height: 10),
                Text(user['bio'] ?? context.t('home.no_bio_info'), style: TextStyle(color: cardText.withOpacity(0.85))),
              ],
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
                      child: Text(context.t('home.referral_program_title'), style: TextStyle(fontWeight: FontWeight.bold, color: cardText)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      ),
                      child: Text(context.t('home.premium_link')),
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
                            color: isDark ? AppColors.surfaceDarkRaised : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.steel : Colors.grey.shade300),
                          ),
                          child: Text(
                            '${_referral!['code']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: cardText, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.green),
                        tooltip: context.t('home.tooltip_copy_code'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '${_referral!['code']}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.t('home.code_copied'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else if (_referral == null) ...[
                  Row(
                    children: [
                      const AppLoader(size: 14),
                      const SizedBox(width: 8),
                      Text(context.t('home.loading_code'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  context.tArgs('home.referrals_invited', {'count': '${_referral?['referrals_count'] ?? 0}'}),
                  style: TextStyle(color: cardText),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t('home.referral_share_hint'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout, size: 18, color: AppColors.red),
            label: Text(context.t('home.logout'), style: const TextStyle(color: AppColors.red, fontSize: 13)),
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
