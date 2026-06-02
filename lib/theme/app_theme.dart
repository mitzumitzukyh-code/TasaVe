import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Temas TasaVe — Light + Dark.
/// Paleta unificada del plan: rojo #CC1C1C (light) / #FF3A3A (dark).
abstract class AppTheme {
  AppTheme._();

  // ── Light ────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.redLight,
          surface: AppColors.bgLight,
        ),
        cardColor: AppColors.surfaceLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.redLight,
          foregroundColor: Colors.white,
        ),
      );

  // ── Dark ─────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.redDark,
          surface: AppColors.bgDark,
        ),
        cardColor: AppColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.redDark,
          foregroundColor: Colors.white,
        ),
      );
}
