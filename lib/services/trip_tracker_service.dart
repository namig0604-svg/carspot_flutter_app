import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Одна точка маршрута, уже в виде, готовом для отправки на бэкенд
/// (см. TripPoint в carspot_project_backend/app/schemas/trip.py: lat/lng/t/speed_kmh).
class TripRoutePoint {
  final double lat;
  final double lng;
  final int t; // секунд от начала поездки
  final double speedKmh;

  const TripRoutePoint({required this.lat, required this.lng, required this.t, required this.speedKmh});

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 't': t, 'speed_kmh': speedKmh};
}

/// Итог законченной поездки — то, что отправляется в POST /api/trips.
class RecordedTrip {
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final int durationS;
  final double avgSpeedKmh;
  final double topSpeedKmh;
  final List<TripRoutePoint> route;

  const RecordedTrip({
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.durationS,
    required this.avgSpeedKmh,
    required this.topSpeedKmh,
    required this.route,
  });

  Map<String, dynamic> toJson(String? carId) => {
        if (carId != null) 'car_id': carId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'distance_km': distanceKm,
        'duration_s': durationS,
        'avg_speed_kmh': avgSpeedKmh,
        'top_speed_kmh': topSpeedKmh,
        'route': route.map((p) => p.toJson()).toList(),
      };
}

/// Причина, по которой не удалось начать запись поездки — чтобы экран мог
/// показать пользователю понятное сообщение вместо общего "не получилось".
enum TripStartFailure { serviceDisabled, permissionDenied }

/// Живое слежение за поездкой: старт/стоп записи GPS-маршрута, на лету
/// считает дистанцию (Geolocator.distanceBetween между соседними точками),
/// текущую/максимальную скорость и длительность.
///
/// Работает только пока открыт экран записи (приложение на переднем плане) —
/// полноценного фонового трекинга (когда телефон лежит в кармане, а экран
/// заблокирован) здесь нет: для веб-версии это в принципе невозможно, а для
/// Android потребовало бы отдельного foreground-сервиса. Для первой версии
/// трекера этого достаточно — как и многие похожие приложения, пользователь
/// держит экран открытым (или просто включённым) во время поездки.
class TripTrackerService extends ChangeNotifier {
  bool _isTracking = false;
  DateTime? _startedAt;
  final List<TripRoutePoint> _points = [];
  double _distanceKm = 0;
  double _currentSpeedKmh = 0;
  double _topSpeedKmh = 0;

  StreamSubscription<Position>? _positionSub;
  Timer? _tickTimer;

  bool get isTracking => _isTracking;
  double get distanceKm => _distanceKm;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get topSpeedKmh => _topSpeedKmh;
  int get pointsCount => _points.length;
  List<TripRoutePoint> get points => List.unmodifiable(_points);

  Duration get elapsed {
    final started = _startedAt;
    if (started == null) return Duration.zero;
    return DateTime.now().difference(started);
  }

  /// Пытается начать запись. Возвращает null при успехе, иначе причину
  /// отказа — экран сам решает, какое сообщение показать пользователю.
  Future<TripStartFailure?> start() async {
    if (_isTracking) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return TripStartFailure.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return TripStartFailure.permissionDenied;
    }

    _points.clear();
    _distanceKm = 0;
    _currentSpeedKmh = 0;
    _topSpeedKmh = 0;
    _startedAt = DateTime.now();
    _isTracking = true;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen(_onPosition, onError: (_) {});

    // Таймер только для того, чтобы секундомер на экране шёл сам по себе —
    // между точками GPS может пройти больше секунды.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());

    notifyListeners();
    return null;
  }

  void _onPosition(Position pos) {
    final started = _startedAt;
    if (started == null || !_isTracking) return;

    // Position.speed — м/с от GPS-чипа устройства; иногда шумит на низкой
    // скорости, но для первой версии трекера отдельного сглаживания не
    // делаем (как и с остальными "трекер"-фичами проекта — см. fuel_tracker).
    final speedKmh = (pos.speed.isFinite && pos.speed > 0) ? pos.speed * 3.6 : 0.0;
    final t = DateTime.now().difference(started).inSeconds;

    if (_points.isNotEmpty) {
      final last = _points.last;
      final meters = Geolocator.distanceBetween(last.lat, last.lng, pos.latitude, pos.longitude);
      // Фильтр от GPS-дрожания на месте: меньше 2 метров между точками не
      // считаем движением, иначе дистанция "натекает" даже стоя на парковке.
      if (meters >= 2) {
        _distanceKm += meters / 1000;
      }
    }

    _points.add(TripRoutePoint(lat: pos.latitude, lng: pos.longitude, t: t, speedKmh: speedKmh));
    _currentSpeedKmh = speedKmh;
    if (speedKmh > _topSpeedKmh) _topSpeedKmh = speedKmh;

    notifyListeners();
  }

  /// Останавливает запись и возвращает итог — null, если точек меньше двух
  /// (слишком короткая поездка, сохранять нечего, карте не на чем рисовать
  /// линию маршрута).
  RecordedTrip? stop() {
    final started = _startedAt;
    _positionSub?.cancel();
    _positionSub = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _isTracking = false;

    RecordedTrip? result;
    if (started != null && _points.length >= 2) {
      final endedAt = DateTime.now();
      final durationS = endedAt.difference(started).inSeconds;
      final avgSpeedKmh = durationS > 0 ? _distanceKm / (durationS / 3600) : 0.0;
      result = RecordedTrip(
        startedAt: started,
        endedAt: endedAt,
        distanceKm: double.parse(_distanceKm.toStringAsFixed(2)),
        durationS: durationS,
        avgSpeedKmh: double.parse(avgSpeedKmh.toStringAsFixed(1)),
        topSpeedKmh: double.parse(_topSpeedKmh.toStringAsFixed(1)),
        route: List.unmodifiable(_points),
      );
    }

    _startedAt = null;
    notifyListeners();
    return result;
  }

  /// Прерывает запись без сохранения (пользователь передумал).
  void discard() {
    _positionSub?.cancel();
    _positionSub = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _isTracking = false;
    _startedAt = null;
    _points.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }
}
