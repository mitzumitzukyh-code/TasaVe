import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/tasa_model.dart';
import '../../utils/formatters.dart';
import '../providers/history_provider.dart';
import '../providers/history_days_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final days = ref.watch(historyDaysProvider);
    final historyAsync = ref.watch(historyProvider(days));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial BCV',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _export(context, ref, days),
                    child: Text(
                      'Exportar',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                children: [
                  _FilterChip(label: '7 días', value: 7, currentDays: days, ref: ref),
                  const SizedBox(width: 6),
                  _FilterChip(label: '30 días', value: 30, currentDays: days, ref: ref),
                  const SizedBox(width: 6),
                  _FilterChip(label: '90 días', value: 90, currentDays: days, ref: ref),
                  const SizedBox(width: 6),
                  _FilterChip(label: '1 año', value: 365, currentDays: days, ref: ref),
                ],
              ),
            ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Sin datos disponibles',
                    style: GoogleFonts.dmSans(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin datos disponibles',
                        style: GoogleFonts.dmSans(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
                  final chartData = [...entries]..sort((a, b) => a.date.compareTo(b.date));
                  final minRate = chartData.map((e) => e.bcvUsd).reduce(math.min);
                  final maxRate = chartData.map((e) => e.bcvUsd).reduce(math.max);

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _HistoryChart(
                        entries: chartData,
                        minRate: minRate,
                        maxRate: maxRate,
                      ),
                      _StatsRow(entries: entries),
                      _TableHeader(theme: theme),
                      ...sorted.asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        final prev = i < sorted.length - 1 ? sorted[i + 1] : null;
                        return _TableRow(
                          entry: entry,
                          previousEntry: prev,
                          theme: theme,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, int days) async {
    final historyAsync = ref.read(historyProvider(days));
    final entries = historyAsync.whenOrNull(data: (e) => e) ?? [];
    if (entries.isEmpty) return;
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    final csv = StringBuffer('Fecha,Tasa BCV,Variación\n');
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final prev = i < sorted.length - 1 ? sorted[i + 1] : null;
      final pct = prev != null && prev.bcvUsd > 0
          ? ((entry.bcvUsd - prev.bcvUsd) / prev.bcvUsd * 100).toStringAsFixed(2)
          : '—';
      csv.writeln('${entry.date.toString().substring(0, 10)},${entry.bcvUsd},$pct%');
    }
    await Share.share(csv.toString());
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int value;
  final int currentDays;
  final WidgetRef ref;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.currentDays,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentDays;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(historyDaysProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<TasaHistoryEntry> entries;
  final double minRate;
  final double maxRate;

  const _HistoryChart({
    required this.entries,
    required this.minRate,
    required this.maxRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.bcvUsd);
    }).toList();

    final padding = (maxRate - minRate) * 0.1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(0, 12, 12, 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LineChart(
          LineChartData(
            minY: minRate - padding,
            maxY: maxRate + padding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) {
                    if (idx != spots.length - 1) {
                      return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                    }
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<TasaHistoryEntry> entries;
  const _StatsRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rates = entries.map((e) => e.bcvUsd).toList();
    final min = rates.reduce(math.min);
    final max = rates.reduce(math.max);
    final avg = rates.reduce((a, b) => a + b) / rates.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        children: [
          _StatCard(label: 'MÍNIMO', value: Formatters.formatRate(min), color: AppColors.success, theme: theme),
          const SizedBox(width: 6),
          _StatCard(label: 'PROMEDIO', value: Formatters.formatRate(avg), color: theme.colorScheme.onSurface, theme: theme),
          const SizedBox(width: 6),
          _StatCard(label: 'MÁXIMO', value: Formatters.formatRate(max), color: AppColors.primary, theme: theme),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final ThemeData theme;
  const _TableHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('FECHA', style: _headerStyle(theme)),
          ),
          Expanded(
            flex: 2,
            child: Text('TASA BCV', style: _headerStyle(theme)),
          ),
          Expanded(
            flex: 2,
            child: Text('VARIACIÓN', textAlign: TextAlign.end, style: _headerStyle(theme)),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(ThemeData theme) => GoogleFonts.dmSans(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      );
}

class _TableRow extends StatelessWidget {
  final TasaHistoryEntry entry;
  final TasaHistoryEntry? previousEntry;
  final ThemeData theme;

  const _TableRow({
    required this.entry,
    this.previousEntry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = previousEntry != null && previousEntry!.bcvUsd > 0
        ? entry.getVariationPct(previousEntry!.bcvUsd)
        : null;

    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final dateStr = '${entry.date.day.toString().padLeft(2, '0')} '
        '${months[entry.date.month - 1]}';

    Color pctColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    String pctStr = '—';
    if (pct != null) {
      pctStr = pct >= 0 ? '+${pct.toStringAsFixed(2)}%' : '${pct.toStringAsFixed(2)}%';
      pctColor = pct > 0 ? AppColors.success : pct < 0 ? AppColors.error : pctColor;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatRate(entry.bcvUsd),
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pctStr,
              textAlign: TextAlign.end,
              style: GoogleFonts.spaceMono(fontSize: 11, color: pctColor),
            ),
          ),
        ],
      ),
    );
  }
}
