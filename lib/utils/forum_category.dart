/// Kategorii temy foruma - fiksirovanny nabor, dolzhen sovpadat so
/// znacheniyami FORUM_CATEGORIES na backende (app/models/forum.py).
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

class ForumCategoryOption {
  final String value;
  final IconData icon;
  final Color color;
  const ForumCategoryOption(this.value, this.icon, this.color);
}

const List<ForumCategoryOption> forumCategories = [
  ForumCategoryOption('events', Icons.calendar_month, AppColors.blue),
  ForumCategoryOption('tuning', Icons.build, AppColors.red),
  ForumCategoryOption('questions', Icons.help_outline, Colors.amber),
  ForumCategoryOption('market', Icons.storefront, Colors.green),
];

ForumCategoryOption forumCategoryByValue(String? value) {
  return forumCategories.firstWhere(
    (c) => c.value == value,
    orElse: () => forumCategories.first,
  );
}

String forumCategoryLabel(BuildContext context, String? value) => context.t('forum.category_${forumCategoryByValue(value).value}_title');

String forumCategoryDescription(BuildContext context, String? value) => context.t('forum.category_${forumCategoryByValue(value).value}_desc');
