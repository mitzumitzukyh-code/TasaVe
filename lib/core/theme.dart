import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0C0E),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.red,
          tertiary: AppColors.yellow,
          surface: Color(0xFF16161A),
          onPrimary: Color(0xFFFFFFFF),
          onSurface: Color(0xFFE8E8EC),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFFE8E8EC),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE8E8EC),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF16161A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.r3),
            side: const BorderSide(color: Color(0xFF2A2A2E)),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.dmSans(fontSize: 48, fontWeight: FontWeight.w700, color: const Color(0xFFE8E8EC)),
          displayMedium: GoogleFonts.dmSans(fontSize: 30, fontWeight: FontWeight.w700, color: const Color(0xFFE8E8EC)),
          titleLarge: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFFE8E8EC)),
          titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE8E8EC)),
          bodyLarge: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFE8E8EC)),
          bodyMedium: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF9CA3AF)),
          bodySmall: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280)),
          labelLarge: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w500, color: const Color(0xFFE8E8EC)),
          labelMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFE8E8EC)),
          labelSmall: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF16161A),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 7, letterSpacing: 0.5),
          unselectedLabelStyle: TextStyle(fontSize: 7, letterSpacing: 0.5),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 4,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.green,
          secondary: AppColors.red,
          tertiary: AppColors.yellow,
          surface: AppColors.surface,
          onPrimary: Color(0xFFFFFFFF),
          onSurface: AppColors.text,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.r3),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.dmSans(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          displayMedium: GoogleFonts.dmSans(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          titleLarge: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          titleMedium: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          bodyLarge: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.text,
          ),
          bodyMedium: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.text2,
          ),
          bodySmall: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.text3,
          ),
          labelLarge: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          labelMedium: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          labelSmall: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.text2,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.text3,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 7, letterSpacing: 0.5),
          unselectedLabelStyle: TextStyle(fontSize: 7, letterSpacing: 0.5),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.green,
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 4,
        ),
      );
}
