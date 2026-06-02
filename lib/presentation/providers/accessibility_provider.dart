import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/cache/local_storage.dart';
import 'tasa_provider.dart';

class AccessibilityNotifier extends StateNotifier<bool> {
  final LocalStorage _storage;

  AccessibilityNotifier(this._storage) : super(_storage.isAccessibleMode);

  void toggle() {
    state = !state;
    _storage.setAccessibleMode(state);
  }

  void set(bool value) {
    state = value;
    _storage.setAccessibleMode(value);
  }
}

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, bool>((ref) {
  final storage = ref.watch(localStorageProvider);
  return AccessibilityNotifier(storage);
});
