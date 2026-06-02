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
          data: (tasa) => _BankHome(
            tasa: tasa,
            controller: _controller,
            isUsdInput: _isUsdInput,
            result: _result,
            onSwap: _swap,
            onMaskChanged: _applyMask,
            historyAsync: ref.watch(historyProvider(2)),
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
  final AsyncValue<List<TasaHistoryEntry>> historyAsync;

  const _BankHome({
    required this.tasa,
    required this.controller,
    required this.isUsdInput,
    required this.result,
    required this.onSwap,
    required this.onMaskChanged,
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
                      width: 28,
                      child: Text(
                        'USD',
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
                      width: 28,
                      child: Text(
                        'Bs',
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
            icon: Icons.euro,
            name: 'Euro',
            source: 'BCV oficial',
            value: tasa.bcvEur,
            valueLabel: 'Bs ${tasa.bcvEur != null && tasa.bcvEur! > 0 ? Formatters.formatRate(tasa.bcvEur!) : '—'}',
          ),
          // USDT (opacidad reducida)
          _CurrencyRow(
            icon: Icons.currency_bitcoin,
            name: 'USDT',
            source: 'P2P · referencia',
            value: tasa.usdtP2P,
            valueLabel: 'Bs ${tasa.usdtP2P > 0 ? Formatters.formatRate(tasa.usdtP2P) : '—'}',
            opacity: 0.65,
          ),
          // COP
          _CurrencyRow(
            icon: Icons.attach_money,
            name: 'Peso colombiano',
            source: 'BCV oficial',
            value: tasa.bcvCop,
            valueLabel: 'Bs ${tasa.bcvCop != null && tasa.bcvCop! > 0 ? Formatters.formatRate(tasa.bcvCop!) : '—'}',
          ),
          // BRL
          _CurrencyRow(
            icon: Icons.monetization_on,
            name: 'Real brasileño',
            source: 'BCV oficial',
            value: tasa.bcvBrl,
            valueLabel: 'Bs ${tasa.bcvBrl != null && tasa.bcvBrl! > 0 ? Formatters.formatRate(tasa.bcvBrl!) : '—'}',
          ),

          // ═══════════════════════════════════════════
          // 6. AD BANNER
          // ═══════════════════════════════════════════
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
  final IconData icon;
  final String name;
  final String source;
  final double? value;
  final String valueLabel;
  final double opacity;

  const _CurrencyRow({
    required this.icon,
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
            // Icono
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
