/// Общие настройки карты.
///
/// Тайлы — OpenStreetMap (стандартный публичный XYZ-тайл сервер).
///
/// Раньше здесь были неофициальные тайлы Яндекс.Карт, но выяснилось, что
/// этот способ отдаёт тайлы НЕ по реальным географическим координатам
/// (проверено: тайл для координат центра Тбилиси и тайл для координат
/// Красной площади в Москве по стандартной формуле z/x/y оба раза
/// показывали случайную непричастную местность) — из-за этого метки на
/// карте (сходки, автосервисы) оказывались смещены в случайные места,
/// вплоть до гор. Переключились на OSM, чтобы метки были на своих местах.
///
/// Если понадобится точный фирменный вид Яндекс.Карт — единственный
/// надёжный путь это официальный yandex_mapkit с API-ключом (потребует
/// ключ на yandex.ru/dev и нативную настройку под Android/iOS).
import 'package:latlong2/latlong.dart';

const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Активный источник тайлов карты — используется во всех экранах с картой.
const String activeTileUrlTemplate = osmTileUrlTemplate;

const String osmAttribution = '© OpenStreetMap contributors';
const String mapUserAgentPackageName = 'com.carspot.app';

/// Тбилиси — то же значение, что раньше было захардкожено при создании сходки.
const LatLng defaultMapCenter = LatLng(41.7151, 44.7671);

const double defaultMapZoom = 12.0;
const double worldMapZoom = 3.0;
