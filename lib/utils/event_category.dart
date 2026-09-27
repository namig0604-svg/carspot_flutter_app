/// Типы сходок — значения должны совпадать с тем, что шлёт/принимает бэкенд
/// (event_type). labelKey — ключ локализации для отображения (см.
/// lib/l10n/app_translations.dart), сами value на бэкенд не влияют.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EventCategoryOption {
  final String value;
  final String labelKey;
  final IconData icon;
  final Color color;
  const EventCategoryOption(this.value, this.labelKey, this.icon, this.color);
}

const List<EventCategoryOption> eventCategories = [
  EventCategoryOption('all', 'event_category.all', Icons.apps, AppColors.blue),
  EventCategoryOption('meetup', 'event_category.meetup', Icons.groups, AppColors.blue),
  EventCategoryOption('racing', 'event_category.racing', Icons.speed, AppColors.red),
  EventCategoryOption('drift', 'event_category.drift', Icons.blur_on, AppColors.red),
  EventCategoryOption('drag', 'event_category.drag', Icons.bolt, AppColors.red),
  EventCategoryOption('offroad', 'event_category.offroad', Icons.terrain, AppColors.blue),
  EventCategoryOption('show', 'event_category.show', Icons.star, Colors.amber),
  EventCategoryOption('cruise', 'event_category.cruise', Icons.route, AppColors.blue),
  EventCategoryOption('track_day', 'event_category.track_day', Icons.flag, AppColors.red),
  EventCategoryOption('charity', 'event_category.charity', Icons.favorite, Colors.pinkAccent),
];

EventCategoryOption eventCategoryByValue(String? value) {
  return eventCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => eventCategories.first,
  );
}

IconData eventCategoryIcon(String? value) => eventCategoryByValue(value).icon;

Color eventCategoryColor(String? value) => eventCategoryByValue(value).color;
