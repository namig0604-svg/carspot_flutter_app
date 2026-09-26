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
  'frame_emerald': Color(0xFF10B981),
  'frame_sapphire': Color(0xFF2563EB),
  'frame_ruby': Color(0xFFDC2626),
  'frame_carbon': Color(0xFF3F3F46),
  'frame_chrome': Color(0xFFE5E7EB),
  'frame_diamond': Color(0xFFB9F2FF),
  // Эксклюзив CarSpot Premium (не покупается за монеты — см.
  // app/api/coins.py::COSMETICS_CATALOG, premium_tier_required).
  'frame_pro_exclusive': Color(0xFF90A4AE),
  'frame_max_exclusive': Color(0xFF7C4DFF),
};

const Map<String, IconData> kCosmeticBadgeIcons = {
  'badge_wrench': Icons.build,
  'badge_flame': Icons.local_fire_department,
  'badge_star': Icons.star,
  'badge_crown': Icons.military_tech,
  'badge_bolt': Icons.bolt,
  'badge_heart': Icons.favorite,
  'badge_trophy': Icons.emoji_events,
  'badge_target': Icons.gps_fixed,
  'badge_rocket': Icons.rocket_launch,
  'badge_diamond': Icons.diamond,
  // Эксклюзив CarSpot Premium.
  'badge_pro_exclusive': Icons.shield,
  'badge_max_exclusive': Icons.workspace_premium,
};

const Map<String, Color> kCosmeticNameColors = {
  'color_red': Color(0xFFE8262F),
  'color_blue': Color(0xFF3B82F6),
  'color_purple': Color(0xFF9B59B6),
  'color_gold': Color(0xFFFFB020),
  'color_green': Color(0xFF22C55E),
  'color_cyan': Color(0xFF06B6D4),
  'color_pink': Color(0xFFEC4899),
  'color_orange': Color(0xFFF97316),
  'color_teal': Color(0xFF14B8A6),
  'color_lime': Color(0xFFA3E635),
  // Эксклюзив CarSpot Premium.
  'color_max_exclusive': Color(0xFFFF3D9A),
};

Color? frameColorFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticFrameColors[cosmeticId];

IconData? badgeIconFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticBadgeIcons[cosmeticId];

Color? nameColorFor(String? cosmeticId) => cosmeticId == null ? null : kCosmeticNameColors[cosmeticId];
