/// Общие настройки карты (OpenStreetMap, без API-ключей и аккаунтов).
import 'package:latlong2/latlong.dart';

const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String osmAttribution = '© OpenStreetMap contributors';
const String mapUserAgentPackageName = 'com.carspot.app';

/// Тбилиси — то же значение, что раньше было захардкожено при создании сходки.
const LatLng defaultMapCenter = LatLng(41.7151, 44.7671);

const double defaultMapZoom = 12.0;
const double worldMapZoom = 3.0;
