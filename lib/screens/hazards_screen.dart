import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';
import '../utils/map_config.dart';
import '../widgets/app_loader.dart';

const Map<String, String> _typeLabels = {
  'camera': 'Камера',
  'pothole': 'Яма',
  'ice': 'Гололёд',
  'accident': 'ДТП',
  'police': 'Пост ДПС',
  'other': 'Другое',
};

const Map<String, IconData> _typeIcons = {
  'camera': Icons.camera_alt,
  'pothole': Icons.warning,
  'ice': Icons.ac_unit,
  'accident': Icons.car_crash,
  'police': Icons.local_police,
  'other': Icons.report_problem,
};

const Map<String, Color> _typeColors = {
  'camera': Colors.purple,
  'pothole': Colors.brown,
  'ice': AppColors.blue,
  'accident': AppColors.red,
  'police': Colors.indigo,
  'other': Colors.grey,
};

/// Карта дорожных опасностей от сообщества: камеры, ямы, гололёд, ДТП, посты ДПС.
/// GET /api/hazards/nearby, POST /api/hazards, POST /api/hazards/{id}/vote.
class HazardsScreen extends StatefulWidget {
  const HazardsScreen({Key? key}) : super(key: key);

  @override
  State<HazardsScreen> createState() => _HazardsScreenState();
}

class _HazardsScreenState extends State<HazardsScreen> {
  final _mapController = MapController();
  List<dynamic> _hazards = [];
  LatLng _center = const LatLng(55.751244, 37.618423);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final position = await determineCurrentPosition();
    if (position != null) {
      _center = LatLng(position.latitude, position.longitude);
    }
    await _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get(
        '/api/hazards/nearby?lat=${_center.latitude}&lng=${_center.longitude}&radius_km=15',
        token: authProvider.accessToken,
      );
      final items = response is Map && response['items'] is List ? response['items'] as List : [];
      setState(() => _hazards = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addHazardAt(LatLng point) async {
    String type = 'pothole';
    final noteController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Отметить опасность'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: _typeLabels.entries.map((e) {
                  final selected = type == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    avatar: Icon(_typeIcons[e.key], size: 16),
                    selected: selected,
                    onSelected: (_) => setDialogState(() => type = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Заметка (необязательно)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Отметить')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/hazards',
        {
          'type': type,
          'latitude': point.latitude,
          'longitude': point.longitude,
          if (noteController.text.trim().isNotEmpty) 'note': noteController.text.trim(),
        },
        token: authProvider.accessToken,
      );
      _loadNearby();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _vote(String hazardId, String vote) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/hazards/$hazardId/vote', {'vote': vote}, token: authProvider.accessToken);
      _loadNearby();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showHazardSheet(Map<String, dynamic> hazard) {
    final type = (hazard['type'] as String?) ?? 'other';
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_typeIcons[type], color: _typeColors[type]),
                const SizedBox(width: 8),
                Text(_typeLabels[type] ?? type, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            if ((hazard['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hazard['note']),
            ],
            const SizedBox(height: 12),
            Text('Подтвердили: ${hazard['confirms_count'] ?? 0} · Опровергли: ${hazard['denies_count'] ?? 0}',
                style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _vote(hazard['id'] as String, 'confirm');
                    },
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Актуально'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _vote(hazard['id'] as String, 'deny');
                    },
                    icon: const Icon(Icons.close, color: AppColors.red),
                    label: const Text('Не актуально'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Дорожные опасности'), backgroundColor: AppColors.black),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onLongPress: (tapPosition, point) => _addHazardAt(point),
            ),
            children: [
              TileLayer(
                urlTemplate: activeTileUrlTemplate,
                subdomains: tileSubdomains,
                userAgentPackageName: mapUserAgentPackageName,
              ),
              MarkerLayer(
                markers: _hazards.map((h) {
                  final hazard = h as Map<String, dynamic>;
                  final type = (hazard['type'] as String?) ?? 'other';
                  final lat = (hazard['latitude'] as num).toDouble();
                  final lng = (hazard['longitude'] as num).toDouble();
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showHazardSheet(hazard),
                      child: CircleAvatar(
                        backgroundColor: _typeColors[type] ?? Colors.grey,
                        child: Icon(_typeIcons[type] ?? Icons.report_problem, color: Colors.white, size: 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading) const Center(child: AppLoader()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkAlt.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Долгое нажатие на карте — отметить опасность',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
