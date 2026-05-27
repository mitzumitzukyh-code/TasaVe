import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tasa_model.dart';
import 'tasa_provider.dart';

/// Family provider: obtiene el historial para N días.
/// Incluye fallback automático a caché local si no hay conexión.
final historyProvider = FutureProvider.family<List<TasaHistoryEntry>, int>((ref, days) async {
  final service = ref.read(bcvServiceProvider);
  final cache = ref.read(localStorageProvider);

  try {
    final history = await service.fetchHistory(days: days);
    await cache.cacheHistory(history);
    return history;
  } catch (_) {
    final cached = cache.getCachedHistory();
    if (cached != null) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final filtered = cached.where((e) => !e.date.isBefore(cutoff)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    }
    rethrow;
  }
});

/// Variación diaria de la tasa BCV.
/// Reutiliza historyProvider(7) para aprovechar el fallback a caché local
/// cuando el dispositivo está sin conexión — evita devolver 0.0 offline.
final variationProvider = FutureProvider<double>((ref) async {
  try {
    final history = await ref.watch(historyProvider(7).future);
    if (history.isNotEmpty) {
      return history[0].variation;
    }
    return 0.0;
  } catch (_) {
    return 0.0;
  }
});

