import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/business_category.dart';
import '../utils/map_config.dart';
import '../utils/maps_launcher.dart';
import '../widgets/report_dialog.dart';
import 'business_form_screen.dart';
import 'premium_screen.dart';
import 'user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/image_url_picker.dart';
import '../utils/sound_player.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/image_url.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({Key? key, required this.businessId}) : super(key: key);

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  Map<String, dynamic>? _business;
  List<dynamic> _reviews = [];
  bool _isLoadingDetail = true;
  bool _isActionLoading = false;

  bool _showReviewForm = false;
  int _myStars = 0;
  final _reviewController = TextEditingController();
  final _reviewPhotoUrlController = TextEditingController();

  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];
  bool get _isOwner => _business != null && _business!['owner_id'] != null && _business!['owner_id'] == _myId;
  bool get _isFavorite => _business?['is_favorite'] == true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _reviewPhotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadBusiness();
    await _loadReviews();
  }

  Future<void> _loadBusiness() async {
    setState(() => _isLoadingDetail = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/businesses/${widget.businessId}',
        token: authProvider.accessToken,
      );
      setState(() {
        _business = response;
        _myStars = (response['my_rating'] as int?) ?? 0;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('business_detail.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/businesses/${widget.businessId}/reviews?limit=50',
        token: authProvider.accessToken,
      );
      setState(() => _reviews = response['items'] ?? []);
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_business == null) return;
    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isFavorite) {
        await ApiService.delete('/api/businesses/${widget.businessId}/favorite', token: authProvider.accessToken);
      } else {
        await ApiService.post('/api/businesses/${widget.businessId}/favorite', {}, token: authProvider.accessToken);
      }
      if (mounted) setState(() => _business!['is_favorite'] = !_isFavorite);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('business_detail.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_myStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('business_detail.rate_before_submit'))));
      return;
    }
    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/businesses/${widget.businessId}/reviews',
        {
          'rating': _myStars,
          'text': _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
          'photo_url': _reviewPhotoUrlController.text.trim().isEmpty ? null : _reviewPhotoUrlController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      _reviewController.clear();
      _reviewPhotoUrlController.clear();
      setState(() => _showReviewForm = false);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('business_detail.review_submitted'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('business_detail.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  bool _isBoosted() {
    final until = _business?['boosted_until'];
    if (until == null) return false;
    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _boost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.user?['is_premium'] == true;
    if (!isPremium) {
      final goPremium = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.t('business_detail.premium_only_title')),
          content: Text(context.t('business_detail.boost_premium_only_desc')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.t('business_detail.learn_more'))),
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
        '/api/businesses/${widget.businessId}/boost',
        {},
        token: authProvider.accessToken,
      );
      setState(() => _business = response);
      SoundPlayer.play(context, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('business_detail.boosted_success'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusinessFormScreen(business: _business)),
    );
    if (result == true) _loadAll();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('business_detail.delete_confirm_title')),
        content: Text(context.t('business_detail.delete_confirm_desc')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('common.delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/businesses/${widget.businessId}', token: authProvider.accessToken);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('business_detail.deleted_success'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('business_detail.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetail && _business == null) {
      return Scaffold(body: Center(child: AppLoader()));
    }
    if (_business == null) {
      return Scaffold(body: Center(child: Text(context.t('business_detail.not_found'))));
    }

    final b = _business!;
    final rating = ((b['average_rating'] ?? 0) as num).toDouble();
    final reviewsCount = b['reviews_count'] ?? 0;
    final coverUrl = b['cover_url'] as String?;
    final logoUrl = b['logo_url'] as String?;
    final services = (b['services'] as String? ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(b['name'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 1),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.red : null),
            tooltip: context.t('business_detail.favorite_tooltip'),
            onPressed: _isActionLoading ? null : _toggleFavorite,
          ),
          if (_isOwner) ...[
            IconButton(
              icon: Icon(Icons.rocket_launch, color: _isBoosted() ? Colors.amber : null),
              tooltip: _isBoosted() ? context.t('business_detail.boosted_tooltip') : context.t('business_detail.boost_tooltip'),
              onPressed: _isBoosted() ? null : _boost,
            ),
            IconButton(icon: const Icon(Icons.edit), tooltip: context.t('business_detail.edit_tooltip'), onPressed: _openEdit),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: context.t('common.delete'), onPressed: _delete),
          ],
          if (!_isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: context.t('business_detail.report_tooltip'),
              onPressed: () => showReportDialog(context, targetType: 'business', targetId: widget.businessId),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(resolveImageUrl(coverUrl), height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),

            Row(
              children: [
                (logoUrl != null && logoUrl.isNotEmpty)
                    ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(resolveImageUrl(logoUrl)))
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.blue.withOpacity(0.15),
                        child: Icon(businessCategoryIcon(b['category']), color: AppColors.blue),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              b['name'] ?? '',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (b['is_verified'] == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.blue, size: 18),
                          ],
                        ],
                      ),
                      Text(businessCategoryLabel(b['category']), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(context.tArgs('business_detail.rating_summary', {'rating': rating.toStringAsFixed(1), 'count': '$reviewsCount'})),
              ],
            ),
            const SizedBox(height: 20),

            if ((b['description'] ?? '').toString().isNotEmpty) ...[
              Text(b['description'], style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
            ],

            if (services.isNotEmpty) ...[
              Text(context.t('business_detail.services_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: services.map((s) => Chip(
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      ),
                    )).toList(),
              ),
              const SizedBox(height: 20),
            ],

            Text(context.t('business_detail.contacts_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if ((b['city'] ?? '').toString().isNotEmpty ||
                (b['address'] ?? '').toString().isNotEmpty ||
                (b['latitude'] != null && b['longitude'] != null))
              _infoRow(
                Icons.location_on,
                () {
                  final parts = [b['city'], b['address']]
                      .where((s) => (s ?? '').toString().isNotEmpty)
                      .join(', ');
                  return parts.isNotEmpty ? parts : context.t('business_detail.location_on_map_only');
                }(),
                trailing: (b['latitude'] != null && b['longitude'] != null)
                    ? IconButton(
                        icon: const Icon(Icons.directions, color: AppColors.blue, size: 20),
                        tooltip: context.t('business_detail.directions_tooltip'),
                        onPressed: () => openDirections(
                          context,
                          (b['latitude'] as num).toDouble(),
                          (b['longitude'] as num).toDouble(),
                        ),
                      )
                    : null,
              ),
            if (b['latitude'] != null && b['longitude'] != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 160,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (b['latitude'] as num).toDouble(),
                        (b['longitude'] as num).toDouble(),
                      ),
                      initialZoom: defaultMapZoom,
                    ),
                    children: [
                      TileLayer(urlTemplate: yandexTileUrlTemplate, userAgentPackageName: mapUserAgentPackageName),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              (b['latitude'] as num).toDouble(),
                              (b['longitude'] as num).toDouble(),
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(
                              businessCategoryIcon(b['category']),
                              color: AppColors.blue,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if ((b['phone'] ?? '').toString().isNotEmpty) _infoRow(Icons.phone, b['phone']),
            if ((b['website'] ?? '').toString().isNotEmpty) _infoRow(Icons.language, b['website']),
            if ((b['instagram'] ?? '').toString().isNotEmpty) _infoRow(Icons.camera_alt, b['instagram']),
            if ((b['work_hours'] ?? '').toString().isNotEmpty) _infoRow(Icons.access_time, b['work_hours']),

            const SizedBox(height: 30),

            Text(context.t('business_detail.reviews_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _reviews.isEmpty
                ? Text(context.t('business_detail.no_reviews_yet'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index] as Map<String, dynamic>;
                      final user = review['user'] as Map<String, dynamic>?;
                      final userId = user?['id'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: userId == null
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
                                            ),
                                    child: Text(user?['username'] ?? context.t('business_detail.unknown_user')),
                                  ),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < (review['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                        color: Colors.orange,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              if ((review['text'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(review['text'], style: const TextStyle(fontSize: 12)),
                              ],
                              if ((review['photo_url'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    resolveImageUrl(review['photo_url']),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showReviewForm = !_showReviewForm),
                icon: const Icon(Icons.star),
                label: Text(_showReviewForm
                    ? context.t('business_detail.hide_review_form')
                    : (_myStars > 0 ? context.t('business_detail.edit_my_review') : context.t('business_detail.leave_review'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            if (_showReviewForm) ...[
              const SizedBox(height: 20),
              Text(context.t('business_detail.your_rating_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _myStars = index + 1),
                    child: Icon(
                      _myStars > index ? Icons.star : Icons.star_border,
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
                  hintText: context.t('business_detail.review_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              ImageUrlPickerField(
                controller: _reviewPhotoUrlController,
                token: Provider.of<AuthProvider>(context, listen: false).accessToken,
                height: 120,
                placeholderIcon: Icons.add_a_photo_outlined,
                galleryLabel: context.t('business_detail.review_photo_pick_from_gallery'),
                cameraLabel: context.t('business_detail.review_photo_pick_from_camera'),
                errorTextBuilder: (e) => context.tArgs('business_detail.review_photo_upload_error', {'error': '$e'}),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isActionLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.t('business_detail.submit_review_button'), style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String? value, {Widget? trailing}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
