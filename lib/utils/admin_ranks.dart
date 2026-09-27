import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

/// Иерархия рангов администрации CarSpot — зеркалит app/ranks.py на бэкенде.
/// Порядок по возрастанию прав: модератор < администратор < тех.администратор < разработчик.
const List<String> kAdminRanks = ['moderator', 'administrator', 'tech_admin', 'developer'];

const Map<String, String> kAdminRankTitleKeys = {
  'moderator': 'admin_rank.moderator',
  'administrator': 'admin_rank.administrator',
  'tech_admin': 'admin_rank.tech_admin',
  'developer': 'admin_rank.developer',
};

const Map<String, int> kAdminRankLevel = {
  'moderator': 1,
  'administrator': 2,
  'tech_admin': 3,
  'developer': 4,
};

int adminRankLevel(String? rank) => rank == null ? 0 : (kAdminRankLevel[rank] ?? 0);

String adminRankTitle(BuildContext context, String? rank) {
  if (rank == null) return context.t('admin_rank.none');
  final key = kAdminRankTitleKeys[rank];
  return key != null ? context.t(key) : rank;
}

const int kTechAdminLevel = 3;
const int kDeveloperLevel = 4;
