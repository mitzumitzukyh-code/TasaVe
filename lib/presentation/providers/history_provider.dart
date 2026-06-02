import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tasa_model.dart';
import 'tasa_provider.dart';

final historyProvider = FutureProvider.family<List<TasaHistoryEntry>, int>((ref, days) async {
  final service = ref.watch(bcvServiceProvider);
  final storage = ref.watch(localStorageProvider);

  try {
    final history = await service.fetchHistory(days: days);
    await storage.cacheHistory(history);
    return history;
  } catch (e) {
    final cached = storage.getCachedHistory();
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});
