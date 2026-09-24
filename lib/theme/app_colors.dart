import 'package:flutter/material.dart';

/// Единая палитра CarSpot — редизайн в стиле референса CCS: почти чёрный фон,
/// тёмно-синие (не серые) карточки, один яркий синий акцент везде, янтарный
/// цвет для срочных/анонсных блоков ("Скоро"). Используется вместо разрозненных
/// Colors.blue/Colors.red по всему приложению, чтобы стиль был последовательным
/// и легко менялся в одном месте.
class AppColors {
  AppColors._();

  // --- Акценты бренда ---
  static const Color blue = Color(0xFF3B82F6);       // основной синий акцент — кнопки, ссылки, активные табы
  static const Color blueBright = Color(0xFF5B9CFF);  // светлее синий — для градиентов на активных пилюлях
  static const Color blueDark = Color(0xFF1B4FCC);    // тёмно-синий — градиенты, акценты в light-теме
  static const Color red = Color(0xFFE8262F);         // гоночный красный — CTA, лайки, буст
  static const Color redDark = Color(0xFF9A0F17);     // тёмно-красный — градиенты
  static const Color amber = Color(0xFFFFB020);       // янтарный — блок "Скоро", анонсы, избранное
  static const Color amberDark = Color(0xFF7A4B0A);   // тёмный янтарный — фон анонс-карточки

  // --- Карбон / тёмная тема ---
  static const Color black = Color(0xFF050608);       // почти чистый чёрный фон, как в CCS
  static const Color surfaceDark = Color(0xFF10141F);  // карточки на тёмном — тёмно-синий, не серый
  static const Color surfaceDarkAlt = Color(0xFF161B29); // поисковые поля, пилюли, второй слой поверх фона
  static const Color surfaceDarkRaised = Color(0xFF1B2233); // приподнятые элементы (активные пилюли, модалки)
  static const Color steel = Color(0x1FFFFFFF);        // тонкая полупрозрачная граница на тёмном (белый 12%)
  static const Color steelStrong = Color(0x33FFFFFF);  // граница чуть заметнее (белый 20%)

  // --- Светлая тема ---
  static const Color white = Color(0xFFF5F6F8);        // фон светлой темы (не чисто белый)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color steelLight = Color(0xFFE1E4E9);   // границы на светлом

  // --- Текст ---
  static const Color textOnDark = Color(0xFFF4F5F7);
  static const Color textMutedDark = Color(0xFF8A93A6); // серый подзаголовок на тёмном, как в CCS
  static const Color textOnLight = Color(0xFF0A0C10);
  static const Color textMutedLight = Color(0xFF6B7280);
}
