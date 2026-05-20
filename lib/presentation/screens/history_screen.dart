import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/history_provider.dart';
import '../../data/models/tasa_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedDays = 30;
  final _tabs = [7, 30, 90, 365];
  final _tabLabels = ['7D', '30D', '90D', '1A'];

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider(_selectedDays));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2),
                  children: const [
                    TextSpan(text: 'TASA', style: TextStyle(color: AppColors.text)),
                    TextSpan(text: 'VE', style: TextStyle(color: AppColors.green)),
                  ],
                ),
              ),
            ),

            // ── Period Tabs (pills) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _tabs[i] == _selectedDays;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDays = _tabs[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.s3 : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: active ? AppColors.green : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _tabLabels[i],
                          style: GoogleFonts.spaceMono(
                            fontSize: 8, letterSpacing: 1,
                            color: active ? AppColors.green : AppColors.text3,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Content ──
            Expanded(
              child: historyAsync.when(
                data: (entries) => _buildContent(entries),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.green)),
                error: (e, _) => Center(
                  child: Text('Error cargando historial', style: GoogleFonts.dmSans(color: AppColors.text3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<TasaHistoryEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text('Sin datos disponibles', style: GoogleFonts.dmSans(color: AppColors.text3)),
      );
    }

    final latest = entries.first;
    final oldest = entries.last;
    final changePct = oldest.bcvUsd > 0
        ? ((latest.bcvUsd - oldest.bcvUsd) / oldest.bcvUsd * 100)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      children: [
        // ── Chart Card ──
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.s2,
            borderRadius: BorderRadius.circular(AppColors.r3),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Formatters.formatRate(latest.bcvUsd),
                            style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text),
                          ),
                          const SizedBox(width: 4),
                          Text('Bs/\$', style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.text3)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '▲ ${changePct >= 0 ? "+" : ""}${changePct.toStringAsFixed(1)}% últimos $_selectedDays días',
                        style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.green),
                      ),
                    ],
                  ),
                  // Legend
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 1.5, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text('BCV', style: GoogleFonts.spaceMono(fontSize: 7, color: AppColors.text2)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 1.5, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text('P2P', style: GoogleFonts.spaceMono(fontSize: 7, color: AppColors.text2)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 85,
                child: _buildChart(entries),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── Daily Register Header ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTRO DIARIO',
                style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
              Text(
                'CSV →',
                style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.green),
              ),
            ],
          ),
        ),

        // ── History list ──
        ...entries.map((entry) {
          final isUp = entry.variation >= 0;
          final pct = entry.bcvUsd > 0
              ? (entry.variation / entry.bcvUsd * 100)
              : 0.0;
          final dateStr = _formatEntryDate(entry.date);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    dateStr,
                    style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3),
                  ),
                ),
                Expanded(
                  child: Text(
                    Formatters.formatRate(entry.bcvUsd),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: isUp ? AppColors.green : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChart(List<TasaHistoryEntry> entries) {
    final reversed = entries.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].bcvUsd));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.text3),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (spots.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= reversed.length) return const SizedBox.shrink();
                return Text(
                  DateFormat('dd/MM').format(reversed[idx].date),
                  style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.text3),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.green,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.green.withValues(alpha: 0.07),
            ),
          ),
          // P2P line (simulated ~3% above BCV, dashed amber)
          LineChartBarData(
            spots: spots.map((s) => FlSpot(s.x, s.y * 1.03)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.amber,
            barWidth: 1.2,
            dotData: const FlDotData(show: false),
            dashArray: [4, 3],
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.border2),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(2)} Bs/\$',
                GoogleFonts.dmMono(fontSize: 12, color: AppColors.text),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);

    if (entryDay == today) return 'Hoy';
    if (entryDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return DateFormat('dd MMM', 'es').format(date);
  }

}

