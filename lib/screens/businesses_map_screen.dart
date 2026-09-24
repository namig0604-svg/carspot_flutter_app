import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/business_category.dart';
import '../utils/map_config.dart';
import '../utils/location_helper.dart';
import '../utils/distance_format.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/maps_launcher.dart';
import 'business_detail_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/map_pin_marker.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/map_theme_toggle.dart';
import '../l10n/l10n_extensions.dart';

/// Карта автосервисов и тюнинг-ателье. Метки — из /api/businesses/map,
/// с широкой рамкой на весь мир (геопозиции пользователя в приложении пока нет).
/// При открытии карта сама подстраивается, чтобы все метки были видны сразу.
class BusinessesMapScreen extends StatefulWidget {
  const BusinessesMapScreen({Key? key}) : super(key: key);

  @override
  State<BusinessesMapScreen> createState() => _BusinessesMapScreenState();
}

class _BusinessesMapScreenState extends State<BusinessesMapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _markers = [];
  bool _isLoading = true;
  Position? _userPosition;
  final Set<String> _selectedCategories = {};

  MapThemeMode _mapTheme = MapThemeMode.auto;

  void _toggleCategory(String value) {
    setState(() {
      if (_selectedCategories.contains(value)) {
        _selectedCategories.remove(value);
      } else {
        _selectedCategories.add(value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    determineCurrentPosition().then((p) {
      if (mounted && p != null) setState(() => _userPosition = p);
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/businesses/map?min_lat=-90&max_lat=90&min_lon=-180&max_lon=180&limit=500',
        token: authProvider.accessToken,
      );
      setState(() => _markers = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('businesses_map.error_message', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
    }
  }

  void _fitToMarkers() {
    final points = _markers
        .where((m) => m['latitude'] != null && m['longitude'] != null)
        .map<LatLng>((m) => LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()))
        .toList();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, defaultMapZoom);
      return;
    }
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {
      // Карта могла ещё не успеть построиться — не критично, просто оставляем текущий вид.
    }
  }

  void _showMarkerSheet(Map<String, dynamic> marker) {
    final lat = (marker['latitude'] as num?)?.toDouble();
    final lon = (marker['longitude'] as num?)?.toDouble();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(businessCategoryIcon(marker['category']), color: businessCategoryColor(marker['category'])),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(marker['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(businessCategoryLabel(marker['category']), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${marker['average_rating'] ?? 0}'),
                if (_userPosition != null && lat != null && lon != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.directions_walk, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(formatDistance(
                    context,
                    Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, lat, lon),
                  )),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (lat != null && lon != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openDirections(context, lat, lon),
                      icon: const Icon(Icons.directions),
                      label: Text(context.t('businesses_map.directions_button')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (lat != null && lon != null) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: marker['id'])),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(context.t('businesses_map.open_business_button'), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _effectiveTileUrl(BuildContext context) {
    switch (_mapTheme) {
      case MapThemeMode.dark:
        return darkTileUrlTemplate;
      case MapThemeMode.light:
        return lightTileUrlTemplate;
      case MapThemeMode.auto:
        return Theme.of(context).brightness == Brightness.dark ? darkTileUrlTemplate : lightTileUrlTemplate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleMarkers = _selectedCategories.isEmpty
        ? _markers
        : _markers.where((m) => _selectedCategories.contains(m['category'])).toList();
    final markers = visibleMarkers
        .where((m) => m['latitude'] != null && m['longitude'] != null)
        .map<Marker>((m) {
      return Marker(
        point: LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showMarkerSheet(m as Map<String, dynamic>),
          child: MapPinMarker(
            icon: businessCategoryIcon(m['category']),
            color: businessCategoryColor(m['category']),
            square: true,
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('businesses_map.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultMapCenter,
              initialZoom: worldMapZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: _effectiveTileUrl(context),
                subdomains: tileSubdomains,
                userAgentPackageName: mapUserAgentPackageName,
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                attributions: [TextSourceAttribution(osmAttribution)],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: MapThemeToggle(
                          value: _mapTheme,
                          onChanged: (m) => setState(() => _mapTheme = m),
                        ),
                      ),
                    ),
                    CategoryFilterBar(
                  items: businessCategories
                      .map((c) => FilterChipData(c.value, c.label, c.icon, c.color))
                      .toList(),
                  selected: _selectedCategories,
                  onToggle: _toggleCategory,
                ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) Positioned(top: 130, left: 0, right: 0, child: Center(child: AppLoader())),
          if (!_isLoading && markers.isEmpty)
            Positioned(
              top: 130,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceDarkAlt, borderRadius: BorderRadius.circular(10)),
                child: Text(context.t('businesses_map.no_businesses_with_coords'), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
