import 'package:geolocator/geolocator.dart';

/// Общая логика получения геопозиции пользователя — с аккуратной обработкой
/// прав доступа, чтобы каждый экран не дублировал одно и то же.
///
/// Возвращает null, если позицию получить не удалось (сервис выключен,
/// доступ не дан или дан навсегда запрещён, таймаут) — вызывающий код в
/// этом случае должен молча откатиться на поведение без геопозиции
/// (например sort=recommended на бэкенде и без lat/lon — по рейтингу),
/// а не показывать пользователю ошибку.
Future<Position?> determineCurrentPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  } catch (_) {
    return null;
  }
}
