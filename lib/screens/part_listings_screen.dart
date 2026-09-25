import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/neon_chip.dart';
import '../utils/image_url.dart';
import 'part_listing_detail_screen.dart';
import 'part_listing_form_screen.dart';

const Map<String, String> partCategoryLabels = {
  'engine': 'Двигатель',
  'suspension': 'Подвеска',
  'brakes': 'Тормоза',
  'body': 'Кузов',
  'interior': 'Салон',
  'electronics': 'Электроника',
  'wheels_tires': 'Колёса/шины',
  'exhaust': 'Выхлоп',
  'other': 'Другое',
};

const Map<String, IconData> partCategoryIcons = {
  'engine': Icons.settings,
  'suspension': Icons.car_repair,
  'brakes': Icons.album,
  'body': Icons.directions_car,
  'interior': Icons.event_seat,
  'electronics': Icons.electrical_services,
  'wheels_tires': Icons.trip_origin,
  'exhaust': Icons.air,
  'other': Icons.category,
};

class PartListingsScreen extends StatefulWidget {
  const PartListingsScreen({Key? key}) : super(key: key);

  @override
  State<PartListingsScreen> createState() => _PartListingsScreenState();
}

class _PartListingsScreenState extends State<PartListingsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;
  bool _mineOnly = false;
  String? _selectedCategory;
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
        final response = await ApiService.get('/api/part-listings/mine?limit=100', token: authProvider.accessToken);
        setState(() => _items = (response is Map && response['items'] is List) ? response['items'] : []);
      } else {
        final q = _searchController.text.trim();
        final params = StringBuffer('limit=100');
        if (_selectedCategory != null) params.write('&category=$_selectedCategory');
        if (q.isNotEmpty) params.write('&q=${Uri.encodeQueryComponent(q)}');
        final response = await ApiService.get('/api/part-listings?$params', token: authProvider.accessToken);
        setState(() => _items = (response is Map && response['items'] is List) ? response['items'] : []);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PartListingFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Барахолка запчастей'), backgroundColor: AppColors.black),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceDarkAlt,
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
                  label: 'Мои',
                  icon: Icons.person,
                  selected: _mineOnly,
                  onTap: () {
                    setState(() => _mineOnly = !_mineOnly);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                NeonChip(
                  label: 'Все категории',
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    _load();
                  },
                ),
                for (final entry in partCategoryLabels.entries) ...[
                  const SizedBox(width: 8),
                  NeonChip(
                    label: entry.value,
                    icon: partCategoryIcons[entry.key],
                    selected: _selectedCategory == entry.key,
                    onTap: () {
                      setState(() => _selectedCategory = entry.key);
                      _load();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoader())
                : _items.isEmpty
                    ? const Center(child: Text('Пока нет объявлений', style: TextStyle(color: AppColors.textMutedDark)))
                    : RefreshIndicator(
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
                                  MaterialPageRoute(builder: (_) => PartListingDetailScreen(listingId: item['id'])),
                                );
                                if (changed == true) _load();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDarkAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.steel),
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
                                                  color: AppColors.steel.withOpacity(0.3),
                                                  child: Icon(partCategoryIcons[item['category']] ?? Icons.category, size: 36, color: AppColors.textMutedDark),
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
                                                  status == 'sold' ? 'Продано' : (status == 'reserved' ? 'Резерв' : 'Снято'),
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
                                            item['title'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'} ₽',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.blue),
                                          ),
                                          if (item['city'] != null)
                                            Text(
                                              item['city'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
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
