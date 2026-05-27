import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Formatea centavos enteros en display con formato venezolano.
/// Ej: 52687 → "526,87"   12345678 → "123.456,78"
String _centsToDisplay(int cents) {
  final value = cents / 100.0;
  final formatter = NumberFormat('#,##0.00', 'es_VE');
  return formatter.format(value);
}

class CalculatorState {
  /// Almacena el valor como centavos enteros para evitar aritmética flotante.
  final int centavos;
  final bool isUsd;

  const CalculatorState({
    this.centavos = 0,
    this.isUsd = true,
  });

  double get monto => centavos / 100.0;

  /// Display con punto decimal fijo y formato venezolano: "0,05", "1,00", "526,87"
  String get montoDisplay => _centsToDisplay(centavos);

  double subtotal(double rate) {
    if (monto <= 0 || rate <= 0) return 0;
    return isUsd ? monto * rate : monto / rate;
  }

  CalculatorState copyWith({int? centavos, bool? isUsd}) {
    return CalculatorState(
      centavos: centavos ?? this.centavos,
      isUsd: isUsd ?? this.isUsd,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  static const int _maxCents = 999999999; // 9.999.999,99 máximo

  void onKey(String key) {
    final current = state.centavos;
    int next;
    if (key == 'C') {
      next = 0;
    } else if (key == '⌫') {
      next = current ~/ 10;
    } else if (key == ',' || key == '.') {
      return; // punto decimal fijo — ignorar
    } else if (key == '00') {
      next = current * 100;
      if (next > _maxCents) return;
    } else {
      final digit = int.tryParse(key);
      if (digit == null) return;
      next = current * 10 + digit;
      if (next > _maxCents) return; // no superar el máximo
    }
    state = state.copyWith(centavos: next);
  }

  /// Establece el monto directamente (usado por el escáner OCR de facturas).
  /// Acepta string con punto o coma como decimal.
  void setInput(String value) {
    final clean = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(clean);
    if (parsed != null) {
      state = state.copyWith(centavos: (parsed * 100).round());
    }
  }

  /// Establece centavos directamente (usado por el swap del home).
  void setCentavos(int cents) {
    state = state.copyWith(centavos: cents.clamp(0, _maxCents));
  }

  void toggleDirection() {
    state = state.copyWith(isUsd: !state.isUsd);
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>(
  (_) => CalculatorNotifier(),
);
