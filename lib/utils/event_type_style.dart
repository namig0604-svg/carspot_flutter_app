import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

/// Иконка и цвет метки на карте для каждого типа сходки — должны совпадать
/// со значениями EVENT_TYPES на бэкенде (app/models/event.py). labelKey —
/// ключ локализации для отображения.
class EventTypeStyle {
  final String value;
  final String labelKey;
  final IconData icon;
  final Color color;
  const EventTypeStyle(this.value, this.labelKey, this.icon, this.color);
}

const List<EventTypeStyle> eventTypeStyles = [
  EventTypeStyle('meetup', 'event_type.meetup', Icons.groups, Colors.blue),
  EventTypeStyle('racing', 'event_type.racing', Icons.emoji_events, Colors.red),
  EventTypeStyle('drift', 'event_category.drift', Icons.whatshot, Colors.deepPurple),
  EventTypeStyle('drag', 'event_category.drag', Icons.bolt, Colors.orange),
  EventTypeStyle('offroad', 'event_type.offroad', Icons.terrain, Colors.brown),
  EventTypeStyle('show', 'event_type.show', Icons.star, Colors.amber),
  EventTypeStyle('cruise', 'event_type.cruise', Icons.directions_car, Colors.teal),
  EventTypeStyle('track_day', 'event_category.track_day', Icons.timer, Colors.indigo),
  EventTypeStyle('charity', 'event_category.charity', Icons.volunteer_activism, Colors.pink),
  EventTypeStyle('other', 'hazards.type_other', Icons.location_on, Colors.grey),
];

EventTypeStyle eventTypeStyleByValue(String? value) {
  return eventTypeStyles.firstWhere(
    (t) => t.value == value,
    orElse: () => eventTypeStyles.last,
  );
}

IconData eventTypeIcon(String? value) => eventTypeStyleByValue(value).icon;

Color eventTypeColor(String? value) => eventTypeStyleByValue(value).color;

String eventTypeLabel(BuildContext context, String? value) =>
    context.t(eventTypeStyleByValue(value).labelKey);
