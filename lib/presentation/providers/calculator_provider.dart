import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasa_provider.dart';

enum ConversionDirection { bsToUsd, usdToBs }

class CalculatorState {
  final String input;
  final ConversionDirection direction;
  final List<CalculatorHistoryEntry> recentOps;

  const CalculatorState({
    this.input = '',
    this.direction = ConversionDirection.bsToUsd,
    this.recentOps = const [],
  });

  CalculatorState copyWith({
    String? input,
    ConversionDirection? direction,
    List<CalculatorHistoryEntry>? recentOps,
  }) {
    return CalculatorState(
      input: input ?? this.input,
      direction: direction ?? this.direction,
      recentOps: recentOps ?? this.recentOps,
    );
  }

  double get inputValue => double.tryParse(input.replaceAll(',', '.')) ?? 0.0;
}

class CalculatorHistoryEntry {
  final double input;
  final double result;
  final ConversionDirection direction;
  final DateTime timestamp;

  const CalculatorHistoryEntry({
    required this.input,
    required this.result,
    required this.direction,
    required this.timestamp,
  });
}

final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  void appendDigit(String digit) {
    if (digit == '.' && state.input.contains('.')) return;
    if (state.input.length >= 15) return;
    state = state.copyWith(input: state.input + digit);
  }

  void deleteLast() {
    if (state.input.isEmpty) return;
    state = state.copyWith(
      input: state.input.substring(0, state.input.length - 1),
    );
  }

  void clear() {
    state = state.copyWith(input: '');
  }

  void toggleDirection() {
    state = state.copyWith(
      direction: state.direction == ConversionDirection.bsToUsd
          ? ConversionDirection.usdToBs
          : ConversionDirection.bsToUsd,
    );
  }

  void setDirection(ConversionDirection direction) {
    state = state.copyWith(direction: direction);
  }

  void saveOperation(double result) {
    final entry = CalculatorHistoryEntry(
      input: state.inputValue,
      result: result,
      direction: state.direction,
      timestamp: DateTime.now(),
    );
    final ops = [entry, ...state.recentOps.take(4)];
    state = state.copyWith(recentOps: ops);
  }
}

final conversionResultProvider = Provider<double>((ref) {
  final calcState = ref.watch(calculatorProvider);
  final tasaAsync = ref.watch(tasaProvider);

  return tasaAsync.when(
    data: (tasa) {
      if (calcState.inputValue == 0) return 0.0;
      if (calcState.direction == ConversionDirection.bsToUsd) {
        return calcState.inputValue / tasa.bcvUsd;
      } else {
        return calcState.inputValue * tasa.bcvUsd;
      }
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
