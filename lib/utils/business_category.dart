/// Категории заведений — должны совпадать со значениями BUSINESS_CATEGORIES
/// на бэкенде (app/models/business.py), иначе фильтр по category не сработает.
/// labelKey — ключ локализации для отображения.
import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

class BusinessCategoryOption {
  final String value;
  final String labelKey;
  final IconData icon;
  final Color color;
  const BusinessCategoryOption(this.value, this.labelKey, this.icon, this.color);
}

const List<BusinessCategoryOption> businessCategories = [
  BusinessCategoryOption('service', 'business_category.service', Icons.car_repair, Colors.blue),
  BusinessCategoryOption('tuning', 'business_category.tuning', Icons.speed, Colors.deepPurple),
  BusinessCategoryOption('detailing', 'business_category.detailing', Icons.auto_awesome, Colors.cyan),
  BusinessCategoryOption('body_shop', 'business_category.body_shop', Icons.build, Colors.brown),
  BusinessCategoryOption('tire', 'business_category.tire', Icons.trip_origin, Colors.grey),
  BusinessCategoryOption('car_wash', 'business_category.car_wash', Icons.local_car_wash, Colors.lightBlue),
  BusinessCategoryOption('electric', 'business_category.electric', Icons.electrical_services, Colors.amber),
  BusinessCategoryOption('parts', 'business_category.parts', Icons.settings_suggest, Colors.green),
  BusinessCategoryOption('other', 'hazards.type_other', Icons.storefront, Colors.blueGrey),
];

BusinessCategoryOption businessCategoryByValue(String? value) {
  return businessCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => businessCategories.last,
  );
}

String businessCategoryLabel(BuildContext context, String? value) =>
    context.t(businessCategoryByValue(value).labelKey);

IconData businessCategoryIcon(String? value) => businessCategoryByValue(value).icon;

Color businessCategoryColor(String? value) => businessCategoryByValue(value).color;
