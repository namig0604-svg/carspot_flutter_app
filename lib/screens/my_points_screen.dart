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
          child: Text(context.t('my_points.empty_events'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMutedDark)),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.steel),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailsScreen(event: {'id': e['id'], 'title': e['title']})),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: style.color.withOpacity(0.18), borderRadius: BorderRadius.circular(13)),
                        child: Icon(style.icon, color: style.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(
                              [context.t(style.labelKey), if ((e['city'] ?? '').toString().isNotEmpty) e['city']].join(' • '),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.textMutedDark),
                          const SizedBox(width: 4),
                          Text('${e['participants_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
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
          child: Text(context.t('my_points.empty_businesses'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMutedDark)),
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
          final catColor = businessCategoryColor(b['category']);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.steel),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: b['id'])),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: catColor.withOpacity(0.18), borderRadius: BorderRadius.circular(13)),
                        child: Icon(businessCategoryIcon(b['category']), color: catColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    hasAddress
                                        ? [businessCategoryLabel(context, b['category']), b['address']].join(' • ')
                                        : businessCategoryLabel(context, b['category']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text('${b['average_rating'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
