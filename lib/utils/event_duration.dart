/// Общий список вариантов продолжительности сходки — используется и при
/// создании, и при редактировании, чтобы не расходились варианты выбора.
/// Сходка автоматически становится неактивной (пропадает из списков), когда
/// проходит event_date + duration_minutes — это считает сервер сам.
library event_duration;

import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

class DurationOption {
  final int minutes;
  final String labelKey;
  const DurationOption(this.minutes, this.labelKey);
}

const List<DurationOption> eventDurationOptions = [
  DurationOption(30, 'event_duration.min30'),
  DurationOption(60, 'event_duration.h1'),
  DurationOption(90, 'event_duration.h1_5'),
  DurationOption(120, 'event_duration.h2'),
  DurationOption(180, 'event_duration.h3'),
  DurationOption(240, 'event_duration.h4'),
  DurationOption(360, 'event_duration.h6'),
  DurationOption(480, 'event_duration.h8'),
  DurationOption(720, 'event_duration.h12'),
  DurationOption(1440, 'event_duration.h24'),
  DurationOption(2880, 'event_duration.d2'),
  DurationOption(4320, 'event_duration.d3'),
  DurationOption(10080, 'event_duration.d7'),
];

String formatEventDuration(BuildContext context, int minutes) {
  for (final o in eventDurationOptions) {
    if (o.minutes == minutes) return context.t(o.labelKey);
  }
  if (minutes < 60) return context.tArgs('event_duration.fmt_min', {'minutes': '$minutes'});
  if (minutes % 1440 == 0) return context.tArgs('event_duration.fmt_day', {'days': '${minutes ~/ 1440}'});
  if (minutes % 60 == 0) return context.tArgs('event_duration.fmt_hour', {'hours': '${minutes ~/ 60}'});
  return context.tArgs('event_duration.fmt_hour_min', {'hours': '${minutes ~/ 60}', 'minutes': '${minutes % 60}'});
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
