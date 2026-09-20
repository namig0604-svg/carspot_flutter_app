/// Общий список вариантов продолжительности сходки — используется и при
/// создании, и при редактировании, чтобы не расходились варианты выбора.
/// Сходка автоматически становится неактивной (пропадает из списков), когда
/// проходит event_date + duration_minutes — это считает сервер сам.
library event_duration;

class DurationOption {
  final int minutes;
  final String label;
  const DurationOption(this.minutes, this.label);
}

const List<DurationOption> eventDurationOptions = [
  DurationOption(30, '30 минут'),
  DurationOption(60, '1 час'),
  DurationOption(90, '1.5 часа'),
  DurationOption(120, '2 часа'),
  DurationOption(180, '3 часа'),
  DurationOption(240, '4 часа'),
  DurationOption(360, '6 часов'),
  DurationOption(480, '8 часов'),
  DurationOption(720, '12 часов'),
  DurationOption(1440, '24 часа (1 день)'),
  DurationOption(2880, '2 дня'),
  DurationOption(4320, '3 дня'),
  DurationOption(10080, '7 дней'),
];

String formatEventDuration(int minutes) {
  for (final o in eventDurationOptions) {
    if (o.minutes == minutes) return o.label;
  }
  if (minutes < 60) return '$minutes мин';
  if (minutes % 1440 == 0) return '${minutes ~/ 1440} дн.';
  if (minutes % 60 == 0) return '${minutes ~/ 60} ч.';
  return '${minutes ~/ 60} ч ${minutes % 60} мин';
}

/// Ближайшее допустимое значение из списка — на случай, если в данных
/// когда-нибудь окажется значение duration_minutes не из этого набора.
int closestEventDuration(int minutes) {
  if (eventDurationOptions.any((o) => o.minutes == minutes)) return minutes;
  DurationOption closest = eventDurationOptions.first;
  int bestDiff = (closest.minutes - minutes).abs();
  for (final o in eventDurationOptions) {
    final diff = (o.minutes - minutes).abs();
    if (diff < bestDiff) {
      closest = o;
      bestDiff = diff;
    }
  }
  return closest.minutes;
}
