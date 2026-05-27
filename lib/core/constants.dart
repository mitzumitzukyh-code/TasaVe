import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Estilo tipográfico para valores monetarios — DM Sans
final TextStyle kMoneyTextStyle = GoogleFonts.dmSans(
  fontSize: 26,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
);

// ─────────────────────────────────────────────────────────────────────────────
// PALETA DE COLORES TASAVE — Sistema actual (Material3)
// Migrado a temas light/dark con AppTheme.light + AppTheme.dark
//
// Primary:       #E53935  — Rojo TasaVe, igual en ambos temas
// Background:    Light #F2F2F2  / Dark #0C0C0E  (via scaffoldBackgroundColor)
// Surface:       Light #FFFFFF  / Dark #16161A  (via colorScheme.surface)
// On-surface:    Material3 auto-genera según tema
// Success/Green: #1B5E20  (light) — texto sobre fondo claro
// Warning/Amber: #FFD100  — advertencias y destacados
// Error/Red:     #E53935  — mismo que primary
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Fondos (Light UI) ──
  static const Color bg = Color(0xFFF2F2F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // ── Color Primario (TasaVe Rojo) ──
  static const Color primary = Color(0xFFE53935);

  // ── Bordes ──
  static const Color border = Color(0xFFE0E0E0);
  static const Color border2 = Color(0xFFBDBDBD);

  // ── Texto ──
  static const Color text = Color(0xFF1A1A1A);
  static const Color text2 = Color(0xFF757575);
  static const Color text3 = Color(0xFF9E9E9E);

  // ── Green (saldos/positivo) ──
  static const Color green = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFFE8F5E9);

  // ── Red (alertas/negativo) ──
  static const Color red = Color(0xFFE53935);
  static const Color redLight = Color(0xFFFFEBEE);

  // ── Yellow (advertencias/destacados) ──
  static const Color yellow = Color(0xFFFFD100);
  static const Color yellowLight = Color(0xFFFFF9C4);

  // ── WhatsApp ──
  static const Color whatsappGreen = Color(0xFF25D366);

  // ── Radios de borde ──
  static const double r1 = 10.0;
  static const double r2 = 16.0;
  static const double r3 = 22.0;
  static const double r4 = 28.0;
}

class AppStrings {
  AppStrings._();

  static const String APP_NAME = 'TasaVe';
  static const String ERROR_NO_CONNECTION = 'Sin conexión. Mostrando último dato guardado.';
  static const String ERROR_API = 'No se pudo actualizar. Intenta más tarde.';
  static const String UPDATED_AGO = 'Actualizado hace';
  static const String MINUTES = 'minutos';
  static const String BS_PER_USD = 'Bs por \$1';
  static const String BS_PER_EUR = 'Bs por €1';
  static const String BS_PER_USDT = 'Bs por USDT';
  static const String DOLAR_BCV = 'Dólar BCV';
  static const String EURO_BCV = 'Euro BCV';
  static const String USDT_P2P = 'USDT P2P';
  static const String CALCULATOR = 'Calculadora';
  static const String HISTORY = 'Historial';
  static const String SHARE_WHATSAPP = 'Compartir por WhatsApp';
  static const String SHARE_HISTORY = 'Compartir historial como imagen';
  static const String EXPORT = 'Exportar';
  static const String AD_BANNER_TEXT = 'Publicidad — Hazte Premium';
}

class ApiConfig {
  ApiConfig._();

  static const String API_BASE_URL = 'https://tasave-api.miztmutzuki.workers.dev';
  static const String BCV_ENDPOINT = '$API_BASE_URL/tasa';
  static const int REFRESH_INTERVAL_MINUTES = 30;
}

enum UserPlan { free, premium }

class AdConfig {
  AdConfig._();

  static const String APP_ID_ANDROID = 'ca-app-pub-8194792499117380~1133581866';
  static const String BANNER_HOME = 'ca-app-pub-8194792499117380/1681210925';
  static const String BANNER_HOME_2 = 'ca-app-pub-8194792499117380/6185746162';
  static const String INTERSTITIAL = 'ca-app-pub-8194792499117380/9143704910';
}
