import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/accessibility_provider.dart';
import '../providers/tasa_provider.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final userPlan = ref.watch(userPlanProvider);
    final isPremium = userPlan == 'premium';
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Alertas',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPremium
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : 'FREE',
                  style: GoogleFonts.dmSans(
                    fontSize: 8, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
        children: [
            // ── Section: Recent Alerts ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
              child: Text(
                'ALERTAS RECIENTES',
                style: GoogleFonts.dmSans(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ),

            // Alert cards (dynamic based on real data)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: _buildDynamicAlerts(),
            ),
            const SizedBox(height: 10),

            // ── Banner explicativo de notificaciones push ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppColors.r1),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las notificaciones push se envían automáticamente desde el servidor cuando la tasa BCV cambia, el spread P2P es inusual o hay máximos históricos. Activa las notificaciones desde Ajustes (⚙️) en la pantalla Inicio.',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section: My Active Alerts ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
              child: Text(
                'UMBRALES DE SEGUIMIENTO',
                style: GoogleFonts.dmSans(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 4),
              child: Text(
                'Configura los valores para recibir notificaciones personalizadas',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text2),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppColors.r2),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < alertsState.alerts.length; i++) ...[
                      if (i > 0) Container(height: 1, color: AppColors.border),
                      Builder(builder: (_) {
                        final alert = alertsState.alerts[i];
                        final colors = {
                          'bcv_above': AppColors.green,
                          'ritmo_inusual': AppColors.yellow,
                          'p2p_above': AppColors.green,
                        };
                        final subtitles = {
                          'bcv_above': 'Notificación cuando BCV supere este valor',
                          'ritmo_inusual': 'Alerta si el cambio supera ${alert.threshold.toStringAsFixed(1)}%/hora',
                          'p2p_above': 'Alerta cuando spread P2P vs BCV supere este %',
                        };
                        final valueTexts = {
                          'bcv_above': alert.threshold > 0
                              ? '${alert.threshold.toStringAsFixed(2)} Bs/\$'
                              : 'sin umbral',
                          'ritmo_inusual': '${alert.threshold.toStringAsFixed(1)}%/h',
                          'p2p_above': '${alert.threshold.toStringAsFixed(1)}%',
                        };
                        return _ToggleRow(
                          label: alert.label,
                          valueText: valueTexts[alert.type] ?? '',
                          valueColor: colors[alert.type] ?? AppColors.text2,
                          subtitle: subtitles[alert.type] ?? '',
                          isEnabled: alert.enabled,
                          toggleColor: colors[alert.type] ?? AppColors.green,
                          onToggle: () {
                            ref.read(alertsProvider.notifier).toggleAlert(alert.id);
                          },
                          onValueTap: () => _showThresholdEditor(context, alert),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            // ── Nota informativa al pie ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
              child: Text(
                'Toca el valor subrayado para cambiar el umbral. Los cambios se aplican en la próxima verificación del servidor.',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text3, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  void _showThresholdEditor(BuildContext context, AlertConfig alert) {
    final controller = TextEditingController(
      text: alert.threshold > 0 ? alert.threshold.toStringAsFixed(2) : '',
    );
    final suffix = alert.type == 'bcv_above' ? 'Bs/\$' : '%';
    final hint = alert.type == 'bcv_above' ? 'Ej: 80.00' : alert.type == 'ritmo_inusual' ? 'Ej: 2.0' : 'Ej: 4.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CONFIGURAR: ${alert.label.toUpperCase()}',
              style: GoogleFonts.dmSans(fontSize: 10, letterSpacing: 2, color: AppColors.text3),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.dmSans(fontSize: 30, color: AppColors.text),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(fontSize: 30, color: AppColors.text3),
                suffixText: suffix,
                suffixStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: const Color(0xFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value != null && value > 0) {
                    ref.read(alertsProvider.notifier).updateThreshold(alert.id, value);
                    Navigator.pop(context);
                  }
                },
                child: Text('GUARDAR', style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicAlerts() {
    final tasaAsync = ref.watch(tasaProvider);
    final tasa = tasaAsync.valueOrNull;

    if (tasa == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final alerts = <Widget>[];

    // Alert 1: P2P vs BCV comparison
    if (tasa.usdtP2P > 0 && tasa.bcvUsd > 0) {
      final diff = ((tasa.usdtP2P - tasa.bcvUsd) / tasa.bcvUsd * 100);
      final isHigh = diff.abs() > 25;
      alerts.add(_AlertCard(
        emoji: isHigh ? '⚡' : '📊',
        title: isHigh ? 'Diferencia inusual detectada' : 'P2P vs BCV',
        subtitle: 'Diferencia: ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)}% · P2P: ${Formatters.formatRate(tasa.usdtP2P)}',
        time: Formatters.timeAgo(tasa.timestamp),
        borderColor: isHigh ? AppColors.yellow : AppColors.border,
        bgColor: isHigh ? AppColors.yellowLight : AppColors.surface,
      ));
    }

    // Alert 2: BCV info
    alerts.add(Padding(
      padding: const EdgeInsets.only(top: 5),
      child: _AlertCard(
        emoji: '✓',
        title: 'Tasa BCV actualizada',
        subtitle: 'BCV: ${Formatters.formatRate(tasa.bcvUsd)} Bs/\$ · ${tasa.timestamp.hour}:${tasa.timestamp.minute.toString().padLeft(2, '0')}',
        time: Formatters.timeAgo(tasa.timestamp),
        borderColor: AppColors.green,
        bgColor: AppColors.greenLight,
      ),
    ));

    if (alerts.isEmpty) {
      return Text('Sin alertas activas',
        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3));
    }

    return Column(children: alerts);
  }
}

// ── Alert Card (colored border left) ──
class _AlertCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String time;
  final Color borderColor;
  final Color bgColor;

  const _AlertCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.borderColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text2, height: 1.4)),
              ],
            ),
          ),
          Text(time,
            style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.text3)),
        ],
      ),
    );
  }
}

// ── Toggle Row ──
class _ToggleRow extends StatelessWidget {
  final String label;
  final String valueText;
  final Color valueColor;
  final String subtitle;
  final bool isEnabled;
  final Color toggleColor;
  final VoidCallback onToggle;
  final VoidCallback? onValueTap;

  const _ToggleRow({
    required this.label,
    required this.valueText,
    required this.valueColor,
    required this.subtitle,
    required this.isEnabled,
    required this.toggleColor,
    required this.onToggle,
    this.onValueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onValueTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text),
                      children: [
                        TextSpan(text: '$label '),
                        TextSpan(
                          text: valueText,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: valueColor,
                            decoration: onValueTap != null ? TextDecoration.underline : null,
                            decorationColor: valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text3)),
                ],
              ),
            ),
          ),
          // Toggle switch — interactive
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 20,
              decoration: BoxDecoration(
                color: isEnabled ? toggleColor : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16, height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
