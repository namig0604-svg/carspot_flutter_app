import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/business_category.dart';
import 'business_detail_screen.dart';
import 'business_form_screen.dart';
import 'premium_screen.dart';
import 'businesses_map_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import '../widgets/neon_chip.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/distance_format.dart';

class BusinessesListScreen extends StatefulWidget {
  const BusinessesListScreen({Key? key}) : super(key: key);

  @override
  State<BusinessesListScreen> createState() => _BusinessesListScreenState();
}

class _BusinessesListScreenState extends State<BusinessesListScreen> {
  List<dynamic> _businesses = [];
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_showFavoritesOnly) {
        final response = await ApiService.get('/api/businesses/my/favorites', token: authProvider.accessToken);
        setState(() => _businesses = response is List ? response : []);
      } else {
        final Position? position = await determineCurrentPosition();
        _userPosition = position;
        final q = _searchController.text.trim();
        final params = StringBuffer('limit=100');
        if (q.isNotEmpty) params.write('&q=${Uri.encodeQueryComponent(q)}');
        if (_selectedCategory != null) params.write('&category=$_selectedCategory');
        if (position != null) {
          params.write('&latitude=${position.latitude}&longitude=${position.longitude}');
        }
        final response = await ApiService.get('/api/businesses/?$params', token: authProvider.accessToken);
        setState(() => _businesses = response['items'] ?? []);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('businesses_list.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isBoosted(dynamic until) {
    if (until == null) return false;
    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Widget _logoPlaceholder(String? category) {
    return CircleAvatar(
      backgroundColor: AppColors.blue.withOpacity(0.15),
      child: Icon(businessCategoryIcon(category), color: AppColors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('businesses_list.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: context.t('businesses_list.map_tooltip'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessesMapScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.red.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: FloatingActionButton(
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.user;
          final canCreate = user?['is_premium'] == true || user?['is_admin'] == true;
          if (!canCreate) {
            final goPremium = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(context.t('businesses_list.premium_only_title')),
                content: Text(
                  context.t('businesses_list.premium_required_desc'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.t('businesses_list.learn_more'))),
                ],
              ),
            );
            if (goPremium == true && mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
            }
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessFormScreen()),
          );
          if (result == true) _load();
        },
        backgroundColor: AppColors.red,
        child: const Icon(Icons.add),
        ),
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/services.jpg'),
          Theme(data: AppTheme.dark, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                NeonChip(
                  label: context.t('businesses_list.filter_all'),
                  icon: Icons.apps,
                  color: AppColors.red,
                  selected: !_showFavoritesOnly,
                  onTap: () {
                    setState(() => _showFavoritesOnly = false);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                NeonChip(
                  label: context.t('businesses_list.filter_favorites'),
                  icon: Icons.favorite,
                  color: AppColors.red,
                  selected: _showFavoritesOnly,
                  onTap: () {
                    setState(() => _showFavoritesOnly = true);
                    _load();
                  },
                ),
              ],
            ),
          ),
          if (!_showFavoritesOnly) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: context.t('businesses_list.search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _load),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NeonChip(
                      label: context.t('businesses_list.all_categories'),
                      icon: Icons.apps,
                      color: AppColors.blue,
                      selected: _selectedCategory == null,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        _load();
                      },
                    ),
                  ),
                  ...businessCategories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: NeonChip(
                          label: c.label,
                          icon: c.icon,
                          color: AppColors.blue,
                          selected: _selectedCategory == c.value,
                          onTap: () {
                            setState(() => _selectedCategory = _selectedCategory == c.value ? null : c.value);
                            _load();
                          },
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: _isLoading
                ? Center(child: AppLoader())
                : RefreshIndicator(
                    color: AppColors.red,
                    backgroundColor: AppColors.surfaceDark,
                    onRefresh: _load,
                    child: _businesses.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Icon(Icons.car_repair, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  _showFavoritesOnly ? context.t('businesses_list.no_favorites_empty') : context.t('businesses_list.nothing_found'),
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _businesses.length,
                            itemBuilder: (context, index) {
                              final business = _businesses[index] as Map<String, dynamic>;
                              final logoUrl = business['logo_url'] as String?;
                              final rating = ((business['average_rating'] ?? 0) as num).toDouble();
                              final reviewsCount = business['reviews_count'] ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: (logoUrl != null && logoUrl.isNotEmpty)
                                      ? CircleAvatar(backgroundImage: NetworkImage(resolveImageUrl(logoUrl)))
                                      : _logoPlaceholder(business['category']),
                                  title: Row(
                                    children: [
                                      if (_isBoosted(business['boosted_until'])) ...[
                                        const Text('🚀', style: TextStyle(fontSize: 13)),
                                        const SizedBox(width: 4),
                                      ],
                                      Flexible(child: Text(business['name'] ?? '', overflow: TextOverflow.ellipsis)),
                                      if (business['is_verified'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: AppColors.blue, size: 14),
                                      ],
                                      if (business['is_favorite'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.favorite, color: AppColors.red, size: 14),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    [
                                      businessCategoryLabel(business['category']),
                                      if ((business['city'] ?? '').toString().isNotEmpty) business['city'],
                                      if (_userPosition != null && business['latitude'] != null && business['longitude'] != null)
                                        formatDistance(
                                          context,
                                          Geolocator.distanceBetween(
                                            _userPosition!.latitude,
                                            _userPosition!.longitude,
                                            (business['latitude'] as num).toDouble(),
                                            (business['longitude'] as num).toDouble(),
                                          ),
                                        ),
                                      if (reviewsCount > 0) '⭐ ${rating.toStringAsFixed(1)} ($reviewsCount)',
                                    ].join(' · '),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BusinessDetailScreen(businessId: business['id']),
                                      ),
                                    ).then((_) => _load());
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      )),
        ],
      ),
    );
  }
}
