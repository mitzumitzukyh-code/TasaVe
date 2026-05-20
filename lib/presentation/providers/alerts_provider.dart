import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasa_provider.dart';

/// Modelo de una alerta configurable
class AlertConfig {
  final String id;
  final String label;
  final bool enabled;
  final double threshold;
  final String type; // 'bcv_above', 'ritmo_inusual', 'spread_above'

  const AlertConfig({
    required this.id,
    required this.label,
    required this.enabled,
    required this.threshold,
    required this.type,
  });

  AlertConfig copyWith({bool? enabled, double? threshold}) {
    return AlertConfig(
      id: id,
      label: label,
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'enabled': enabled,
    'threshold': threshold,
    'type': type,
  };

  factory AlertConfig.fromJson(Map<String, dynamic> json) => AlertConfig(
    id: json['id'] as String,
    label: json['label'] as String,
    enabled: json['enabled'] as bool,
    threshold: (json['threshold'] as num).toDouble(),
    type: json['type'] as String,
  );
}

/// Estado completo de alertas
class AlertsState {
  final List<AlertConfig> alerts;
  final String? fcmToken;
  final bool notificationsEnabled;

  const AlertsState({
    required this.alerts,
    this.fcmToken,
    this.notificationsEnabled = false,
  });

  AlertsState copyWith({
    List<AlertConfig>? alerts,
    String? fcmToken,
    bool? notificationsEnabled,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  static AlertsState get initial => const AlertsState(
    alerts: [
      AlertConfig(
        id: 'bcv_above',
        label: 'BCV supere',
        enabled: false,
        threshold: 0, // se inicializa con tasa actual + margen
        type: 'bcv_above',
      ),
      AlertConfig(
        id: 'ritmo_inusual',
        label: 'Ritmo inusual',
        enabled: false,
        threshold: 2.0, // % de cambio por hora
        type: 'ritmo_inusual',
      ),
      AlertConfig(
        id: 'spread_above',
        label: 'Spread supere',
        enabled: false,
        threshold: 4.0, // %
        type: 'spread_above',
      ),
    ],
  );
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final Ref _ref;
  static const String _storageKey = 'alerts_config';

  AlertsNotifier(this._ref) : super(AlertsState.initial) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final storage = _ref.read(localStorageProvider);
    final raw = storage.prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final alerts = (json['alerts'] as List)
            .map((e) => AlertConfig.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AlertsState(
          alerts: alerts,
          fcmToken: json['fcmToken'] as String?,
          notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
        );
      } catch (_) {
        // corrupted data, keep defaults
      }
    }
  }

  Future<void> _saveToStorage() async {
    final storage = _ref.read(localStorageProvider);
    final json = {
      'alerts': state.alerts.map((a) => a.toJson()).toList(),
      'fcmToken': state.fcmToken,
      'notificationsEnabled': state.notificationsEnabled,
    };
    await storage.prefs.setString(_storageKey, jsonEncode(json));
  }

  Future<void> toggleAlert(String alertId) async {
    final updated = state.alerts.map((a) {
      if (a.id == alertId) return a.copyWith(enabled: !a.enabled);
      return a;
    }).toList();
    state = state.copyWith(alerts: updated);
    await _saveToStorage();
    await _syncWithBackend();
  }

  Future<void> updateThreshold(String alertId, double value) async {
    final updated = state.alerts.map((a) {
      if (a.id == alertId) return a.copyWith(threshold: value);
      return a;
    }).toList();
    state = state.copyWith(alerts: updated);
    await _saveToStorage();
    await _syncWithBackend();
  }

  Future<void> setFcmToken(String token) async {
    state = state.copyWith(fcmToken: token, notificationsEnabled: true);
    await _saveToStorage();
    await _syncWithBackend();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveToStorage();
    await _syncWithBackend();
  }

  Future<void> _syncWithBackend() async {
    if (state.fcmToken == null) return;
    try {
      final service = _ref.read(bcvServiceProvider);
      await service.syncAlertPreferences(
        token: state.fcmToken!,
        alerts: state.alerts,
      );
    } catch (_) {
      // silently fail — will retry on next sync
    }
  }

  /// Evalúa alertas localmente contra datos frescos
  List<String> evaluateAlerts({
    required double bcvUsd,
    required double spreadPercent,
  }) {
    final triggered = <String>[];
    for (final alert in state.alerts) {
      if (!alert.enabled) continue;
      switch (alert.type) {
        case 'bcv_above':
          if (alert.threshold > 0 && bcvUsd >= alert.threshold) {
            triggered.add('BCV alcanzó ${bcvUsd.toStringAsFixed(2)} Bs/\$ (umbral: ${alert.threshold.toStringAsFixed(2)})');
          }
          break;
        case 'spread_above':
          if (spreadPercent.abs() >= alert.threshold) {
            triggered.add('Spread en ${spreadPercent.toStringAsFixed(1)}% (umbral: ${alert.threshold.toStringAsFixed(1)}%)');
          }
          break;
        case 'ritmo_inusual':
          // This is evaluated on the backend with historical comparison
          break;
      }
    }
    return triggered;
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier(ref);
});
