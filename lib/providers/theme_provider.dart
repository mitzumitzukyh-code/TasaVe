import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/providers/tasa_provider.dart';

// ── ThemeData ──────────────────────────────────────────────

final lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  cardColor: const Color(0xFFF5F5F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE53935),
    onSurface: Color(0xFF1A1A1A),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF0C0C0C),
  cardColor: const Color(0xFF1A1A1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0C0C0C),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE53935),
    onSurface: Color(0xFFFFFFFF),
  ),
);

// ── ThemeNotifier ──────────────────────────────────────────

class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'dark_mode';

  ThemeNotifier(this._prefs)
      : super(_prefs.getBool(_key) ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
