/// Общие настройки карты.
///
/// Тайлы — Яндекс.Карт (без официального SDK и ключей, просто как источник
/// растровых тайлов в обычном flutter_map — визуально привычная Яндекс-карта).
/// Это неофициальный способ: у Яндекса нет публичного бесплатного XYZ-тайл
/// API для сторонних приложений, так что этот URL не гарантирован контрактом
/// и может перестать отдавать тайлы без предупреждения. Если это случится —
/// самый надёжный вариант отката: вернуть osmTileUrlTemplate ниже в
/// urlTemplate у TileLayer, либо подключить официальный yandex_mapkit
/// с API-ключом (потребует ключ на yandex.ru/dev и настройку под Android/iOS).
import 'package:latlong2/latlong.dart';

const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String yandexTileUrlTemplate =
    'https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x={x}&y={y}&z={z}&scale=1&lang=ru_RU';
const String osmAttribution = '© Яндекс.Карты';
const String mapUserAgentPackageName = 'com.carspot.app';

/// Тбилиси — то же значение, что раньше было захардкожено при создании сходки.
const LatLng defaultMapCenter = LatLng(41.7151, 44.7671);

const double defaultMapZoom = 12.0;
const double worldMapZoom = 3.0;
