import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasa_provider.dart';

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, bool>((ref) {
  final storage = ref.read(localStorageProvider);
  return AccessibilityNotifier(storage.isAccessibleMode, ref);
});

class AccessibilityNotifier extends StateNotifier<bool> {
  final Ref _ref;

  AccessibilityNotifier(super.initialValue, this._ref);

  Future<void> toggle() async {
    state = !state;
    await _ref.read(localStorageProvider).setAccessibleMode(state);
  }
}

final userPlanProvider = StateProvider<String>((ref) {
  final storage = ref.read(localStorageProvider);
  return storage.isPremium ? 'premium' : 'free';
});
