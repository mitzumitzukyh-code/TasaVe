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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            // ── Header with PREMIUM badge ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2),
                      children: const [
                        TextSpan(text: 'TASA', style: TextStyle(color: AppColors.text)),
                        TextSpan(text: 'VE', style: TextStyle(color: AppColors.green)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPremium ? AppColors.green : AppColors.s4,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isPremium ? 'PREMIUM ACTIVO' : 'FREE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7, fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: isPremium ? const Color(0xFF050505) : AppColors.text3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Section: Recent Alerts ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 4, 13, 6),
              child: Text(
                'ALERTAS RECIENTES',
                style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ),

            // Alert cards (dynamic based on real data)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: _buildDynamicAlerts(),
            ),
            const SizedBox(height: 10),

            // ── Section: My Active Alerts ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
              child: Text(
                'MIS ALERTAS ACTIVAS',
                style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.s2,
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
                          'ritmo_inusual': AppColors.amber,
                          'spread_above': AppColors.green,
                        };
                        final subtitles = {
                          'bcv_above': 'Push cuando BCV supere el umbral',
                          'ritmo_inusual': 'Cambio > ${alert.threshold.toStringAsFixed(1)}%/hora',
                          'spread_above': 'Diferencia oficial vs paralelo',
                        };
                        final valueTexts = {
                          'bcv_above': alert.threshold > 0
                              ? alert.threshold.toStringAsFixed(2)
                              : 'configurar',
                          'ritmo_inusual': '${alert.threshold.toStringAsFixed(1)}%/h',
                          'spread_above': '${alert.threshold.toStringAsFixed(1)}%',
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
          ],
        ),
      ),
    );
  }

  void _showThresholdEditor(BuildContext context, AlertConfig alert) {
    final controller = TextEditingController(
      text: alert.threshold > 0 ? alert.threshold.toStringAsFixed(2) : '',
    );
    final suffix = alert.type == 'bcv_above' ? 'Bs/\$' : '%';
    final hint = alert.type == 'bcv_above' ? 'Ej: 80.00' : 'Ej: 4.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.s2,
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
              style: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 2, color: AppColors.text3),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text3),
                suffixText: suffix,
                suffixStyle: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.text3),
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
                child: Text('GUARDAR', style: GoogleFonts.spaceMono(
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

    final spread = tasa.spreadPercent;
    final alerts = <Widget>[];

    // Alert 1: Spread analysis (always show if data available)
    if (tasa.usdtP2P != null && spread.abs() > 0) {
      final isHigh = spread.abs() > 25;
      alerts.add(_AlertCard(
        emoji: isHigh ? '⚡' : '📊',
        title: isHigh ? 'Spread inusual detectado' : 'Spread BCV vs Paralelo',
        subtitle: 'Diferencia: ${spread > 0 ? "+" : ""}${spread.toStringAsFixed(1)}% · P2P: ${Formatters.formatRate(tasa.usdtP2P!)}',
        time: Formatters.timeAgo(tasa.timestamp),
        borderColor: isHigh ? AppColors.amber : AppColors.blue,
        bgColor: isHigh ? AppColors.amberDim : AppColors.blueDim,
      ));
    }

    // Alert 2: BCV status
    if (tasa.bcvStatus != null) {
      final isLive = tasa.bcvStatus!.contains('Monitoreando');
      alerts.add(Padding(
        padding: const EdgeInsets.only(top: 5),
        child: _AlertCard(
          emoji: isLive ? '🔴' : '✓',
          title: isLive ? 'Monitoreando BCV' : 'Tasa BCV actualizada',
          subtitle: '${tasa.bcvStatus} · BCV: ${Formatters.formatRate(tasa.bcvUsd)}',
          time: '${tasa.timestamp.hour}:${tasa.timestamp.minute.toString().padLeft(2, '0')}',
          borderColor: isLive ? AppColors.amber : AppColors.green,
          bgColor: isLive ? AppColors.amberDim : AppColors.greenDim,
        ),
      ));
    }

    // Alert 3: Yadio comparison
    if (tasa.yadioRate != null && tasa.yadioRate! > 0) {
      final yadioDiff = ((tasa.yadioRate! - tasa.bcvUsd) / tasa.bcvUsd * 100);
      alerts.add(Padding(
        padding: const EdgeInsets.only(top: 5),
        child: _AlertCard(
          emoji: '🌐',
          title: 'Yadio vs BCV',
          subtitle: 'Yadio: ${Formatters.formatRate(tasa.yadioRate!)} · ${yadioDiff > 0 ? "+" : ""}${yadioDiff.toStringAsFixed(1)}% vs oficial',
          time: 'hoy',
          borderColor: AppColors.border2,
          bgColor: AppColors.s2,
        ),
      ));
    }

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
            style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3)),
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
                          style: GoogleFonts.spaceMono(
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
                color: isEnabled ? toggleColor : AppColors.s4,
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
