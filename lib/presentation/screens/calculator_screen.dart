import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';
import '../state/calculator_provider.dart';
import '../widgets/invoice_scanner_view.dart';

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  static const _shadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final calc = ref.watch(calculatorProvider);
    final tasa = ref.watch(tasaProvider).valueOrNull;
    final bcvRate = tasa?.bcvUsd ?? 0;
    final activeRate = bcvRate;
    const srcLabel = 'BCV';

    final subtotal  = calc.subtotal(activeRate);

    final resultUnit = calc.isUsd ? 'Bs' : '\$';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Calculadora',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  children: [
                    // ── Input card (Red background with white text like TasaVe) ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [_shadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => ref.read(calculatorProvider.notifier).toggleDirection(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    calc.isUsd ? 'USD → Bs' : 'Bs → USD',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  calc.montoDisplay,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 32, height: 1, fontWeight: FontWeight.w900, color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ── Botón escáner OCR ──
                              if (!kIsWeb)
                                GestureDetector(
                                  onTap: () async {
                                    final monto = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InvoiceScannerView(),
                                      ),
                                    );
                                    if (monto != null && monto.isNotEmpty) {
                                      ref.read(calculatorProvider.notifier).setInput(monto);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            calc.isUsd ? 'Ingresa monto en USD' : 'Ingresa monto en Bs',
                            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white70),
                          ),
                          if (activeRate > 0 && calc.monto > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              '= ${Formatters.formatCurrency(subtotal)} ${calc.isUsd ? "Bs" : "\$"}',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Resultado principal ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [_shadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TASA APLICADA · $srcLabel ${Formatters.formatRate(activeRate)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11, letterSpacing: 1.2, color: AppColors.text3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.formatCurrency(subtotal),
                                style: GoogleFonts.dmSans(
                                  fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                resultUnit,
                                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Teclado numérico ──
            _Keypad(
                onKey: (k) => ref.read(calculatorProvider.notifier).onKey(k),
                onCopy: () {
                  final text = '${Formatters.formatCurrency(subtotal)} $resultUnit';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Copiado: $text'),
                    backgroundColor: AppColors.green,
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KEYPAD
// ─────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onCopy;
  const _Keypad({required this.onKey, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          _kRow(['7', '8', '9', '⌫'], onKey),
          const SizedBox(height: 5),
          _kRow(['4', '5', '6', 'C'], onKey),
          const SizedBox(height: 5),
          _kRow(['1', '2', '3', '00'], onKey),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _Key(label: '0', onTap: () => onKey('0')),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _Key(
                  icon: Icons.copy_rounded,
                  isAction: true,
                  onTap: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kRow(List<String> keys, void Function(String) fn) {
    return Row(
      children: keys.asMap().entries.map((e) {
        final k = e.value;
        final isFunc = k == '⌫' || k == 'C';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 5),
            child: k == '⌫'
                ? _Key(icon: Icons.backspace_outlined, isFunc: true, onTap: () => fn(k))
                : _Key(label: k, isFunc: isFunc, onTap: () => fn(k)),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// KEY WIDGET
// ─────────────────────────────────────────────
class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isFunc;
  final bool isAction;
  final VoidCallback onTap;

  const _Key({
    this.label,
    this.icon,
    this.isFunc = false,
    this.isAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    if (isAction) {
      bgColor = AppColors.green;
      fgColor = Colors.white;
    } else if (isFunc) {
      bgColor = AppColors.bg;
      fgColor = AppColors.text2;
    } else {
      bgColor = AppColors.surface;
      fgColor = AppColors.text;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isAction ? AppColors.green : AppColors.border),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 16, color: fgColor)
            : Text(
                label ?? '',
                style: isFunc
                    ? GoogleFonts.dmSans(fontSize: 11, color: fgColor)
                    : GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: fgColor,
                      ),
              ),
      ),
    );
  }
}

