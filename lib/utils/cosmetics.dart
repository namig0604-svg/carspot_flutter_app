import 'package:flutter/material.dart';

/// Косметика профиля (рамки аватара, значки, цвет имени), которая
/// покупается за CarSpot Coins — id здесь должны совпадать с каталогом на
/// бэкенде (app/api/coins.py: COSMETICS_CATALOG). Название и цену отдаёт
/// сервер, а как именно предмет выглядит (цвет/иконка) знает только
/// фронтенд — рисуется чистым Flutter, без картинок-ассетов.
const Map<String, Color> kCosmeticFrameColors = {
  'frame_bronze': Color(0xFFCD7F32),
  'frame_silver': Color(0xFFC0C0C0),
  'frame_gold': Color(0xFFFFD700),
  'frame_neon': Color(0xFF39FF14),
};

const Map<String, IconData> kCosmeticBadgeIcons = {
  'badge_wrench': Icons.build,
  'badge_flame': Icons.local_fire_department,
  'badge_star': Icons.star,
  'badge_crown': Icons.military_tech,
};

const Map<String, Color> kCosmeticNameColors = {
  'color_red': Color(0xFFE8262F),
  'color_blue': Color(0xFF3B82F6),
  'color_purple': Color(0xFF9B59B6),
  'color_gold': Color(0xFFFFB020),
};

Color? frameColorFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticFrameColors[cosmeticId];

IconData? badgeIconFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticBadgeIcons[cosmeticId];

Color? nameColorFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticNameColors[cosmeticId];
