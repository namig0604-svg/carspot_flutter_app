import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/neon_chip.dart';
import '../utils/image_url.dart';
import '../l10n/l10n_extensions.dart';
import 'car_listing_detail_screen.dart';
import 'car_listing_form_screen.dart';

/// Витрина «Машина на продажу»: список объявлений (GET /api/car-listings),
/// поиск по марке/модели, переключатель "Мои объявления". По структуре
/// повторяет part_listings_screen.dart (та же модель "барахолки"), но без
/// категорий — вместо них марка/модель/год/цена.
class CarListingsScreen extends StatefulWidget {
  const CarListingsScreen({Key? key}) : super(key: key);

  @override
  State<CarListingsScreen> createState() => _CarListingsScreenState();
}

class _CarListingsScreenState extends State<CarListingsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;
  bool _mineOnly = false;
  final TextEditingController _searchController = TextEditingController();

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
      if (_mineOnly) {
        final response = await ApiService.get('/api/car-listings/mine?limit=100', token: authProvider.accessToken);
        setState(() => _items = (response is Map && response['items'] is List) ? response['items'] : []);
      } else {
        final q = _searchController.text.trim();
        final params = StringBuffer('limit=100');
        if (q.isNotEmpty) params.write('&q=${Uri.encodeQueryComponent(q)}');
        final response = await ApiService.get('/api/car-listings?$params', token: authProvider.accessToken);
        setState(() => _items = (response is Map && response['items'] is List) ? response['items'] : []);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarListingFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('car_listings.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.onSurface(context)),
              decoration: InputDecoration(
                hintText: context.t('car_listings.search_hint'),
                hintStyle: TextStyle(color: AppColors.textMuted(context)),
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted(context)),
                filled: true,
                fillColor: AppColors.surfaceAlt(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                NeonChip(
                  label: context.t('car_listings.mine_chip'),
                  icon: Icons.person,
                  selected: _mineOnly,
                  onTap: () {
                    setState(() => _mineOnly = !_mineOnly);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: AppFullLoader())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          context.t('car_listings.empty'),
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.deepPurple,
                        backgroundColor: AppColors.surface(context),
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) {
                            final item = _items[index] as Map<String, dynamic>;
                            final photoUrl = item['photo_url'] as String?;
                            final status = (item['status'] as String?) ?? 'active';
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final changed = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CarListingDetailScreen(listingId: item['id'] as String)),
                                );
                                if (changed == true) _load();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          (photoUrl != null && photoUrl.isNotEmpty)
                                              ? Image.network(resolveImageUrl(photoUrl), fit: BoxFit.cover)
                                              : Container(
                                                  color: AppColors.surfaceAlt(context),
                                                  child: Icon(Icons.directions_car, size: 36, color: AppColors.textMuted(context)),
                                                ),
                                          if (status != 'active')
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  status == 'sold'
                                                      ? context.t('car_listings.status_sold')
                                                      : (status == 'reserved' ? context.t('car_listings.status_reserved') : context.t('car_listings.status_removed')),
                                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item['make'] ?? ''} ${item['model'] ?? ''}'.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                          Text(
                                            '${item['year'] ?? ''}',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'} ₽',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
                                          ),
                                          if (item['city'] != null)
                                            Text(
                                              item['city'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
