import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico TasaVe.
/// DM Sans (sans-serif) para todo el texto.
/// Space Mono para tasas, números y valores monetarios.
abstract class AppTypography {
  AppTypography._();

  // ── DM Sans — Títulos ──────────────────────────────────
  static final TextStyle displayLarge = GoogleFonts.dmSans(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );
  static final TextStyle displayMedium = GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
  static final TextStyle titleLarge = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static final TextStyle titleMedium = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static final TextStyle titleSmall = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── DM Sans — Cuerpo ──────────────────────────────────
  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static final TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static final TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── DM Sans — Etiquetas ───────────────────────────────
  static final TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static final TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ── Space Mono — Números / Tasas ───────────────────────
  static final TextStyle rateHero = GoogleFonts.spaceMono(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );
  static final TextStyle rateLarge = GoogleFonts.spaceMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static final TextStyle rateMedium = GoogleFonts.spaceMono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static final TextStyle rateSmall = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
