import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Тёмная и светлая тема CarSpot — единый стиль в духе автоклубов 2000-х
/// (NFS Underground: карбон, неоновый синий, гоночный красный), но опрятный
/// и современный: Material 3, скруглённые карточки, жирные заголовки.
class AppTheme {
  AppTheme._();

  static const _radius = 14.0;

  // Более "живой" переход между экранами вместо стандартного — один и тот же
  // билдер для всех платформ (zoom+fade), задаётся один раз для обеих тем.
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    },
  );

  static TextTheme _textTheme(Color onSurface) {
    final base = ThemeData(brightness: Brightness.dark).textTheme;
    return base.apply(bodyColor: onSurface, displayColor: onSurface).copyWith(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      labelLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      secondary: AppColors.red,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textOnDark,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      dividerColor: AppColors.steel,
      textTheme: _textTheme(AppColors.textOnDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.steel),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkAlt,
        selectedColor: AppColors.blue,
        labelStyle: const TextStyle(color: AppColors.textOnDark),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.steel),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDarkAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steel),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textOnDark,
          side: const BorderSide(color: AppColors.steel),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: Colors.grey,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.blue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDarkAlt,
        contentTextStyle: const TextStyle(color: AppColors.textOnDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.blueDark,
      onPrimary: Colors.white,
      secondary: AppColors.red,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textOnLight,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: AppColors.white,
      canvasColor: AppColors.white,
      dividerColor: AppColors.steelLight,
      textTheme: _textTheme(AppColors.textOnLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.steelLight),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF1F4),
        selectedColor: AppColors.blueDark,
        labelStyle: const TextStyle(color: AppColors.textOnLight),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.steelLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEFF1F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steelLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blueDark, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textOnLight,
          side: const BorderSide(color: AppColors.steelLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnLight),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.blueDark,
        unselectedItemColor: Colors.grey,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.blueDark,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.blueDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
