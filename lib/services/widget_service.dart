import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../data/models/tasa_model.dart';
import '../utils/formatters.dart';

/// Actualiza el widget de pantalla de inicio (Android) con la tasa BCV.
class WidgetService {
  WidgetService._();

  static const _androidProvider = 'TasaWidgetProvider';

  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('group.com.miztmutzuki.tasave');
    } catch (_) {
      // Android ignora app group; no bloquea.
    }
  }

  static Future<void> updateFromTasa(TasaModel tasa, {bool isPremium = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final rate = tasa.bcvUsd > 0 ? Formatters.formatRate(tasa.bcvUsd) : '—';
      final p2p = tasa.usdtP2P > 0 ? Formatters.formatRate(tasa.usdtP2P) : '—';
      final spread = tasa.bcvUsd > 0 && tasa.usdtP2P > 0
          ? ((tasa.usdtP2P - tasa.bcvUsd) / tasa.bcvUsd * 100).toStringAsFixed(1)
          : '—';

      await HomeWidget.saveWidgetData<String>('bcv_rate', rate);
      await HomeWidget.saveWidgetData<String>('p2p_rate', p2p);
      await HomeWidget.saveWidgetData<String>('spread_pct', spread);
      await HomeWidget.saveWidgetData<String>(
        'updated_at',
        Formatters.timeAgo(tasa.timestamp),
      );
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // Widget opcional; no interrumpe flujo principal.
    }
  }
}
