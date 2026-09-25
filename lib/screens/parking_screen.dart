import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';
import '../utils/map_config.dart';
import '../utils/maps_launcher.dart';
import '../widgets/app_loader.dart';
import '../widgets/map_pin_marker.dart';

/// "Где я припарковался": сохраняет текущую геопозицию одной кнопкой,
/// показывает метку на карте и строит маршрут обратно во внешнем навигаторе.
/// GET/POST/DELETE /api/parking.
class ParkingScreen extends StatefulWidget {
  const ParkingScreen({Key? key}) : super(key: key);

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  Map<String, dynamic>? _spot;
  bool _isLoading = true;
  bool _isSaving = false;
  final _noteController = TextEditingController();
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/parking/mine', token: authProvider.accessToken);
      if (response is Map<String, dynamic>) {
        setState(() => _spot = response);
      }
    } catch (_) {
      // 404 — метки ещё нет, это нормальное состояние.
      setState(() => _spot = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHere() async {
    setState(() => _isSaving = true);
    try {
      final position = await determineCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось определить геопозицию — проверьте разрешения')),
          );
        }
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/parking',
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      if (response is Map<String, dynamic>) {
        setState(() => _spot = response);
        _mapController.move(LatLng(position.latitude, position.longitude), 16);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Место парковки сохранено')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clear() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/parking/mine', token: authProvider.accessToken);
      setState(() => _spot = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = _spot;
    final hasSpot = spot != null && spot['latitude'] != null && spot['longitude'] != null;
    final point = hasSpot
        ? LatLng((spot['latitude'] as num).toDouble(), (spot['longitude'] as num).toDouble())
        : const LatLng(55.751244, 37.618423);

    return Scaffold(
      appBar: AppBar(title: const Text('Где я припарковался'), backgroundColor: AppColors.black),
      body: _isLoading
          ? const Center(child: AppLoader())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(initialCenter: point, initialZoom: hasSpot ? 16 : 11),
                        children: [
                          TileLayer(
                            urlTemplate: activeTileUrlTemplate,
                            subdomains: tileSubdomains,
                            userAgentPackageName: mapUserAgentPackageName,
                          ),
                          if (hasSpot)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.bottomCenter,
                                  child: const MapPinMarker(icon: Icons.local_parking, color: AppColors.blue),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (!hasSpot)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDarkAlt.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Метки пока нет. Нажмите «Я здесь припарковался», когда оставите машину.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (hasSpot && (spot['note'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('Заметка: ${spot['note']}', style: const TextStyle(color: AppColors.textMutedDark)),
                        ),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'Заметка (например: 3 этаж, синий сектор)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveHere,
                          icon: _isSaving ? const AppLoader(size: 20, color: Colors.white) : const Icon(Icons.my_location),
                          label: const Text('Я здесь припарковался'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                        ),
                      ),
                      if (hasSpot) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => openDirections(context, point.latitude, point.longitude),
                                icon: const Icon(Icons.directions),
                                label: const Text('Маршрут туда'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _clear,
                                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                                label: const Text('Убрать метку', style: TextStyle(color: AppColors.red)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
