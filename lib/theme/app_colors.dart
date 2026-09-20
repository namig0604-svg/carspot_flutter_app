import 'package:flutter/material.dart';

/// Единая палитра CarSpot — стиль автоклубов 2000-х (NFS Underground),
/// но современный: карбон-чёрный + неоновый синий + гоночный красный + белый.
/// Используется вместо разрозненных Colors.blue/Colors.red по всему приложению,
/// чтобы визуальный стиль был последовательным и легко менялся в одном месте.
class AppColors {
  AppColors._();

  // --- Акценты бренда ---
  static const Color blue = Color(0xFF2F6FFF);      // неоновый синий — навигация, действия
  static const Color blueDark = Color(0xFF13398F);  // тёмно-синий — градиенты, акценты в light-теме
  static const Color red = Color(0xFFE8262F);        // гоночный красный — CTA, лайки, буст
  static const Color redDark = Color(0xFF9A0F17);    // тёмно-красный — градиенты

  // --- Карбон / тёмная тема ---
  static const Color black = Color(0xFF0A0C10);      // почти чёрный фон (карбон)
  static const Color surfaceDark = Color(0xFF16181D); // карточки/поверхности на тёмном
  static const Color surfaceDarkAlt = Color(0xFF1E2127);
  static const Color steel = Color(0xFF2A2E36);       // границы/разделители на тёмном

  // --- Светлая тема ---
  static const Color white = Color(0xFFF5F6F8);       // фон светлой темы (не чисто белый)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color steelLight = Color(0xFFE1E4E9);  // границы на светлом

  // --- Текст ---
  static const Color textOnDark = Color(0xFFF4F5F7);
  static const Color textOnLight = Color(0xFF0A0C10);
}
