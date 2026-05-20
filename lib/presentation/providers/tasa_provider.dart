import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/bcv_service.dart';
import '../../data/cache/local_storage.dart';
import '../../data/models/tasa_model.dart';
import '../../core/connectivity.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

final bcvServiceProvider = Provider<BcvService>((ref) {
  return BcvService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final tasaProvider = StateNotifierProvider<TasaNotifier, AsyncValue<TasaModel>>((ref) {
  return TasaNotifier(ref);
});

class TasaNotifier extends StateNotifier<AsyncValue<TasaModel>> {
  final Ref _ref;

  TasaNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final cache = _ref.read(localStorageProvider);
    final cached = cache.getCachedTasa();

    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    await refresh();
  }

  Future<void> refresh() async {
    final connectivity = _ref.read(connectivityServiceProvider);
    final isOnline = await connectivity.isConnected;

    if (!isOnline) {
      final cache = _ref.read(localStorageProvider);
      final cached = cache.getCachedTasa();
      if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error('Sin conexión', StackTrace.current);
      }
      return;
    }

    try {
      final service = _ref.read(bcvServiceProvider);
      final tasa = await service.fetchCurrentRate();
      final cache = _ref.read(localStorageProvider);
      await cache.cacheTasa(tasa);
      state = AsyncValue.data(tasa);
    } catch (e) {
      final cache = _ref.read(localStorageProvider);
      final cached = cache.getCachedTasa();
      if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

final variationProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(bcvServiceProvider);
  try {
    final history = await service.fetchHistory(days: 7);
    if (history.isNotEmpty) {
      // Use the API's own variation field from the most recent entry
      return history[0].variation;
    }
    return 0.0;
  } catch (_) {
    return 0.0;
  }
});
