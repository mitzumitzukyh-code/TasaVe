import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tasa_model.dart';

class LocalStorage {
  static const String _TASA_KEY = 'cached_tasa';
  static const String _HISTORY_KEY = 'cached_history';
  static const String _USER_PLAN_KEY = 'user_plan';
  static const String _ACCESSIBLE_KEY = 'accessible_mode';
  static const String _SCAN_DATE_KEY = 'scan_date';
  static const String _SCAN_COUNT_KEY = 'scan_count';

  final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  LocalStorage(this._prefs);

  Future<void> cacheTasa(TasaModel tasa) async {
    await _prefs.setString(_TASA_KEY, jsonEncode(tasa.toJson()));
  }

  TasaModel? getCachedTasa() {
    final raw = _prefs.getString(_TASA_KEY);
    if (raw == null) return null;
    return TasaModel.fromJson(jsonDecode(raw)).copyWith(isFromCache: true);
  }

  Future<void> cacheHistory(List<TasaHistoryEntry> history) async {
    final list = history.map((e) => {
      'date': e.date.toIso8601String(),
      'bcvUsd': e.bcvUsd,
      'variation': e.variation,
    }).toList();
    await _prefs.setString(_HISTORY_KEY, jsonEncode(list));
  }

  List<TasaHistoryEntry>? getCachedHistory() {
    final raw = _prefs.getString(_HISTORY_KEY);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => TasaHistoryEntry.fromJson(e)).toList();
  }

  bool get isAccessibleMode => _prefs.getBool(_ACCESSIBLE_KEY) ?? false;

  Future<void> setAccessibleMode(bool value) async {
    await _prefs.setBool(_ACCESSIBLE_KEY, value);
  }

  bool get isPremium => _prefs.getString(_USER_PLAN_KEY) == 'premium';

  Future<void> setUserPlan(String plan) async {
    await _prefs.setString(_USER_PLAN_KEY, plan);
  }

  int get dailyScanCount {
    final today = _todayKey();
    final saved = _prefs.getString(_SCAN_DATE_KEY);
    if (saved != today) return 0;
    return _prefs.getInt(_SCAN_COUNT_KEY) ?? 0;
  }

  Future<void> incrementDailyScanCount() async {
    final today = _todayKey();
    final saved = _prefs.getString(_SCAN_DATE_KEY);
    if (saved != today) {
      await _prefs.setString(_SCAN_DATE_KEY, today);
      await _prefs.setInt(_SCAN_COUNT_KEY, 1);
      return;
    }
    await _prefs.setInt(_SCAN_COUNT_KEY, dailyScanCount + 1);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}
