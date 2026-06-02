import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // ── Máscara financiera (Regla 12 CLAUDE.md) ─────────────

  String _applyMask(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final value = int.parse(digits);
    final integer = value ~/ 100;
    final decimal = (value % 100).toString().padLeft(2, '0');
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

    final converted = _isUsdInput ? input * rate : input / rate;
    _result = Formatters.formatRate(converted);
  }

  void _swap() {
    final currentText = _controller.text;
    _isUsdInput = !_isUsdInput;
    _controller.text = '';
    _result = '0,00';
    if (currentText.isNotEmpty) {
      _controller.text = currentText;
    }
  }

  // ── Lifecycle ───────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
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
          data: (tasa) {
            final historyAsync = ref.watch(historyProvider(2));
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
            return _HomeContent(
              tasa: tasa,
              change: change,
              controller: _controller,
              isUsdInput: _isUsdInput,
              result: _result,
              onSwap: _swap,
              onMaskChanged: _applyMask,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME CONTENT
// ─────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final TasaModel tasa;
  final double? change;
  final TextEditingController controller;
  final bool isUsdInput;
  final String result;
  final VoidCallback onSwap;
  final String Function(String) onMaskChanged;

  const _HomeContent({
    required this.tasa,
    this.change,
    required this.controller,
    required this.isUsdInput,
    required this.result,
    required this.onSwap,
    required this.onMaskChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final diff = DateTime.now().difference(tasa.timestamp);
    final timeAgo = diff.inMinutes < 1
        ? 'ahora'
        : diff.inMinutes < 60
            ? 'hace ${diff.inMinutes} min'
            : 'hace ${diff.inHours}h';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tasave',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'BCV · $timeAgo',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // 2. HeroCard
          _HeroCard(
            rate: tasa.bcvUsd,
            change: change,
            buyRate: tasa.bcvUsd - 0.13,
            sellRate: tasa.bcvUsd + 0.13,
          ),

          // 3. SectionLabel
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 4),
            child: Text(
              'Calculadora rápida',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // 4. QuickCalculator
          _QuickCalc(
            controller: controller,
            isUsdInput: isUsdInput,
            result: result,
            onSwap: onSwap,
            onMaskChanged: onMaskChanged,
          ),

          // 5. SectionLabel
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 4),
            child: Text(
              'Otras monedas',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // 6. RatesGrid
          _RatesGrid(tasa: tasa),

          // 7. AdBanner
          Container(
            height: 52,
            color: theme.cardColor,
            alignment: Alignment.center,
            child: Text(
              'Publicidad',
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUICK CALCULATOR (máscara financiera — Regla 12)
// ─────────────────────────────────────────────────────────────

class _QuickCalc extends StatelessWidget {
  final TextEditingController controller;
  final bool isUsdInput;
  final String result;
  final VoidCallback onSwap;
  final String Function(String) onMaskChanged;

  const _QuickCalc({
    required this.controller,
    required this.isUsdInput,
    required this.result,
    required this.onSwap,
    required this.onMaskChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Fila input
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  isUsdInput ? 'USD' : 'Bs',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(child: Divider(height: 0.5, thickness: 0.5)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSwap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider(height: 0.5, thickness: 0.5)),
              ],
            ),
          ),
          // Fila resultado
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  isUsdInput ? 'Bs' : 'USD',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.text.isEmpty ? '0,00' : result,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double rate;
  final double? change;
  final double buyRate;
  final double sellRate;

  const _HeroCard({
    required this.rate,
    this.change,
    required this.buyRate,
    required this.sellRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formatted = Formatters.formatRate(rate);
    final parts = formatted.split(',');
    final intPart = parts.isNotEmpty ? parts[0] : '0';
    final decPart = parts.length > 1 ? parts[1] : '00';

    final String subtitle;
    if (change != null) {
      subtitle = 'Bs por 1 USD · ${change! >= 0 ? "▲" : "▼"} ${change!.abs().toStringAsFixed(2)}%';
    } else {
      subtitle = 'Bs por 1 USD';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DÓLAR BCV',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w500,
                color: isDark ? theme.colorScheme.onSurface : Colors.white,
              ),
              children: [
                TextSpan(
                  text: intPart,
                  style: const TextStyle(fontSize: 36, letterSpacing: -2),
                ),
                TextSpan(
                  text: ',$decPart',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? (change != null && change! > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3))
                  : Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SpreadPill(label: 'Compra', value: buyRate, theme: theme, isDark: isDark),
              const SizedBox(width: 6),
              _SpreadPill(label: 'Venta', value: sellRate, theme: theme, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpreadPill extends StatelessWidget {
  final String label;
  final double value;
  final ThemeData theme;
  final bool isDark;

  const _SpreadPill({
    required this.label,
    required this.value,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: isDark
            ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))
            : null,
      ),
      child: Text(
        '$label: Bs ${Formatters.formatRate(value)}',
        style: TextStyle(
          fontSize: 9,
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RATES GRID
// ─────────────────────────────────────────────────────────────

class _RatesGrid extends StatelessWidget {
  final TasaModel tasa;
  const _RatesGrid({required this.tasa});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 2.6,
        ),
        children: [
          _RateCard(name: 'EUR/BCV', value: tasa.bcvEur, theme: theme, isDark: isDark),
          _RateCard(name: 'COP', value: tasa.bcvCop, theme: theme, isDark: isDark),
          _RateCard(name: 'USDT', value: tasa.usdtP2P, theme: theme, isDark: isDark),
          _RateCard(name: 'BRL', value: tasa.bcvBrl, theme: theme, isDark: isDark),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String name;
  final double? value;
  final ThemeData theme;
  final bool isDark;

  const _RateCard({
    required this.name,
    required this.value,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = value != null && value! > 0;

    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(9),
        border: isDark
            ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasData ? 'Bs ${Formatters.formatRate(value!)}' : 'N/D',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
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
            Icon(Icons.cloud_off, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
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
