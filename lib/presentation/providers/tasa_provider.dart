import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/bcv_service.dart';
import '../../data/cache/local_storage.dart';
import '../../data/models/tasa_model.dart';
import '../../core/connectivity.dart';
import '../../services/widget_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe ser sobreescrito antes de usarse. '
    'Hazlo en main() así:\n'
    '  final prefs = await SharedPreferences.getInstance();\n'
    '  ProviderScope(\n'
    '    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],\n'
    '    child: TasaVeApp(),\n'
    '  )',
  );
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

    // Precarga historial para sparkline y modo offline.
    _prefetchHistory();

    await refresh();
  }

  Future<void> _prefetchHistory() async {
    try {
      final service = _ref.read(bcvServiceProvider);
      final history = await service.fetchHistory(days: 7);
      await _ref.read(localStorageProvider).cacheHistory(history);
    } catch (_) {
      // Fallback silencioso: sparkline usará caché existente.
    }
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
      final isPremium = _ref.read(localStorageProvider).isPremium;
      await WidgetService.updateFromTasa(tasa, isPremium: isPremium);
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
