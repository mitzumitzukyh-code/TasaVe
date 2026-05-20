import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.green,
          secondary: AppColors.amber,
          tertiary: AppColors.blue,
          surface: AppColors.s2,
          onPrimary: Color(0xFFFFFFFF),
          onSurface: AppColors.text,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.s2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.r3),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.bebasNeue(
            fontSize: 58,
            color: AppColors.text,
            letterSpacing: 1,
          ),
          displayMedium: GoogleFonts.bebasNeue(
            fontSize: 30,
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
          labelLarge: GoogleFonts.spaceMono(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          labelMedium: GoogleFonts.spaceMono(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          labelSmall: GoogleFonts.spaceMono(
            fontSize: 11,
            color: AppColors.text2,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bg,
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

  static ThemeData get light => dark;
}
