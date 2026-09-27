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

  // --- Светлые аналоги "тёмных" поверхностей/границ ---
  // Нужны экранам, которые раньше были жёстко завёрнуты в Theme(data: AppTheme.dark)
  // (см. lib/theme/app_theme.dart) и использовали surfaceDark*/steel*/textOnDark
  // напрямую — теперь эти экраны следуют системной/пользовательской теме, а эти
  // константы и хелперы ниже дают им светлый эквивалент того же слоя.
  static const Color surfaceAltLight = Color(0xFFEFF1F4); // как fillColor/chipTheme в AppTheme.light
  static const Color surfaceRaisedLight = Color(0xFFE7E9ED);

  /// true, если сейчас действует тёмная тема (см. Theme.of(context).brightness).
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  /// Фон экрана — то же самое, что Theme.of(context).scaffoldBackgroundColor,
  /// но короче в местах, где раньше стоял литерал AppColors.black.
  static Color scaffoldBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  /// Была AppColors.surfaceDark — карточки/поверхности первого уровня.
  static Color surface(BuildContext context) => isDark(context) ? surfaceDark : surfaceLight;

  /// Была AppColors.surfaceDarkAlt — поля поиска, пилюли, второй слой поверх фона.
  static Color surfaceAlt(BuildContext context) => isDark(context) ? surfaceDarkAlt : surfaceAltLight;

  /// Была AppColors.surfaceDarkRaised — приподнятые элементы (активные пилюли, модалки).
  static Color surfaceRaised(BuildContext context) => isDark(context) ? surfaceDarkRaised : surfaceRaisedLight;

  /// Была AppColors.steel — тонкая граница.
  static Color border(BuildContext context) => isDark(context) ? steel : steelLight;

  /// Была AppColors.steelStrong — граница чуть заметнее.
  static Color borderStrong(BuildContext context) => isDark(context) ? steelStrong : steelLight;

  /// Была AppColors.textOnDark — основной цвет текста. Совпадает с
  /// Theme.of(context).colorScheme.onSurface, но так короче и явнее по смыслу.
  static Color onSurface(BuildContext context) => isDark(context) ? textOnDark : textOnLight;

  /// Была AppColors.textMutedDark — приглушённый подзаголовок/второстепенный текст.
  static Color textMuted(BuildContext context) => isDark(context) ? textMutedDark : textMutedLight;
}
