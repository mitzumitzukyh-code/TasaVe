import 'package:flutter/material.dart';

/// Tokens de color del sistema TasaVe.
/// Rojo + Blanco + Negro — minimalista, sin desviaciones.
abstract class AppColors {
  AppColors._();

  // ── Primario ───────────────────────────────────────────
  static const Color primary = Color(0xFFE53935); // Rojo TasaVe
  static const Color primaryDrk = Color(0xFFC62828); // Rojo oscuro (pressed)
  static const Color primaryLgt = Color(0xFFFFF0F0); // Fondo rojo suave

  // ── Fondos ─────────────────────────────────────────────
  static const Color bg = Color(0xFFFFFFFF); // Blanco
  static const Color surface = Color(0xFFF5F5F5); // Gris claro
  static const Color surface2 = Color(0xFFEEEEEE); // Gris más claro

  // ── Texto ──────────────────────────────────────────────
  static const Color text = Color(0xFF1A1A1A); // Casi negro
  static const Color text2 = Color(0xFF757575); // Gris medio
  static const Color text3 = Color(0xFF9E9E9E); // Gris claro

  // ── Bordes ─────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color border2 = Color(0xFFEEEEEE);

  // ── Semánticos ─────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32); // Verde (subidas)
  static const Color error = Color(0xFFC62828); // Rojo (bajadas)
  static const Color warning = Color(0xFFF57C00); // Ámbar
}
