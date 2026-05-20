import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tasa_model.dart';
import 'tasa_provider.dart';

/// Family provider: fetches history for given number of days
final historyProvider = FutureProvider.family<List<TasaHistoryEntry>, int>((ref, days) async {
  final service = ref.read(bcvServiceProvider);
  final cache = ref.read(localStorageProvider);

  try {
    final history = await service.fetchHistory(days: days);
    await cache.cacheHistory(history);
    return history;
  } catch (_) {
    final cached = cache.getCachedHistory();
    if (cached != null) return cached;
    rethrow;
  }
});
