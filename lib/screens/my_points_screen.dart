import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/business_category.dart';
import '../utils/event_type_style.dart';
import 'business_detail_screen.dart';
import 'event_details_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Sozdannye tekushchim polzovatelem skhodki i zavedeniya - dva taba, kak
/// v prilozheniyah-referensah ("moi zayavki"/"moi tochki"). Skhodki -
/// GET /api/events/my/created, zavedeniya - GET /api/businesses/my/added
/// (obe ruchki uzhe est na backende).
class MyPointsScreen extends StatefulWidget {
  const MyPointsScreen({Key? key}) : super(key: key);

  @override
  State<MyPointsScreen> createState() => _MyPointsScreenState();
}

class _MyPointsScreenState extends State<MyPointsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<dynamic> _events = [];
  List<dynamic> _businesses = [];
  bool _isLoadingEvents = true;
  bool _isLoadingBusinesses = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
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
      final response = await ApiService.get('/api/events/my/created', token: authProvider.accessToken);
      if (mounted) setState(() => _events = response is List ? response : []);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = context.tArgs('my_points.error_message', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoadingBusinesses = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/businesses/my/added', token: authProvider.accessToken);
      if (mounted) setState(() => _businesses = response is List ? response : []);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = context.tArgs('my_points.error_message', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoadingBusinesses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('my_points.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.t('my_points.tab_events')),
            Tab(text: context.t('my_points.tab_businesses')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(),
          _buildBusinessesTab(),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoadingEvents) return const Center(child: AppLoader());
    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.t('my_points.empty_events'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (context, i) {
          final e = _events[i] as Map<String, dynamic>;
          final style = eventTypeStyleByValue(e['event_type']);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: style.color,
                child: Icon(style.icon, color: Colors.white, size: 20),
              ),
              title: Text(e['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [style.label, if ((e['city'] ?? '').toString().isNotEmpty) e['city']].join(' • '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${e['participants_count'] ?? 0}'),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventDetailsScreen(event: {'id': e['id'], 'title': e['title']})),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessesTab() {
    if (_isLoadingBusinesses) return const Center(child: AppLoader());
    if (_businesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.t('my_points.empty_businesses'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBusinesses,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _businesses.length,
        itemBuilder: (context, i) {
          final b = _businesses[i] as Map<String, dynamic>;
          final hasAddress = (b['address'] ?? '').toString().trim().isNotEmpty;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: businessCategoryColor(b['category']),
                child: Icon(businessCategoryIcon(b['category']), color: Colors.white, size: 20),
              ),
              title: Text(b['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(
                children: [
                  Flexible(
                    child: Text(
                      hasAddress
                          ? [businessCategoryLabel(b['category']), b['address']].join(' • ')
                          : businessCategoryLabel(b['category']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!hasAddress) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.hourglass_top, size: 13, color: AppColors.blue.withOpacity(0.8)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        context.t('my_points.address_pending'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.blue.withOpacity(0.8), fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('${b['average_rating'] ?? 0}'),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: b['id'])),
              ),
            ),
          );
        },
      ),
    );
  }
}
