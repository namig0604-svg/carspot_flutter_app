import 'package:flutter/widgets.dart';
import '../l10n/l10n_extensions.dart';

/// Форматирует расстояние в метрах в короткую подпись вида "850 м" / "12.3 км".
String formatDistance(BuildContext context, double meters) {
  if (meters < 1000) {
    return context.tArgs('common.distance_m', {'value': meters.round().toString()});
  }
  final km = meters / 1000;
  final value = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
  return context.tArgs('common.distance_km', {'value': value});
}
