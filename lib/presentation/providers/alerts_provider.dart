import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/alert_model.dart';
import 'tasa_provider.dart';

class AlertsNotifier extends StateNotifier<List<AlertModel>> {
  final SharedPreferences _prefs;

  AlertsNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(AppConstants.kPrefAlerts);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = AlertModel.decodeList(raw);
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(AppConstants.kPrefAlerts, AlertModel.encodeList(state));
  }

  void add(AlertModel alert) {
    state = [...state, alert];
    _save();
  }

  void toggle(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(isActive: !a.isActive) else a,
    ];
    _save();
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
    _save();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<AlertModel>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AlertsNotifier(prefs);
});
