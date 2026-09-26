import 'package:flutter/material.dart';

/// Статусный цвет ника по тарифу CarSpot Premium — общая логика, чтобы не
/// дублировать одни и те же цвета в списке участников сходки, чатах и
/// каталоге (см. premium.compare_status_name / premium.perk_status_name_*
/// в переводах и app/premium_tiers.py::status_name_color_hex на бэкенде).
///
/// tier — это user['premium_tier'] с бэкенда: "basic" | "pro" | "max" | null.
/// null (или любое другое значение) — обычный пользователь, возвращаем null,
/// вызывающий код в этом случае просто не переопределяет цвет текста.
Color? premiumNameColor(String? tier) {
  switch (tier) {
    case 'max':
      return const Color(0xFF8E24AA); // фиолетовый — топ-уровень
    case 'pro':
      return const Color(0xFFF9A825); // золотой
    case 'basic':
      return const Color(0xFF42A5F5); // голубой
    default:
      return null;
  }
}
