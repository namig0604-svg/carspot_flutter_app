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

  @override
  void initState() {
    super.initState();
    _load();
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
            Text(eventTypeLabel(marker['event_type']), style: const TextStyle(color: Colors.grey)),
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

  @override
  Widget build(BuildContext context) {
    final markers = _markers
        .where((m) => m['latitude'] != null && m['longitude'] != null)
        .map<Marker>((m) {
      final style = eventTypeStyleByValue(m['event_type']);
      return Marker(
        point: LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showMarkerSheet(m as Map<String, dynamic>),
          child: Icon(style.icon, color: style.color, size: 36),
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
              TileLayer(
                urlTemplate: yandexTileUrlTemplate,
                userAgentPackageName: mapUserAgentPackageName,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (_isLoading) Positioned(top: 12, left: 0, right: 0, child: Center(child: AppLoader())),
          if (!_isLoading && markers.isEmpty)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Text(context.t('events_map.no_events'), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
