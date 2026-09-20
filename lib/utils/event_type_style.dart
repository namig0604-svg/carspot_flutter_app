import 'package:flutter/material.dart';

/// Иконка и цвет метки на карте для каждого типа сходки — должны совпадать
/// со значениями EVENT_TYPES на бэкенде (app/models/event.py).
class EventTypeStyle {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const EventTypeStyle(this.value, this.label, this.icon, this.color);
}

const List<EventTypeStyle> eventTypeStyles = [
  EventTypeStyle('meetup', 'Сходка', Icons.groups, Colors.blue),
  EventTypeStyle('racing', 'Заезды', Icons.emoji_events, Colors.red),
  EventTypeStyle('drift', 'Дрифт', Icons.whatshot, Colors.deepPurple),
  EventTypeStyle('drag', 'Драг', Icons.bolt, Colors.orange),
  EventTypeStyle('offroad', 'Офф-роуд', Icons.terrain, Colors.brown),
  EventTypeStyle('show', 'Автовыставка', Icons.star, Colors.amber),
  EventTypeStyle('cruise', 'Покатушки', Icons.directions_car, Colors.teal),
  EventTypeStyle('track_day', 'Трек-день', Icons.timer, Colors.indigo),
  EventTypeStyle('charity', 'Благотворительность', Icons.volunteer_activism, Colors.pink),
  EventTypeStyle('other', 'Другое', Icons.location_on, Colors.grey),
];

EventTypeStyle eventTypeStyleByValue(String? value) {
  return eventTypeStyles.firstWhere(
    (t) => t.value == value,
    orElse: () => eventTypeStyles.last,
  );
}

IconData eventTypeIcon(String? value) => eventTypeStyleByValue(value).icon;

Color eventTypeColor(String? value) => eventTypeStyleByValue(value).color;

String eventTypeLabel(String? value) => eventTypeStyleByValue(value).label;
