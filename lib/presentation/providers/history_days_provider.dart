import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Período de días para el historial (7, 30, 90, 365)
final historyDaysProvider = StateProvider<int>((ref) => 7);
