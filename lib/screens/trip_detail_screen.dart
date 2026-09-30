import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/map_config.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Полоса скорости для гистограммы распределения и раскраски маршрута —
/// границы в км/ч (аналог референса, где диапазоны были в mph).
class _SpeedBand {
  final String key;
  final Color color;
  final double maxKmh; // верхняя граница (включительно), последняя — без верха

  const _SpeedBand(this.key, this.color, this.maxKmh);
}

const List<_SpeedBand> _kSpeedBands = [
  _SpeedBand('low', AppColors.blue, 30),
  _SpeedBand('mid', Color(0xFF35C15C), 60),
  _SpeedBand('high', AppColors.amber, 90),
  _SpeedBand('vhigh', AppColors.red, double.infinity),
];

int _bandIndexFor(double speedKmh) {
  for (var i = 0; i < _kSpeedBands.length; i++) {
    if (speedKmh <= _kSpeedBands[i].maxKmh) return i;
  }
  return _kSpeedBands.length - 1;
}

/// Детали одной поездки: карта с маршрутом (цвет линии меняется по скорости
/// сегмента), дистанция/время/макс.скорость, распределение скорости по
/// диапазонам. Принимает либо готовые данные (сразу после записи — см.
/// DriveTrackerScreen), либо только id и сам загружает GET /api/trips/{id}.
class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic>? initialData;

  const TripDetailScreen({Key? key, required this.tripId, this.initialData}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _trip;
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!['route'] != null) {
      _trip = widget.initialData;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/trips/${widget.tripId}', token: authProvider.accessToken);
      if (response is Map<String, dynamic>) {
        setState(() => _trip = response);
      }
    } catch (e) {
      setState(() => _error = context.t('trip_detail.load_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('trip_detail.delete_confirm_title')),
        content: Text(dialogContext.t('trip_detail.delete_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('carpool.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.t('trip_detail.delete_button'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/trips/${widget.tripId}', token: authProvider.accessToken);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(context.t('trip_detail.title')),
        actions: [
          if (_trip != null)
            IconButton(
              icon: _isDeleting ? const SizedBox(width: 18, height: 18, child: AppLoader(size: 18)) : const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader(size: 32))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textMutedDark)))
              : _trip == null
                  ? const SizedBox.shrink()
                  : _buildContent(context, _trip!),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> trip) {
    final route = (trip['route'] as List? ?? [])
        .map((p) => p as Map<String, dynamic>)
        .toList();
    final points = route.map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();

    final distanceKm = (trip['distance_km'] as num?)?.toDouble() ?? 0;
    final durationS = (trip['duration_s'] as num?)?.toInt() ?? 0;
    final topSpeed = (trip['top_speed_kmh'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: points.length < 2
                ? Container(color: AppColors.surfaceDark)
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: points.first,
                      initialZoom: 13,
                      onMapReady: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          try {
                            _mapController.fitCamera(
                              CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(32)),
                            );
                          } catch (_) {}
                        });
                      },
                    ),
                    children: [
                      TileLayer(urlTemplate: activeTileUrlTemplate, subdomains: tileSubdomains, userAgentPackageName: mapUserAgentPackageName),
                      PolylineLayer(polylines: _buildSpeedPolylines(route, points)),
                      MarkerLayer(markers: [
                        Marker(point: points.first, width: 16, height: 16, child: _dotMarker(const Color(0xFF35C15C))),
                        Marker(point: points.last, width: 16, height: 16, child: _dotMarker(AppColors.red)),
                      ]),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statTile(context, Icons.route, '${distanceKm.toStringAsFixed(1)} км', context.t('trip_detail.distance')),
            const SizedBox(width: 10),
            _statTile(context, Icons.timer_outlined, _formatDuration(durationS), context.t('trip_detail.duration')),
            const SizedBox(width: 10),
            _statTile(context, Icons.speed, '${topSpeed.toStringAsFixed(0)} км/ч', context.t('trip_detail.top_speed')),
          ],
        ),
        const SizedBox(height: 20),
        Text(context.t('trip_detail.speed_distribution'), style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._buildDistributionRows(context, route),
      ],
    );
  }

  Widget _dotMarker(Color color) => Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      );

  List<Polyline> _buildSpeedPolylines(List<Map<String, dynamic>> route, List<LatLng> points) {
    final segments = <Polyline>[];
    for (var i = 0; i < points.length - 1; i++) {
      final speed = (route[i]['speed_kmh'] as num?)?.toDouble() ?? 0;
      final band = _kSpeedBands[_bandIndexFor(speed)];
      segments.add(Polyline(points: [points[i], points[i + 1]], color: band.color, strokeWidth: 4));
    }
    return segments;
  }

  List<Widget> _buildDistributionRows(BuildContext context, List<Map<String, dynamic>> route) {
    final bandSeconds = List<double>.filled(_kSpeedBands.length, 0);
    double totalSeconds = 0;

    for (var i = 0; i < route.length - 1; i++) {
      final t0 = (route[i]['t'] as num?)?.toDouble() ?? 0;
      final t1 = (route[i + 1]['t'] as num?)?.toDouble() ?? 0;
      final dt = (t1 - t0).clamp(0, double.infinity);
      final speed = (route[i]['speed_kmh'] as num?)?.toDouble() ?? 0;
      bandSeconds[_bandIndexFor(speed)] += dt;
      totalSeconds += dt;
    }

    const labelKeys = ['trip_detail.speed_band_low', 'trip_detail.speed_band_mid', 'trip_detail.speed_band_high', 'trip_detail.speed_band_vhigh'];

    return List.generate(_kSpeedBands.length, (i) {
      final pct = totalSeconds > 0 ? (bandSeconds[i] / totalSeconds * 100) : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _kSpeedBands[i].color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            SizedBox(width: 56, child: Text(context.t(labelKeys[i]), style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceDarkAlt,
                    valueColor: AlwaysStoppedAnimation(_kSpeedBands[i].color),
                  ),
                ),
              ),
            ),
            SizedBox(width: 40, child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textOnDark, fontSize: 12))),
          ],
        ),
      );
    });
  }

  Widget _statTile(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.blue, size: 18),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }
}
