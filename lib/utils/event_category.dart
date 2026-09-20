/// Типы сходок — значения должны совпадать с тем, что шлёт/принимает бэкенд
/// (event_type), а лейблы/иконки — только для отображения на русском.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EventCategoryOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const EventCategoryOption(this.value, this.label, this.icon, this.color);
}

const List<EventCategoryOption> eventCategories = [
  EventCategoryOption('all', 'Все', Icons.apps, AppColors.blue),
  EventCategoryOption('meetup', 'Тусовка', Icons.groups, AppColors.blue),
  EventCategoryOption('racing', 'Гонки', Icons.speed, AppColors.red),
  EventCategoryOption('drift', 'Дрифт', Icons.blur_on, AppColors.red),
  EventCategoryOption('drag', 'Драг', Icons.bolt, AppColors.red),
  EventCategoryOption('offroad', 'Офроуд', Icons.terrain, AppColors.blue),
  EventCategoryOption('show', 'Автошоу', Icons.star, Colors.amber),
  EventCategoryOption('cruise', 'Круиз', Icons.route, AppColors.blue),
  EventCategoryOption('track_day', 'Трек-день', Icons.flag, AppColors.red),
  EventCategoryOption('charity', 'Благотворительность', Icons.favorite, Colors.pinkAccent),
];

EventCategoryOption eventCategoryByValue(String? value) {
  return eventCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => eventCategories.first,
  );
}

String eventCategoryLabel(String? value) => eventCategoryByValue(value).label;

IconData eventCategoryIcon(String? value) => eventCategoryByValue(value).icon;

Color eventCategoryColor(String? value) => eventCategoryByValue(value).color;
