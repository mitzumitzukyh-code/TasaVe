import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Fondos (V3.1 FINAL) ──
  static const Color bg = Color(0xFF07070A);
  static const Color s1 = Color(0xFF0D0D11);
  static const Color s2 = Color(0xFF141418);
  static const Color s3 = Color(0xFF1B1B20);
  static const Color s4 = Color(0xFF222228);
  static const Color surface = s3;

  // ── Bordes ──
  static const Color border = Color(0xFF28282F);
  static const Color border2 = Color(0xFF36363F);

  // ── Texto ──
  static const Color text = Color(0xFFEEEEF5);
  static const Color text2 = Color(0xFF8888A0);
  static const Color text3 = Color(0xFF444455);
  static const Color text4 = Color(0xFF22222A);

  // ── Green (Verde venezolano del ícono) ──
  static const Color green = Color(0xFF00A86B);
  static const Color green2 = Color(0xFF007A4D);
  static const Color greenDim = Color(0x1A00A86B);   // rgba(0,168,107,.1)
  static const Color greenDim2 = Color(0x2E00A86B);  // rgba(0,168,107,.18)

  // ── Gold (Dorado de la bandera venezolana) ──
  static const Color amber = Color(0xFFCF9B2E);
  static const Color amberDim = Color(0x1ACF9B2E);   // rgba(207,155,46,.1)
  static const Color amberDim2 = Color(0x33CF9B2E);  // rgba(207,155,46,.2)

  // ── Red (Rojo venezolano) ──
  static const Color red = Color(0xFFCF142B);
  static const Color redDim = Color(0x1ACF142B);

  // ── Blue ──
  static const Color blue = Color(0xFF40C4FF);
  static const Color blueDim = Color(0x1A40C4FF);

  // ── Purple ──
  static const Color purple = Color(0xFFCE93D8);
  static const Color purpleDim = Color(0x1ACE93D8);

  // ── Legado (compatibilidad) ──
  static const Color bg2 = s1;
  static const Color bg3 = s2;
  static const Color bg4 = s3;
  static const Color primary = green;
  static const Color secondary = Color(0xFFCF142B);
  static const Color accent = amber;
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color bgDark = bg;
  static const Color textMain = text;
  static const Color textMuted = text2;
  static const Color success = green;
  static const Color danger = red;
  static const Color cardBg = s2;
  static const Color whatsappGreen = Color(0xFF12C55D);

  // ── Radios ──
  static const double r1 = 10.0;
  static const double r2 = 16.0;
  static const double r3 = 22.0;
  static const double r4 = 28.0;
  static const double radius = r3;
  static const double radiusSm = r1;
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
  static const String INTERSTITIAL = 'ca-app-pub-8194792499117380/9143704910';
}
