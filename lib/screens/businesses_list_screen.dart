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
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/section_background.dart';
import '../widgets/neon_chip.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';
import '../utils/distance_format.dart';

class BusinessesListScreen extends StatefulWidget {
  final String? initialCategory;

  const BusinessesListScreen({Key? key, this.initialCategory}) : super(key: key);

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
    _selectedCategory = widget.initialCategory;
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
    final color = businessCategoryColor(category);
    return Container(
      color: color.withOpacity(0.18),
      child: Icon(businessCategoryIcon(category), color: color, size: 26),
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
            BoxShadow(color: AppColors.blue.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
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
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add),
        ),
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/services.jpg'),
          Column(
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
                style: TextStyle(color: AppColors.onSurface(context)),
                decoration: InputDecoration(
                  hintText: context.t('businesses_list.search_hint'),
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted(context)),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, color: AppColors.blue), onPressed: _load),
                  filled: true,
                  fillColor: AppColors.surfaceAlt(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.blue.withOpacity(0.35)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: AppColors.blue, width: 1.6),
                  ),
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
                          label: context.t(c.labelKey),
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
                ? Center(child: AppFullLoader())
                : RefreshIndicator(
                    color: AppColors.red,
                    backgroundColor: AppColors.surface(context),
                    onRefresh: _load,
                    child: _businesses.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Icon(Icons.car_repair, size: 64, color: AppColors.textMuted(context)),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  _showFavoritesOnly ? context.t('businesses_list.no_favorites_empty') : context.t('businesses_list.nothing_found'),
                                  style: TextStyle(fontSize: 16, color: AppColors.textMuted(context)),
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
                              final catColor = businessCategoryColor(business['category']);
                              final rating = ((business['average_rating'] ?? 0) as num).toDouble();
                              final reviewsCount = business['reviews_count'] ?? 0;
                              final distanceText = (_userPosition != null && business['latitude'] != null && business['longitude'] != null)
                                  ? formatDistance(
                                      context,
                                      Geolocator.distanceBetween(
                                        _userPosition!.latitude,
                                        _userPosition!.longitude,
                                        (business['latitude'] as num).toDouble(),
                                        (business['longitude'] as num).toDouble(),
                                      ),
                                    )
                                  : null;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                          builder: (_) => BusinessDetailScreen(businessId: business['id']),
                                        ),
                                      ).then((_) => _load());
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: (logoUrl != null && logoUrl.isNotEmpty)
                                                ? Image.network(
                                                    resolveImageUrl(logoUrl),
                                                    width: 64,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => SizedBox(width: 64, height: 64, child: _logoPlaceholder(business['category'])),
                                                  )
                                                : SizedBox(width: 64, height: 64, child: _logoPlaceholder(business['category'])),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (_isBoosted(business['boosted_until'])) ...[
                                                      const Text('🚀', style: TextStyle(fontSize: 12)),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Flexible(
                                                      child: Text(
                                                        business['name'] ?? '',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                                      ),
                                                    ),
                                                    if (business['is_verified'] == true) ...[
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.verified, color: AppColors.blue, size: 15),
                                                    ],
                                                    const Spacer(),
                                                    if (business['is_favorite'] == true)
                                                      const Icon(Icons.favorite, color: AppColors.red, size: 16),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(businessCategoryIcon(business['category']), size: 13, color: catColor),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        [
                                                          businessCategoryLabel(context, business['category']),
                                                          if ((business['city'] ?? '').toString().isNotEmpty) business['city'],
                                                          if (distanceText != null) distanceText,
                                                        ].join(' · '),
                                                        style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    if (reviewsCount > 0) ...[
                                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '${rating.toStringAsFixed(1)} ($reviewsCount)',
                                                        style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
                                                      ),
                                                    ],
                                                    const Spacer(),
                                                    Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted(context)),
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
      ),
        ],
      ),
    );
  }
}
