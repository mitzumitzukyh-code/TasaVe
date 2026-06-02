import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/bcv_service.dart';
import '../../data/cache/local_storage.dart';
import '../../data/models/tasa_model.dart';

// ── Providers de servicio ─────────────────────────────────

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider debe ser sobrescrito en main()');
});

final bcvServiceProvider = Provider<BcvService>((ref) {
  return BcvService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider debe ser sobrescrito en main()');
});

// ── TasaNotifier ──────────────────────────────────────────

class TasaNotifier extends StateNotifier<AsyncValue<TasaModel>> {
  final BcvService _service;
  final LocalStorage _storage;

  TasaNotifier(this._service, this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    // 1. Intentar caché primero (offline first)
    final cached = _storage.getCachedTasa();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    // 2. Fetch del API
    try {
      final tasa = await _service.fetchCurrentRate();
      await _storage.cacheTasa(tasa);
      state = AsyncValue.data(tasa);
    } catch (e, st) {
      if (cached != null) {
        // Si ya mostramos caché, no sobreescribimos con error
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }
}

final tasaProvider = StateNotifierProvider<TasaNotifier, AsyncValue<TasaModel>>((ref) {
  final service = ref.watch(bcvServiceProvider);
  final storage = ref.watch(localStorageProvider);
  return TasaNotifier(service, storage);
});
