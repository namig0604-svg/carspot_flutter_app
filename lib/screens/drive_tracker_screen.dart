import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/trip_tracker_service.dart';
import '../theme/app_colors.dart';
import '../utils/map_config.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_picker_field.dart';
import '../l10n/l10n_extensions.dart';
import 'trip_detail_screen.dart';

/// Запись новой поездки: выбор машины (необязательно) → "Начать поездку" →
/// живая карта с маршрутом, дистанцией, временем и текущей скоростью →
/// "Завершить поездку" сохраняет её на сервере и открывает экран деталей.
///
/// Работает, пока этот экран открыт (см. TripTrackerService) — сворачивание
/// приложения или блокировка экрана останавливают запись GPS, как и в
/// большинстве похожих трекеров без отдельного фонового сервиса.
class DriveTrackerScreen extends StatefulWidget {
  const DriveTrackerScreen({Key? key}) : super(key: key);

  @override
  State<DriveTrackerScreen> createState() => _DriveTrackerScreenState();
}

class _DriveTrackerScreenState extends State<DriveTrackerScreen> {
  final TripTrackerService _tracker = TripTrackerService();
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedCar;
  bool _isSaving = false;
  bool _mapReady = false;

  @override
  void dispose() {
    // Если пользователь ушёл с экрана прямо во время записи (не через кнопку
    // "Завершить") — не оставляем GPS-слежение висеть в фоне без экрана.
    _tracker.discard();
    _tracker.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final failure = await _tracker.start();
    if (!mounted) return;
    if (failure != null) {
      final key = failure == TripStartFailure.serviceDisabled
          ? 'drive_tracker.location_service_disabled'
          : 'drive_tracker.location_permission_denied';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t(key))));
      return;
    }
    setState(() {});
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('drive_tracker.cancel_confirm_title')),
        content: Text(dialogContext.t('drive_tracker.cancel_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.t('drive_tracker.cancel_confirm_no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.t('drive_tracker.cancel_confirm_yes'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _tracker.discard();
      setState(() {});
    }
  }

  Future<void> _stop() async {
    final recorded = _tracker.stop();
    if (!mounted) return;
    setState(() {});

    if (recorded == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('drive_tracker.too_short'))));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/trips',
        recorded.toJson(_selectedCar?['id'] as String?),
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      if (response is Map<String, dynamic> && response['id'] != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: response['id'] as String, initialData: response)),
        );
        return;
      }
      throw Exception('unexpected response');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('drive_tracker.save_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}ч ${m.toString().padLeft(2, '0')}м';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(context.t('drive_tracker.title')),
      ),
      body: AnimatedBuilder(
        animation: _tracker,
        builder: (context, _) {
          if (!_tracker.isTracking) return _buildIdle(context);
          return _buildTracking(context);
        },
      ),
    );
  }

  Widget _buildIdle(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.route, size: 72, color: AppColors.blue),
            const SizedBox(height: 16),
            Text(
              context.t('drive_tracker.intro_text'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
            ),
            const SizedBox(height: 24),
            CarPickerField(onSelected: (car) => setState(() => _selectedCar = car)),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _start,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.t('drive_tracker.start_button'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracking(BuildContext context) {
    final routePoints = _tracker.points.map((p) => LatLng(p.lat, p.lng)).toList();
    if (routePoints.isNotEmpty && _mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(routePoints.last, 16);
        } catch (_) {}
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: routePoints.isNotEmpty ? routePoints.last : defaultMapCenter,
            initialZoom: 16,
            onMapReady: () => _mapReady = true,
          ),
          children: [
            TileLayer(
              urlTemplate: activeTileUrlTemplate,
              subdomains: tileSubdomains,
              userAgentPackageName: mapUserAgentPackageName,
            ),
            if (routePoints.length >= 2)
              PolylineLayer(polylines: [Polyline(points: routePoints, color: AppColors.blue, strokeWidth: 4)]),
            if (routePoints.isNotEmpty)
              MarkerLayer(markers: [
                Marker(
                  point: routePoints.last,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ]),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(0.96), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn(context, Icons.route, '${_tracker.distanceKm.toStringAsFixed(1)} ${context.t('drive_tracker.unit_km')}', context.t('drive_tracker.distance_label')),
                      _statColumn(context, Icons.timer_outlined, _formatDuration(_tracker.elapsed), context.t('drive_tracker.duration_label')),
                      _statColumn(context, Icons.speed, '${_tracker.currentSpeedKmh.toStringAsFixed(0)} ${context.t('drive_tracker.unit_kmh')}', context.t('drive_tracker.speed_label')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _confirmCancel,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(context.t('drive_tracker.cancel_button')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _stop,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: AppLoader(size: 20))
                            : Text(context.t('drive_tracker.stop_button'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statColumn(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.blue, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
      ],
    );
  }
}
