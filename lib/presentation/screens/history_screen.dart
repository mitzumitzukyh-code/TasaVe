import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/connectivity.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/history_provider.dart';
import '../providers/tasa_provider.dart';
import '../../data/models/tasa_model.dart';
import '../../core/constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';
import '../widgets/connection_status_chip.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedDays = 30;
  final _tabs = [7, 30, 90, 365];
  final _tabLabels = ['7D', '30D', '90D', '1A'];

  void _retry() {
    ref.invalidate(historyProvider(_selectedDays));
    ref.read(tasaProvider.notifier).refresh();
  }

  void _exportCsv(List<TasaHistoryEntry> entries) {
    final buffer = StringBuffer('fecha,bcv_usd,variacion_bs\n');
    for (final e in entries) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(e.date)},${e.bcvUsd.toStringAsFixed(2)},${e.variation.toStringAsFixed(2)}',
      );
    }
    Share.share(buffer.toString(), subject: 'Historial TasaVe');
  }

  double _dayChangePct(List<TasaHistoryEntry> entries, int index) {
    final entry = entries[index];
    final prevBcvUsd = index < entries.length - 1 ? entries[index + 1].bcvUsd : null;
    if (prevBcvUsd != null && prevBcvUsd > 0) {
      return ((entry.bcvUsd - prevBcvUsd) / prevBcvUsd) * 100;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider(_selectedDays));
    final tasa = ref.watch(tasaProvider).valueOrNull;
    final isOnline = ref.watch(connectivityProvider).valueOrNull;
    final fromCache = historyAsync.hasValue &&
        (isOnline == false || (tasa?.isFromCache ?? false));

    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Historial',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        actions: [
          if (fromCache)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ConnectionStatusChip(
                status: DataConnectionStatus.cache,
                compact: true,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: TextButton(
              onPressed: historyAsync.hasValue && isPremium
                  ? () => _exportCsv(historyAsync.requireValue)
                  : historyAsync.hasValue && !isPremium
                      ? () => _showProRequired(context)
                      : null,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(
                'CSV ↓',
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Period Tabs (pills) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _tabs[i] == _selectedDays;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () {
                        if (!isPremium && _tabs[i] > SubscriptionConstants.freeHistoryMaxDays) {
                          _showProRequired(context);
                          return;
                        }
                        setState(() => _selectedDays = _tabs[i]);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _tabLabels[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.text3,
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
                data: (entries) => _buildContent(entries, fromCache: fromCache),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => _ErrorState(onRetry: _retry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Historial extendido y CSV son funciones Pro.',
          style: GoogleFonts.dmSans(),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildContent(List<TasaHistoryEntry> entries, {bool fromCache = false}) {
    if (entries.isEmpty) {
      return _ErrorState(
        message: 'Sin datos para este período',
        onRetry: _retry,
      );
    }

    final latest = entries.first;
    final oldest = entries.last;
    final changePct = oldest.bcvUsd > 0
        ? ((latest.bcvUsd - oldest.bcvUsd) / oldest.bcvUsd * 100)
        : 0.0;

    final minRate = entries.map((e) => e.bcvUsd).reduce((a, b) => a < b ? a : b);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      children: [
        if (fromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.yellowLight,
                borderRadius: BorderRadius.circular(AppColors.r1),
                border: Border.all(color: AppColors.yellow),
              ),
              child: Text(
                'Mostrando historial guardado — conecta para actualizar',
                style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6D5500)),
              ),
            ),
          ),
        // ── Chart Card ──
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                            style: GoogleFonts.dmSans(fontSize: 30, color: AppColors.text),
                          ),
                          const SizedBox(width: 4),
                          Text('Bs/\$', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text3)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${changePct >= 0 ? "▲" : "▼"} ${changePct >= 0 ? "+" : ""}${changePct.toStringAsFixed(1)}% en $_selectedDays días',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: changePct >= 0 ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'mín período',
                        style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.text3),
                      ),
                      Text(
                        Formatters.formatRate(minRate),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ZoomableChart(entries: entries),
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
                'Registro diario',
                style: GoogleFonts.dmSans(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ],
          ),
        ),

        // ── History list ──
        ...entries.asMap().entries.map((item) {
          final index = item.key;
          final entry = item.value;
          final pct = _dayChangePct(entries, index);
          final isUp = pct >= 0;
          final dateStr = _formatEntryDate(entry.date);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    dateStr,
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
                  ),
                ),
                Expanded(
                  child: Text(
                    Formatters.formatRate(entry.bcvUsd),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pct == 0
                        ? AppColors.bg
                        : isUp
                            ? AppColors.greenLight
                            : AppColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pct == 0 ? AppColors.text3 : isUp ? AppColors.green : AppColors.red,
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


  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);

    if (entryDay == today) return 'Hoy';
    if (entryDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return DateFormat('dd MMM', 'es').format(date);
  }
}

// ─────────────────────────────────────────────
// GRÁFICA MEJORADA CON ZOOM + ANOTACIONES
// ─────────────────────────────────────────────
class _ZoomableChart extends StatefulWidget {
  final List<TasaHistoryEntry> entries;
  const _ZoomableChart({required this.entries});

  @override
  State<_ZoomableChart> createState() => _ZoomableChartState();
}

class _ZoomableChartState extends State<_ZoomableChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final reversed = widget.entries.reversed.toList();
    if (reversed.isEmpty) return const SizedBox(height: 160);

    final spots = <FlSpot>[
      for (var i = 0; i < reversed.length; i++)
        FlSpot(i.toDouble(), reversed[i].bcvUsd),
    ];

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minIdx = values.indexOf(minY);
    final maxIdx = values.indexOf(maxY);
    final padding = (maxY - minY) < 1 ? 2.0 : (maxY - minY) * 0.15;

    return InteractiveViewer(
      scaleEnabled: true,
      panEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY + padding * 2) / 4,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.border,
                strokeWidth: 0.5,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(0),
                    style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text3),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (spots.length / 4).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= reversed.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('dd/MM').format(reversed[idx].date),
                        style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.text3),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: minY - padding,
            maxY: maxY + padding,
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: maxY,
                  color: AppColors.green.withValues(alpha: 0.35),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => '↑ ${maxY.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.green),
                  ),
                ),
                HorizontalLine(
                  y: minY,
                  color: AppColors.red.withValues(alpha: 0.35),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    labelResolver: (_) => '↓ ${minY.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.red),
                  ),
                ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.green,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, _) =>
                      spot.x.toInt() == minIdx ||
                      spot.x.toInt() == maxIdx ||
                      spot.x.toInt() == _touchedIndex,
                  getDotPainter: (spot, _, __, ___) {
                    final isMax = spot.x.toInt() == maxIdx;
                    final isTouched = spot.x.toInt() == _touchedIndex;
                    return FlDotCirclePainter(
                      radius: isTouched ? 5 : 4,
                      color: isMax ? AppColors.green : AppColors.red,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.green.withValues(alpha: 0.15),
                      AppColors.green.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                final idx = response?.lineBarSpots?.first.spotIndex;
                if (mounted) setState(() => _touchedIndex = idx);
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface,
                tooltipBorder: const BorderSide(color: AppColors.border),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                  final idx = s.spotIndex;
                  final entry = idx < reversed.length ? reversed[idx] : null;
                  final dateStr = entry != null
                      ? DateFormat('dd MMM', 'es').format(entry.date)
                      : '';
                  return LineTooltipItem(
                    '$dateStr\n${s.y.toStringAsFixed(2)} Bs/\$',
                    GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    this.message = 'No se pudo cargar el historial',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text2),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                'Reintentar',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
