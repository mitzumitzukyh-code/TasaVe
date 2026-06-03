import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/tasa_model.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';
import '../providers/history_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  bool _isUsdInput = true;
  String _result = '0,00';
  int? _selectedChip;

  // ── Formateo manual (sin locale — funciona en Flutter Web) ──

  // Formatea con punto de miles y coma decimal: 27898.5 → "27.898,50"
  String _formatBs(double value) {
    // Redondear a 2 decimales para evitar imprecisión de punto flotante
    final rounded = (value * 100).round();
    final intPart = rounded ~/ 100;
    final decPart = (rounded % 100).toString().padLeft(2, '0');
    return '${_addThousands(intPart)},$decPart';
  }

  // Formatea sin punto de miles y coma decimal: 8.96 → "8,96"
  String _formatUsd(double value) {
    final rounded = (value * 100).round();
    final intPart = rounded ~/ 100;
    final decPart = (rounded % 100).toString().padLeft(2, '0');
    return '$intPart,$decPart';
  }

  // Agrega puntos de miles: 27898 → "27.898"
  String _addThousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      if (i > 0 && remaining % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── Máscara financiera (Regla 12 CLAUDE.md) ─────────────

  String _applyMask(String raw, {bool withThousands = false}) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final value = int.parse(digits);
    final integer = value ~/ 100;
    final decimal = (value % 100).toString().padLeft(2, '0');
    if (withThousands) {
      return '${_addThousands(integer)},$decimal';
    }
    return '$integer,$decimal';
  }

  double _parseMasked(String masked) {
    if (masked.isEmpty) return 0;
    final cleaned = masked.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  void _onInputChanged() {
    final tasaAsync = ref.read(tasaProvider);
    final rate = tasaAsync.whenOrNull(data: (t) => t.bcvUsd) ?? 0;
    if (rate <= 0) return;

    final input = _parseMasked(_controller.text);
    if (input == 0) {
      _result = '0,00';
      return;
    }

    if (_isUsdInput) {
      final bsValue = input * rate;
      _result = _formatBs(bsValue);
    } else {
      final usdValue = input / rate;
      _result = _formatUsd(usdValue);
    }
  }

  void _swap() {
    final tasaAsync = ref.read(tasaProvider);
    final rate = tasaAsync.whenOrNull(data: (t) => t.bcvUsd) ?? 0;

    // Guardar el resultado actual como nuevo input
    final currentResult = _result;

    // Cambiar dirección
    _isUsdInput = !_isUsdInput;

    // Si había un resultado válido, ponerlo como nuevo input
    if (currentResult.isNotEmpty && currentResult != '0,00' && rate > 0) {
      // Convertir el resultado a dígitos para la máscara
      final cleaned = currentResult
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final value = double.tryParse(cleaned) ?? 0;
      if (value > 0) {
        // Convertir a centavos para la máscara financiera
        final centavos = (value * 100).round();
        // Si ahora el input es Bs, agregar puntos de miles
        final masked = _applyMask(centavos.toString(),
            withThousands: !_isUsdInput);
        _controller.text = masked;
        _controller.selection = TextSelection.collapsed(offset: masked.length);
      } else {
        _controller.text = '';
      }
    } else {
      _controller.text = '';
    }

    _onInputChanged();
    setState(() {});
  }

  void _onQuickAmount(int amount) {
    _isUsdInput = true;
    _selectedChip = amount;
    final centavos = amount * 100;
    final masked = _applyMask(centavos.toString());
    _controller.text = masked;
    _controller.selection =
        TextSelection.collapsed(offset: masked.length);
    _onInputChanged();
    setState(() {});
  }

  // ── Lifecycle ───────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final masked = _applyMask(_controller.text,
          withThousands: !_isUsdInput);
      if (masked != _controller.text) {
        _controller.text = masked;
        _controller.selection =
            TextSelection.collapsed(offset: masked.length);
      }
      if (_controller.text.isEmpty && _selectedChip != null) {
        _selectedChip = null;
      }
      _onInputChanged();
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = '1,00';
      if (_controller.text.isEmpty && _selectedChip != null) {
        _selectedChip = null;
      }
      _onInputChanged();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasaAsync = ref.watch(tasaProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: tasaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: 'Error al obtener la tasa',
            onRetry: () => ref.read(tasaProvider.notifier).refresh(),
          ),
          data: (tasa) => _BankHome(
            tasa: tasa,
            controller: _controller,
            isUsdInput: _isUsdInput,
            result: _result,
            onSwap: _swap,
            onMaskChanged: _applyMask,
            onQuickAmount: _onQuickAmount,
            selectedChip: _selectedChip,
            historyAsync: ref.watch(historyProvider(7)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BANK HOME — diseño completo tipo app de banco
// ─────────────────────────────────────────────────────────────

class _BankHome extends StatelessWidget {
  final TasaModel tasa;
  final TextEditingController controller;
  final bool isUsdInput;
  final String result;
  final VoidCallback onSwap;
  final String Function(String) onMaskChanged;
  final void Function(int amount) onQuickAmount;
  final int? selectedChip;
  final AsyncValue<List<TasaHistoryEntry>> historyAsync;

  const _BankHome({
    required this.tasa,
    required this.controller,
    required this.isUsdInput,
    required this.result,
    required this.onSwap,
    required this.onMaskChanged,
    required this.onQuickAmount,
    required this.selectedChip,
    required this.historyAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Calcular % de cambio vs día anterior ──
    final double? change = historyAsync.whenOrNull(
      data: (history) {
        if (history.isEmpty) return null;
        final now = DateTime.now();
        for (final entry in history) {
          if (entry.date.day != now.day ||
              entry.date.month != now.month ||
              entry.date.year != now.year) {
            if (entry.bcvUsd > 0) {
              return ((tasa.bcvUsd - entry.bcvUsd) / entry.bcvUsd) * 100;
            }
            break;
          }
        }
        return null;
      },
    );

    // ── Tiempo desde última actualización ──
    final diff = DateTime.now().difference(tasa.timestamp);
    final timeAgoStr = diff.inMinutes < 1
        ? 'ahora'
        : diff.inMinutes < 60
            ? 'hace ${diff.inMinutes}min'
            : 'hace ${diff.inHours}h';

    // ── Formatear tasa principal ──
    final formatted = Formatters.formatRate(tasa.bcvUsd);
    final parts = formatted.split(',');
    final intPart = parts.isNotEmpty ? parts[0] : '0';
    final decPart = parts.length > 1 ? parts[1] : '00';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════
          // 1. HEADER
          // ═══════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tasave',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    color: const Color(0xFFE53935),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                  color: const Color(0xFFE53935),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // 2. HERO CARD
          // ═══════════════════════════════════════════
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DÓLAR BCV OFICIAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Bs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: 3),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: intPart,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ',$decPart',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (change != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'SpaceMono',
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'vs ayer · $timeAgoStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // 3. CALCULADORA RÁPIDA
          // ═══════════════════════════════════════════
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // ── Fila USD (input) ──
                Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        isUsdInput ? 'USD' : 'Bs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]')),
                        ],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SpaceMono',
                          color: const Color(0xFFE53935),
                        ),
                        decoration: const InputDecoration(
                          hintText: '0,00',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontFamily: 'SpaceMono',
                            color: Color(0xFFBDBDBD),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Divider con swap ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Divider(height: 1, thickness: 0.5)),
                      GestureDetector(
                        onTap: onSwap,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_vert,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const Expanded(
                          child: Divider(height: 1, thickness: 0.5)),
                    ],
                  ),
                ),
                // ── Fila Bs (resultado) ──
                Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        isUsdInput ? 'Bs' : 'USD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? '0,00' : result,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SpaceMono',
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // 3.5. MONTOS RÁPIDOS
          // ═══════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              children: [5, 10, 20, 50, 100, 500].map((amount) {
                return GestureDetector(
                  onTap: () {
                    onQuickAmount(amount);
                  },
                  child: () {
                    final isSelected = selectedChip == amount;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE53935)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        '\$$amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SpaceMono',
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }(),
                );
              }).toList(),
            ),
          ),

          // ═══════════════════════════════════════════
          // 4. SECCIÓN "OTRAS MONEDAS"
          // ═══════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Text(
              'OTRAS MONEDAS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // 5. LISTA DE MONEDAS
          // ═══════════════════════════════════════════
          // EUR
          _CurrencyRow(
            emoji: '🇪🇺',
            name: 'Euro',
            source: 'BCV oficial',
            value: tasa.bcvEur,
            valueLabel: 'Bs ${tasa.bcvEur != null && tasa.bcvEur! > 0 ? Formatters.formatRate(tasa.bcvEur!) : '—'}',
          ),
          // USDT (opacidad reducida)
          _CurrencyRow(
            emoji: '⚡',
            name: 'USDT',
            source: 'P2P · referencia',
            value: tasa.usdtP2P,
            valueLabel: 'Bs ${tasa.usdtP2P > 0 ? Formatters.formatRate(tasa.usdtP2P) : '—'}',
            opacity: 0.65,
          ),
          // COP
          _CurrencyRow(
            emoji: '🇨🇴',
            name: 'Peso colombiano',
            source: 'BCV oficial',
            value: tasa.bcvCop,
            valueLabel: 'Bs ${tasa.bcvCop != null && tasa.bcvCop! > 0 ? Formatters.formatRate(tasa.bcvCop!) : '—'}',
          ),
          // BRL
          _CurrencyRow(
            emoji: '🇧🇷',
            name: 'Real brasileño',
            source: 'BCV oficial',
            value: tasa.bcvBrl,
            valueLabel: 'Bs ${tasa.bcvBrl != null && tasa.bcvBrl! > 0 ? Formatters.formatRate(tasa.bcvBrl!) : '—'}',
          ),

          // ═══════════════════════════════════════════
          // 5.5. MINI GRÁFICO HISTORIAL 7 DÍAS
          // ═══════════════════════════════════════════
          _MiniChart(historyAsync: historyAsync),

          // ═══════════════════════════════════════════
          // 6. AD BANNER
          // ═══════════════════════════════════════════
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            height: 52,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 14,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.25)),
                const SizedBox(width: 6),
                Text('Espacio publicitario',
                    style: TextStyle(fontSize: 10,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.25))),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // 7. BOTTOM SPACER
          // ═══════════════════════════════════════════
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CURRENCY ROW — estilo ListTile bancario
// ─────────────────────────────────────────────────────────────

class _CurrencyRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String source;
  final double? value;
  final String valueLabel;
  final double opacity;

  const _CurrencyRow({
    required this.emoji,
    required this.name,
    required this.source,
    required this.value,
    required this.valueLabel,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 2.5),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre + fuente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    source,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            // Valor
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceMono',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI CHART — gráfico de 7 días en Home
// ─────────────────────────────────────────────────────────────

class _MiniChart extends StatelessWidget {
  final AsyncValue<List<TasaHistoryEntry>> historyAsync;

  const _MiniChart({required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.length < 2) return const SizedBox.shrink();

        final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
        final spots = sorted.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.bcvUsd))
            .toList();

        final rates = sorted.map((e) => e.bcvUsd).toList();
        final minRate = rates.reduce(math.min);
        final maxRate = rates.reduce(math.max);
        final padding = (maxRate - minRate) * 0.15;

        // Determinar tendencia
        final first = sorted.first.bcvUsd;
        final last = sorted.last.bcvUsd;
        final isUp = last >= first;
        final pct = first > 0 ? ((last - first) / first * 100) : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TENDENCIA 7 DÍAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUp
                          ? const Color(0xFFE53935).withValues(alpha: 0.1)
                          : const Color(0xFF43A047).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isUp ? '▲' : '▼'} ${pct.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceMono',
                        color: isUp
                            ? const Color(0xFFE53935)
                            : const Color(0xFF43A047),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: LineChart(
                  LineChartData(
                    minY: minRate - padding,
                    maxY: maxRate + padding,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: isUp
                            ? const Color(0xFFE53935)
                            : const Color(0xFF43A047),
                        barWidth: 1.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, pct, bar, idx) {
                            if (idx != spots.length - 1) {
                              return FlDotCirclePainter(
                                  radius: 0, color: Colors.transparent);
                            }
                            return FlDotCirclePainter(
                              radius: 3,
                              color: isUp
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF43A047),
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              (isUp
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF43A047))
                                  .withValues(alpha: 0.12),
                              Colors.transparent,
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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _shortDate(sorted.first.date),
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    _shortDate(sorted.last.date),
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun',
        'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 56,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
