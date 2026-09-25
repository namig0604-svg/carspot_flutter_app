/// Форматирование даты/времени сходки для отображения в UI.
///
/// Бэкенд отдаёт `event_date` как полный ISO-datetime (например
/// "2026-10-01T20:00:00"), а `event_time` — отдельной строкой вида "20:00"
/// только для отображения. Раньше в нескольких экранах их склеивали как
/// есть ('${event_date} ${event_time}'), из-за чего пользователь видел
/// "2026-09-27T18:12:00 18:12". Эта функция достаёт только дату из
/// event_date и красиво объединяет её с event_time (если есть).
library event_date;

String formatEventDateOnly(dynamic eventDate) {
  if (eventDate == null) return '';
  final raw = eventDate.toString();
  try {
    final dt = DateTime.parse(raw).toLocal();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year}';
  } catch (_) {
    // Не смогли распарсить — отдаём то, что пришло, до первого 'T', чтобы
    // хотя бы не дублировать время.
    final tIndex = raw.indexOf('T');
    return tIndex == -1 ? raw : raw.substring(0, tIndex);
  }
}

String formatEventDateTime(dynamic eventDate, [String? eventTime]) {
  final datePart = formatEventDateOnly(eventDate);
  final timePart = (eventTime != null && eventTime.trim().isNotEmpty) ? eventTime.trim() : null;
  if (datePart.isEmpty) return timePart ?? '';
  return timePart != null ? '$datePart · $timePart' : datePart;
}
