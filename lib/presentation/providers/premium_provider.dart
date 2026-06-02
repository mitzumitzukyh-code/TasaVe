import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasa_provider.dart';

class PremiumNotifier extends StateNotifier<bool> {
  final Ref _ref;

  PremiumNotifier(this._ref) : super(false) {
    _load();
  }

  void _load() {
    try {
      final storage = _ref.read(localStorageProvider);
      state = storage.isPremium;
    } catch (_) {
      state = false;
    }
  }

  Future<void> activatePremium() async {
    final storage = _ref.read(localStorageProvider);
    await storage.setUserPlan('premium');
    state = true;
  }

  Future<void> deactivatePremium() async {
    final storage = _ref.read(localStorageProvider);
    await storage.setUserPlan('free');
    state = false;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});
