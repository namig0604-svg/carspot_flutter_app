import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/event_type_style.dart';
import '../utils/map_config.dart';
import '../utils/maps_launcher.dart';
import 'event_details_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/map_pin_marker.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/map_theme_toggle.dart';
import '../widgets/map_filters_sheet.dart';
import '../widgets/live_location_layer.dart';
import '../l10n/l10n_extensions.dart';

/// Карта всех предстоящих сходок. Метки берутся из лёгкого /api/events/map —
/// той же ручки, что бэкенд отдаёт для карты, просто с широкой рамкой на весь мир,
/// т.к. в приложении пока нет привязки к текущей геопозиции пользователя.
/// При открытии карта сама подстраивается (зум + центр), чтобы все метки
/// были видны сразу, без ручного зумирования.
class EventsMapScreen extends StatefulWidget {
  const EventsMapScreen({Key? key}) : super(key: key);

  @override
  State<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends State<EventsMapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _markers = [];
  bool _isLoading = true;
  final Set<String> _selectedCategories = {};

  MapThemeMode _mapTheme = MapThemeMode.auto;
  late final LiveLocationController _liveLocation;

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
    _liveLocation = LiveLocationController(
      getToken: () => Provider.of<AuthProvider>(context, listen: false).accessToken,
    );
    _liveLocation.addListener(_onLiveLocationChanged);
    _liveLocation.start();
  }

  @override
  void dispose() {
    _liveLocation.removeListener(_onLiveLocationChanged);
    _liveLocation.disposeController();
    super.dispose();
  }

  void _onLiveLocationChanged() {
    if (mounted) setState(() {});
  }

  void _showPeerSheet(Map<String, dynamic> peer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tArgs('live_location.peer_sharing', {'username': '${peer['username'] ?? ''}'}),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/events/map?min_lat=-90&max_lat=90&min_lon=-180&max_lon=180&only_upcoming=true&limit=500',
        token: authProvider.accessToken,
      );
      setState(() => _markers = response is List ? response : []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('events_map.error_message', {'error': '$e'}))));
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
                Icon(eventTypeIcon(marker['event_type']), color: eventTypeColor(marker['event_type'])),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(marker['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(eventTypeLabel(context, marker['event_type']), style: const TextStyle(color: Colors.grey)),
            if ((marker['city'] ?? '').toString().isNotEmpty)
              Text(marker['city'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(context.tArgs('events_map.participants_count', {'count': '${marker['participants_count'] ?? 0}'})),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${marker['average_rating'] ?? 0}'),
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
                      label: Text(context.t('events_map.directions')),
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
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(event: {'id': marker['id'], 'title': marker['title']}),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(context.t('events_map.open_event'), style: const TextStyle(color: Colors.white)),
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
        : _markers.where((m) => _selectedCategories.contains(m['event_type'])).toList();
    final markers = visibleMarkers
        .where((m) => m['latitude'] != null && m['longitude'] != null)
        .map<Marker>((m) {
      final style = eventTypeStyleByValue(m['event_type']);
      return Marker(
        point: LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showMarkerSheet(m as Map<String, dynamic>),
          child: MapPinMarker(icon: style.icon, color: style.color),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('events_map.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
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
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.35, 0.35, 0.35, 0, 0,
                  0.35, 0.35, 0.35, 0, 0,
                  0.35, 0.35, 0.35, 0, 0,
                  0,    0,    0,    1, 0,
                ]),
                child: TileLayer(
                  urlTemplate: _effectiveTileUrl(context),
                  subdomains: tileSubdomains,
                  userAgentPackageName: mapUserAgentPackageName,
                ),
              ),
              MarkerLayer(
                markers: [
                  ...markers,
                  ..._liveLocation.buildPeerMarkers(onTap: _showPeerSheet),
                  if (_liveLocation.buildSelfMarker() != null) _liveLocation.buildSelfMarker()!,
                ],
              ),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Row(
                    children: [
                      MapThemeToggle(
                        value: _mapTheme,
                        onChanged: (m) => setState(() => _mapTheme = m),
                      ),
                      const SizedBox(width: 8),
                      LiveLocationToggleButton(
                        active: _liveLocation.sharing,
                        onTap: () => showLiveLocationSheet(context, _liveLocation),
                      ),
                      const Spacer(),
                      _FilterIconButton(
                        active: _selectedCategories.isNotEmpty,
                        onTap: () => showMapFiltersSheet(
                          context: context,
                          items: eventTypeStyles
                              .map((t) => FilterChipData(t.value, context.t(t.labelKey), t.icon, t.color))
                              .toList(),
                          selected: _selectedCategories,
                          onToggle: (v) => setState(() => _toggleCategory(v)),
                          onClear: () => setState(() => _selectedCategories.clear()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) Positioned(top: 90, left: 0, right: 0, child: Center(child: AppLoader())),
          if (!_isLoading && markers.isEmpty)
            Positioned(
              top: 90,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceDarkAlt, borderRadius: BorderRadius.circular(10)),
                child: Text(context.t('events_map.no_events'), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}

/// Кнопка-иконка "фильтры" рядом с переключателем темы карты — открывает
/// bottom-sheet с категориями (см. map_filters_sheet.dart). Синяя точка —
/// индикатор, что фильтр сейчас применён (как в референсе CCS).
class _FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterIconButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(child: Icon(Icons.tune, size: 18, color: Colors.white)),
            if (active)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
