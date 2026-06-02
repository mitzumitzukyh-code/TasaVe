import 'package:flutter/material.dart';

/// Constantes fiscales y de negocio centralizadas.
/// Toda la lógica matemática debe consumir estas variables,
/// NUNCA números mágicos directamente en widgets.
class AppConstants {
  AppConstants._();

  /// IVA vigente en Venezuela (16%)
  static const double IVA = 0.16;

  /// IGTF — Impuesto a Grandes Transacciones Financieras (3%)
  static const double IGTF = 0.03;

  /// Nombre público de la app
  static const String appName = 'TasaVe';

  /// URL de producción web
  static const String productionUrl = 'https://tasave-app.pages.dev/';

  // ── UI ──────────────────────────────────────────────────
  static const double kBorderRadius = 10.0;
  static const double kBorderRadiusLg = 12.0;
  static const double kPaddingH = 18.0;
  static const double kPaddingV = 14.0;

  // ── Horario BCV ─────────────────────────────────────────
  static const String kBcvSchedule = '4:00 – 6:00 PM';

  // ── Color oscuro para display calculadora ───────────────
  static const Color kDark = Color(0xFF1A1A1A);

  // ── Preferencias SharedPreferences keys ─────────────────
  static const String kPrefDefaultRate = 'pref_default_rate';
  static const String kPrefDecimalFormat = 'pref_decimal_format';
  static const String kPrefAccessibility = 'pref_accessibility';
  static const String kPrefAlerts = 'pref_alerts_json';

  /// Lista maestra de bancos venezolanos con código interbancario de 4 dígitos
  static const List<VenezuelanBank> venezuelanBanks = [
    VenezuelanBank(code: '0102', name: 'Banco de Venezuela'),
    VenezuelanBank(code: '0134', name: 'Banesco'),
    VenezuelanBank(code: '0105', name: 'Mercantil'),
    VenezuelanBank(code: '0108', name: 'BBVA Provincial'),
    VenezuelanBank(code: '0172', name: 'Bancamiga'),
    VenezuelanBank(code: '0191', name: 'BNC Nacional de Crédito'),
    VenezuelanBank(code: '0174', name: 'Banplus'),
    VenezuelanBank(code: '0163', name: 'Banco del Tesoro'),
    VenezuelanBank(code: '0175', name: 'Banco Bicentenario'),
    VenezuelanBank(code: '0114', name: 'Bancaribe'),
    VenezuelanBank(code: '0115', name: 'Banco Exterior'),
    VenezuelanBank(code: '0151', name: 'Fondo Común (BFC)'),
    VenezuelanBank(code: '0177', name: 'Banfanb'),
    VenezuelanBank(code: '0156', name: '100% Banco'),
    VenezuelanBank(code: '0171', name: 'Banco Activo'),
    VenezuelanBank(code: '0104', name: 'Venezolano de Crédito'),
    VenezuelanBank(code: '0116', name: 'Occidental de Descuento'),
    VenezuelanBank(code: '0128', name: 'Caroní'),
    VenezuelanBank(code: '0137', name: 'Sofitasa'),
    VenezuelanBank(code: '0138', name: 'Mibanco'),
    VenezuelanBank(code: '0149', name: 'BNC'),
    VenezuelanBank(code: '0168', name: 'Bancrecer'),
    VenezuelanBank(code: '0176', name: 'Novo Banco'),
  ];
}

/// Modelo de banco venezolano con código interbancario
class VenezuelanBank {
  final String code;
  final String name;
  const VenezuelanBank({required this.code, required this.name});
}
