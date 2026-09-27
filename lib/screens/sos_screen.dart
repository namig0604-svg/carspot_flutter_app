import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';
import '../widgets/app_loader.dart';
import '../widgets/live_location_layer.dart' show LiveLocationController, showLiveLocationSheet;
import '../l10n/l10n_extensions.dart';
import 'business_detail_screen.dart';

// Реальные категории заведений (app/models/business.py): для экстренной
// помощи актуальны автосервис (в т.ч. эвакуация) и шиномонтаж.
const List<String> _sosCategories = ['service', 'tire'];

/// Экран экстренной помощи на дороге: ближайшие эвакуаторы/шиномонтажи +
/// быстрый доступ к "поделиться геопозицией" с другом.
class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  List<dynamic> _nearby = [];
  bool _isLoading = true;
  LiveLocationController? _liveLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _liveLocation?.disposeController();
    super.dispose();
  }

  Future<void> _shareLocation() async {
    if (_liveLocation == null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _liveLocation = LiveLocationController(getToken: () => authProvider.accessToken);
      await _liveLocation!.start();
    }
    if (mounted) showLiveLocationSheet(context, _liveLocation!);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final position = await determineCurrentPosition();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final List<dynamic> collected = [];
      for (final category in _sosCategories) {
        try {
          final response = await ApiService.get(
            '/api/businesses?category=$category&limit=10',
            token: authProvider.accessToken,
          );
          final items = response is Map && response['items'] is List ? response['items'] as List : [];
          collected.addAll(items);
        } catch (_) {
          // Пропускаем категорию, если её нет в справочнике — не критично.
        }
      }

      if (position != null) {
        collected.sort((a, b) {
          final da = _distanceKm(position.latitude, position.longitude, a);
          final db = _distanceKm(position.latitude, position.longitude, b);
          return da.compareTo(db);
        });
      }

      setState(() => _nearby = collected.take(15).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _distanceKm(double lat, double lng, dynamic business) {
    final b = business as Map<String, dynamic>;
    final blat = (b['latitude'] as num?)?.toDouble();
    final blng = (b['longitude'] as num?)?.toDouble();
    if (blat == null || blng == null) return double.infinity;
    // Формула гаверсинуса.
    const r = 6371.0;
    final dLat = _deg2rad(blat - lat);
    final dLng = _deg2rad(blng - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat)) * math.cos(_deg2rad(blat)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('sos.title')), backgroundColor: AppColors.red),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('sos.broke_down'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  context.t('sos.share_hint'),
                  style: const TextStyle(color: AppColors.textMutedDark),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.share_location),
                    label: Text(context.t('sos.share_button')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(context.t('sos.nearby_title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: AppLoader())
          else if (_nearby.isEmpty)
            Text(context.t('sos.empty'), style: const TextStyle(color: AppColors.textMutedDark))
          else
            ..._nearby.map((b) {
              final business = b as Map<String, dynamic>;
              final phone = business['phone'] as String?;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.steel),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: business['id'])),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(business['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (business['address'] != null)
                              Text(business['address'], style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                          ],
                        ),
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _call(phone),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
