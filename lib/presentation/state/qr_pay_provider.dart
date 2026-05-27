import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../providers/tasa_provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Normaliza el teléfono ingresado por el usuario a los 9 dígitos locales
/// (sin el 0 inicial). Acepta:
///   04121234567  → 4121234567
///   4121234567   → 4121234567
///   584121234567 → 4121234567
String _normalizePhone(String raw) {
  final digits = raw.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('58') && digits.length >= 12) {
    return digits.substring(2); // quitar código de país
  }
  if (digits.startsWith('0') && digits.length >= 10) {
    return digits.substring(1); // quitar 0 inicial
  }
  return digits;
}

/// Devuelve el número en formato local 04XX... para mostrar al usuario
String _toDisplayPhone(String normalized) =>
    normalized.isNotEmpty ? '0$normalized' : '';

// ── Estado ───────────────────────────────────────────────────────────────────
class QrPayState {
  /// Código de 4 dígitos del banco (ej. '0134')
  final String bancoCodigo;
  /// Solo dígitos, sin prefijo V-/E-
  final String cedula;
  /// 'V' | 'E' | 'J'
  final String prefijoCedula;
  /// 9 dígitos locales normalizados (sin 0 inicial, sin +58)
  final String telefono;
  final bool isLoaded;

  const QrPayState({
    this.bancoCodigo = '0134',
    this.cedula = '',
    this.prefijoCedula = 'V',
    this.telefono = '',
    this.isLoaded = false,
  });

  /// El teléfono es válido si tiene entre 9 y 10 dígitos normalizados
  bool get isComplete =>
      bancoCodigo.isNotEmpty &&
      cedula.isNotEmpty &&
      telefono.length >= 9 &&
      telefono.length <= 10;

  /// Cadena CSV plana compatible con lectores bancarios venezolanos (BDV, Banesco, etc.)
  /// Formato: CODIGO_BANCO,CEDULA_SOLO_DIGITOS,TELEFONO_LOCAL
  /// Para evitar que algunos bancos (como Banesco o Mercantil) den error al intentar
  /// parsear la letra 'V' o prefijos, enviamos la cédula como puros dígitos en el código QR.
  String get qrPayload =>
      '$bancoCodigo,$cedula,${_toDisplayPhone(telefono)}';

  /// Texto legible para compartir por WhatsApp
  String get textoCompartir {
    final banco = AppConstants.venezuelanBanks
        .firstWhere((b) => b.code == bancoCodigo,
            orElse: () => const VenezuelanBank(code: '', name: 'Banco'))
        .name;
    return '📲 *Mi Pago Móvil*\n'
        '🏦 Banco: $banco ($bancoCodigo)\n'
        '🪪 Cédula: $prefijoCedula-$cedula\n'
        '📞 Teléfono: ${_toDisplayPhone(telefono)}\n'
        '\n— Enviado desde *TasaVe* 🇻🇪';
  }

  /// Número para mostrar en el formulario (con 0 inicial)
  String get telefonoDisplay => _toDisplayPhone(telefono);

  QrPayState copyWith({
    String? bancoCodigo,
    String? cedula,
    String? prefijoCedula,
    String? telefono,
    bool? isLoaded,
  }) =>
      QrPayState(
        bancoCodigo: bancoCodigo ?? this.bancoCodigo,
        cedula: cedula ?? this.cedula,
        prefijoCedula: prefijoCedula ?? this.prefijoCedula,
        telefono: telefono ?? this.telefono,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class QrPayNotifier extends StateNotifier<QrPayState> {
  static const _key = 'qr_pay_data';
  final SharedPreferences _prefs;

  QrPayNotifier(this._prefs) : super(const QrPayState()) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      state = state.copyWith(isLoaded: true);
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = QrPayState(
        bancoCodigo: m['bancoCodigo'] as String? ?? '0134',
        cedula: m['cedula'] as String? ?? '',
        prefijoCedula: m['prefijoCedula'] as String? ?? 'V',
        telefono: m['telefono'] as String? ?? '',
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  /// Guarda los datos. El teléfono se normaliza aquí antes de persistir.
  Future<void> save({
    required String bancoCodigo,
    required String cedula,
    required String prefijoCedula,
    required String rawTelefono,
  }) async {
    final normalized = _normalizePhone(rawTelefono);
    final data = {
      'bancoCodigo': bancoCodigo,
      'cedula': cedula,
      'prefijoCedula': prefijoCedula,
      'telefono': normalized,
    };
    await _prefs.setString(_key, jsonEncode(data));
    state = QrPayState(
      bancoCodigo: bancoCodigo,
      cedula: cedula,
      prefijoCedula: prefijoCedula,
      telefono: normalized,
      isLoaded: true,
    );
  }

  void clear() {
    _prefs.remove(_key);
    state = const QrPayState(isLoaded: true);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final qrPayProvider =
    StateNotifierProvider<QrPayNotifier, QrPayState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QrPayNotifier(prefs);
});
