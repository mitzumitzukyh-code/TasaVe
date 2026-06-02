import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del teclado de la calculadora — centavos como string
final calculatorRawCentsProvider = StateProvider<String>((ref) => '000');

/// Monto derivado en double
final calculatorAmountProvider = Provider<double>((ref) {
  final raw = ref.watch(calculatorRawCentsProvider);
  return int.parse(raw) / 100.0;
});

/// Filtro de impuesto
enum TaxMode { none, iva, igtf }

final taxModeProvider = StateProvider<TaxMode>((ref) => TaxMode.none);
