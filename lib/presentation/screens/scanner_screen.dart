import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = TextEditingController();

  // ── Máscara financiera (misma lógica del home) ──────────

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

  void _clear() {
    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasaAsync = ref.watch(tasaProvider);
    final tasa = tasaAsync.whenOrNull(data: (t) => t);

    final inputValue = _parseMasked(_controller.text);
    final active = inputValue > 0 && tasa != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
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
                      'Escáner',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Estado ACTIVO ───────────────────────────────
              if (active) ...[
                _ActiveView(
                  bsAmount: inputValue,
                  tasa: tasa,
                  onScanAgain: _clear,
                ),
              ] else ...[
                // ── Estado REPOSO ─────────────────────────────
                _IdleView(
                  controller: _controller,
                  onMaskChanged: _applyMask,
                  isWeb: kIsWeb,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADO REPOSO
// ─────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final TextEditingController controller;
  final String Function(String) onMaskChanged;
  final bool isWeb;

  const _IdleView({
    required this.controller,
    required this.onMaskChanged,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('📸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Apunta la cámara a un precio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detectamos el monto en Bs y lo convertimos\na USD, EUR y USDT al instante',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // En web: scroll hacia el campo manual
                // En móvil: stub para cámara futura
              },
              icon: const Text('📷', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Escanear precio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'También puedes ingresar\nel monto manualmente',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'SpaceMono',
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0,00',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                fontFamily: 'SpaceMono',
              ),
              prefixText: 'Bs ',
              prefixStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE53935),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADO ACTIVO
// ─────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final double bsAmount;
  final dynamic tasa;
  final VoidCallback onScanAgain;

  const _ActiveView({
    required this.bsAmount,
    required this.tasa,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final usdAmount = tasa.bcvUsd > 0 ? bsAmount / tasa.bcvUsd : 0.0;
    final eurAmount = tasa.bcvEur != null && tasa.bcvEur > 0
        ? bsAmount / tasa.bcvEur
        : 0.0;
    final usdtAmount = tasa.usdtP2P > 0 ? bsAmount / tasa.usdtP2P : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Precio detectado ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                const Text('🏷️', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'Bs ${Formatters.formatRate(bsAmount)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Precio detectado',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Card USD ──────────────────────────────────────
          _ResultCard(
            emoji: '🇺🇸',
            label: 'USD · BCV oficial',
            value: '\$ ${Formatters.formatRate(usdAmount)}',
            isPrimary: true,
          ),

          const SizedBox(height: 8),

          // ── Card EUR ──────────────────────────────────────
          _ResultCard(
            emoji: '🇪🇺',
            label: 'EUR · BCV oficial',
            value: eurAmount > 0
                ? '€ ${Formatters.formatRate(eurAmount)}'
                : 'N/D',
          ),

          const SizedBox(height: 8),

          // ── Card USDT ─────────────────────────────────────
          _ResultCard(
            emoji: '⚡',
            label: 'USDT · P2P referencia',
            value: usdtAmount > 0
                ? '≈ \$ ${Formatters.formatRate(usdtAmount)}'
                : 'N/D',
            opacity: 0.7,
            badge: 'ref',
          ),

          const SizedBox(height: 20),

          // ── Botón escanear otro ───────────────────────────
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onScanAgain,
              icon: const Text('🔄', style: TextStyle(fontSize: 16)),
              label: Text(
                'Escanear otro precio',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESULT CARD
// ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool isPrimary;
  final double opacity;
  final String? badge;

  const _ResultCard({
    required this.emoji,
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.opacity = 1.0,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                      color: isPrimary
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
