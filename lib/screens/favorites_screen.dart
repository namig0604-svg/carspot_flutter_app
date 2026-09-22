import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'event_details_screen.dart';
import 'club_detail_screen.dart';
import 'business_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

/// Единый экран "Избранное" — сохранённые сходки, клубы и автосервисы
/// на трёх вкладках. Каждый тип избранного уже умеет тогглиться со своего
/// экрана (сердечко на карточке/в шапке) — здесь просто собираем всё вместе.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoadingEvents = true;
  bool _isLoadingClubs = true;
  bool _isLoadingBusinesses = true;
  List<dynamic> _events = [];
  List<dynamic> _clubs = [];
  List<dynamic> _businesses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
    _loadClubs();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/events/my/favorites', token: authProvider.accessToken);
      if (mounted) setState(() => _events = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoadingClubs = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/clubs/my/favorites', token: authProvider.accessToken);
      if (mounted) setState(() => _clubs = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoadingClubs = false);
    }
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoadingBusinesses = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/businesses/my/favorites', token: authProvider.accessToken);
      if (mounted) setState(() => _businesses = response is List ? response : []);
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBusinesses = false);
    }
  }

  Future<void> _removeEventFavorite(Map event) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _events.removeWhere((e) => e['id'] == event['id']));
    try {
      await ApiService.delete('/api/events/${event['id']}/favorite', token: authProvider.accessToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('favorites.error_with_message', {'error': '$e'}))));
        _loadEvents();
      }
    }
  }

  Future<void> _removeClubFavorite(Map club) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _clubs.removeWhere((c) => c['id'] == club['id']));
    try {
      await ApiService.delete('/api/clubs/${club['id']}/favorite', token: authProvider.accessToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('favorites.error_with_message', {'error': '$e'}))));
        _loadClubs();
      }
    }
  }

  Future<void> _removeBusinessFavorite(Map business) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _businesses.removeWhere((b) => b['id'] == business['id']));
    try {
      await ApiService.delete('/api/businesses/${business['id']}/favorite', token: authProvider.accessToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('favorites.error_with_message', {'error': '$e'}))));
        _loadBusinesses();
      }
    }
  }

  Widget _emptyState(String text, IconData icon) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(icon, size: 56, color: Colors.grey),
        const SizedBox(height: 14),
        Center(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 15))),
      ],
    );
  }

  Widget _eventsTab() {
    if (_isLoadingEvents) return Center(child: AppLoader());
    if (_events.isEmpty) return _emptyState(context.t('favorites.no_events'), Icons.calendar_today_outlined);
    return RefreshIndicator(
      color: AppColors.red,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(child: Text((event['event_type'] ?? '?')[0].toUpperCase())),
              title: Text(event['title'] ?? context.t('favorites.untitled_event'), overflow: TextOverflow.ellipsis),
              subtitle: Text('${event['city'] ?? ''}, ${event['event_date'] ?? ''}', overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.red),
                tooltip: context.t('favorites.remove_favorite_tooltip'),
                onPressed: () => _removeEventFavorite(event),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
                ).then((_) => _loadEvents());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _clubsTab() {
    if (_isLoadingClubs) return Center(child: AppLoader());
    if (_clubs.isEmpty) return _emptyState(context.t('favorites.no_clubs'), Icons.groups_outlined);
    return RefreshIndicator(
      color: AppColors.red,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: _loadClubs,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _clubs.length,
        itemBuilder: (context, index) {
          final club = _clubs[index] as Map<String, dynamic>;
          final logoUrl = club['logo_url'] as String?;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: (logoUrl != null && logoUrl.isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(resolveImageUrl(logoUrl)))
                  : CircleAvatar(
                      backgroundColor: AppColors.blue.withOpacity(0.15),
                      child: const Icon(Icons.groups, color: AppColors.blue),
                    ),
              title: Text(club['name'] ?? '', overflow: TextOverflow.ellipsis),
              subtitle: Text(context.tArgs('favorites.members_count', {'count': '${club['members_count'] ?? 0}'}), overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.red),
                tooltip: context.t('favorites.remove_favorite_tooltip'),
                onPressed: () => _removeClubFavorite(club),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club['id'])),
                ).then((_) => _loadClubs());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _businessesTab() {
    if (_isLoadingBusinesses) return Center(child: AppLoader());
    if (_businesses.isEmpty) return _emptyState(context.t('favorites.no_businesses'), Icons.car_repair);
    return RefreshIndicator(
      color: AppColors.red,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: _loadBusinesses,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _businesses.length,
        itemBuilder: (context, index) {
          final business = _businesses[index] as Map<String, dynamic>;
          final logoUrl = business['logo_url'] as String?;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: (logoUrl != null && logoUrl.isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(resolveImageUrl(logoUrl)))
                  : CircleAvatar(
                      backgroundColor: AppColors.red.withOpacity(0.15),
                      child: const Icon(Icons.car_repair, color: AppColors.red),
                    ),
              title: Text(business['name'] ?? '', overflow: TextOverflow.ellipsis),
              subtitle: Text('${business['city'] ?? ''}', overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.red),
                tooltip: context.t('favorites.remove_favorite_tooltip'),
                onPressed: () => _removeBusinessFavorite(business),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: business['id'])),
                ).then((_) => _loadBusinesses());
              },
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
        title: Text(context.t('favorites.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: context.t('favorites.tab_events')),
            Tab(text: context.t('favorites.tab_clubs')),
            Tab(text: context.t('favorites.tab_businesses')),
          ],
        ),
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/profile.jpg'),
          Theme(
            data: AppTheme.dark,
            child: TabBarView(
              controller: _tabController,
              children: [_eventsTab(), _clubsTab(), _businessesTab()],
            ),
          ),
        ],
      ),
    );
  }
}
