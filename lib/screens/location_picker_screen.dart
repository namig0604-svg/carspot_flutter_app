import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/map_config.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

/// Выбор точки на карте тапом. Возвращает {'latitude': double, 'longitude': double}
/// через Navigator.pop, либо null если отменили.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({Key? key, this.initialLatitude, this.initialLongitude}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _picked = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? defaultMapCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('location_picker.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: defaultMapZoom,
              onTap: (tapPosition, point) {
                setState(() => _picked = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: activeTileUrlTemplate,
                subdomains: tileSubdomains,
                userAgentPackageName: mapUserAgentPackageName,
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_pin, color: AppColors.red, size: 44),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [TextSourceAttribution(osmAttribution)],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
              ),
              child: Text(
                _picked == null
                    ? context.t('location_picker.tap_hint')
                    : '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _picked == null
            ? null
            : () {
                Navigator.pop(context, {
                  'latitude': _picked!.latitude,
                  'longitude': _picked!.longitude,
                });
              },
        backgroundColor: _picked == null ? Colors.grey : AppColors.blue,
        icon: const Icon(Icons.check),
        label: Text(context.t('common.confirm')),
      ),
    );
  }
}
