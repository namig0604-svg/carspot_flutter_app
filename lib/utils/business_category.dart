/// Категории заведений — должны совпадать со значениями BUSINESS_CATEGORIES
/// на бэкенде (app/models/business.py), иначе фильтр по category не сработает.
import 'package:flutter/material.dart';

class BusinessCategoryOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const BusinessCategoryOption(this.value, this.label, this.icon, this.color);
}

const List<BusinessCategoryOption> businessCategories = [
  BusinessCategoryOption('service', 'Автосервис', Icons.car_repair, Colors.blue),
  BusinessCategoryOption('tuning', 'Тюнинг-ателье', Icons.speed, Colors.deepPurple),
  BusinessCategoryOption('detailing', 'Детейлинг', Icons.auto_awesome, Colors.cyan),
  BusinessCategoryOption('body_shop', 'Кузовной ремонт', Icons.build, Colors.brown),
  BusinessCategoryOption('tire', 'Шиномонтаж', Icons.trip_origin, Colors.grey),
  BusinessCategoryOption('car_wash', 'Автомойка', Icons.local_car_wash, Colors.lightBlue),
  BusinessCategoryOption('electric', 'Автоэлектрик', Icons.electrical_services, Colors.amber),
  BusinessCategoryOption('parts', 'Магазин запчастей', Icons.settings_suggest, Colors.green),
  BusinessCategoryOption('other', 'Другое', Icons.storefront, Colors.blueGrey),
];

BusinessCategoryOption businessCategoryByValue(String? value) {
  return businessCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => businessCategories.last,
  );
}

String businessCategoryLabel(String? value) => businessCategoryByValue(value).label;

IconData businessCategoryIcon(String? value) => businessCategoryByValue(value).icon;

Color businessCategoryColor(String? value) => businessCategoryByValue(value).color;
