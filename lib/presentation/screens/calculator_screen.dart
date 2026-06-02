import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/converter_direction_provider.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasaAsync = ref.watch(tasaProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: tasaAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => Center(
            child: Text('Sin datos', style: GoogleFonts.dmSans(color: AppColors.text3)),
          ),
          data: (tasa) => _CalculatorBody(bcvUsd: tasa.bcvUsd),
        ),
      ),
    );
  }
}

class _CalculatorBody extends ConsumerWidget {
  final double bcvUsd;
  const _CalculatorBody({required this.bcvUsd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawCents = ref.watch(calculatorRawCentsProvider);
    final amount = ref.watch(calculatorAmountProvider);
    final direction = ref.watch(conversionDirectionProvider);
    final taxMode = ref.watch(taxModeProvider);
    final isUsdToBs = direction == ConversionDirection.usdToBs;

    // Calculate result
    double resultBase;
    if (isUsdToBs) {
      resultBase = amount * bcvUsd;
    } else {
      resultBase = bcvUsd > 0 ? amount / bcvUsd : 0;
    }

    // Apply tax
    double taxMultiplier = 1.0;
    if (taxMode == TaxMode.iva) taxMultiplier = 1 + AppConstants.IVA;
    if (taxMode == TaxMode.igtf) taxMultiplier = 1 + AppConstants.IGTF;
    final result = resultBase * taxMultiplier;

    final resultCurrency = isUsdToBs ? 'BOLÍVARES' : 'DÓLARES';
    final inputPrefix = isUsdToBs ? '\$ ' : 'Bs ';
    final directionLabel = isUsdToBs ? 'USD→Bs' : 'Bs→USD';
    final resultColor = isUsdToBs ? AppColors.success : AppColors.primary;

    // Format input display
    final inputAmount = int.parse(rawCents) / 100.0;
    final inputDisplay = '$inputPrefix${Formatters.formatCurrency(inputAmount)}';

    return Column(
      children: [
        // 2.1 Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tasa',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    TextSpan(
                      text: 'Ve',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Sin anuncios',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3),
              ),
            ],
          ),
        ),

        // 2.2 Input display (dark)
        Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.kDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INGRESA MONTO',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.text3,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                inputDisplay,
                style: GoogleFonts.spaceMono(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '← dígitos fluyen de derecha a izquierda',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),

        // 2.3 Result display
        Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESULTADO EN $resultCurrency',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text3,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isUsdToBs
                    ? 'Bs ${Formatters.formatCurrency(result)}'
                    : '\$ ${Formatters.formatCurrency(result)}',
                style: GoogleFonts.spaceMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tasa BCV · 1 USD = ${Formatters.formatRate(bcvUsd)} Bs',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text3),
              ),
            ],
          ),
        ),

        // 2.4 Tax buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Row(
            children: [
              _TaxButton(
                label: 'Sin impuesto',
                isActive: taxMode == TaxMode.none,
                onTap: () => ref.read(taxModeProvider.notifier).state = TaxMode.none,
              ),
              const SizedBox(width: 6),
              _TaxButton(
                label: '+ IVA 16%',
                isActive: taxMode == TaxMode.iva,
                onTap: () => ref.read(taxModeProvider.notifier).state = TaxMode.iva,
              ),
              const SizedBox(width: 6),
              _TaxButton(
                label: '+ IGTF 3%',
                isActive: taxMode == TaxMode.igtf,
                onTap: () => ref.read(taxModeProvider.notifier).state = TaxMode.igtf,
              ),
            ],
          ),
        ),

        // 2.5 Numpad
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: _NumPad(
              directionLabel: directionLabel,
              onDigit: (d) {
                final current = ref.read(calculatorRawCentsProvider);
                if (current.length < 12) {
                  final newVal = current + d;
                  ref.read(calculatorRawCentsProvider.notifier).state = newVal;
                }
              },
              onClear: () {
                ref.read(calculatorRawCentsProvider.notifier).state = '000';
              },
              onBackspace: () {
                final current = ref.read(calculatorRawCentsProvider);
                if (current.length > 1) {
                  final newVal = '0${current.substring(0, current.length - 1)}';
                  ref.read(calculatorRawCentsProvider.notifier).state = newVal;
                } else {
                  ref.read(calculatorRawCentsProvider.notifier).state = '000';
                }
              },
              onSwap: () {
                final dir = ref.read(conversionDirectionProvider);
                ref.read(conversionDirectionProvider.notifier).state =
                    dir == ConversionDirection.usdToBs
                        ? ConversionDirection.bsToUsd
                        : ConversionDirection.usdToBs;
              },
              onDot: () {
                // No-op: decimal is handled by the right-to-left digit flow
              },
              isUsdToBs: isUsdToBs,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAX BUTTON
// ─────────────────────────────────────────────────────────────

class _TaxButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TaxButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLgt : AppColors.bg,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NUMPAD
// ─────────────────────────────────────────────────────────────

class _NumPad extends StatelessWidget {
  final String directionLabel;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onSwap;
  final VoidCallback onDot;
  final bool isUsdToBs;

  const _NumPad({
    required this.directionLabel,
    required this.onDigit,
    required this.onClear,
    required this.onBackspace,
    required this.onSwap,
    required this.onDot,
    required this.isUsdToBs,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 6.0;
        final cols = 4;
        final rows = 5;
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final cellW = (totalWidth - (cols - 1) * gap) / cols;
        final cellH = (totalHeight - (rows - 1) * gap) / rows;

        Widget btn(String text, {Color? bg, Color? fg, VoidCallback? onTap, int colSpan = 1}) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: cellW * colSpan + gap * (colSpan - 1),
              height: cellH,
              decoration: BoxDecoration(
                color: bg ?? AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  text,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg ?? AppColors.text,
                  ),
                ),
              ),
            ),
          );
        }

        Widget iconBtn(IconData icon, {Color? bg, Color? fg, VoidCallback? onTap}) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: cellW,
              height: cellH,
              decoration: BoxDecoration(
                color: bg ?? AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: fg ?? AppColors.text),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Row 1: C, ←, ↑↓, USD→Bs
            Row(
              children: [
                btn('C', bg: AppColors.surface2, onTap: onClear),
                SizedBox(width: gap),
                iconBtn(Icons.backspace_outlined, bg: AppColors.surface2, onTap: onBackspace),
                SizedBox(width: gap),
                iconBtn(Icons.swap_vert, bg: AppColors.primaryLgt, fg: AppColors.primary, onTap: onSwap),
                SizedBox(width: gap),
                GestureDetector(
                  onTap: onSwap,
                  child: Container(
                    width: cellW,
                    height: cellH,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        directionLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            // Row 2: 7 8 9 (empty)
            Row(
              children: [
                btn('7', onTap: () => onDigit('7')),
                SizedBox(width: gap),
                btn('8', onTap: () => onDigit('8')),
                SizedBox(width: gap),
                btn('9', onTap: () => onDigit('9')),
                SizedBox(width: gap),
                // ✓ button spans rows 2-3
                GestureDetector(
                  onTap: () {}, // Result is real-time, no action needed
                  child: Container(
                    width: cellW,
                    height: cellH * 2 + gap,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '✓',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            // Row 3: 4 5 6
            Row(
              children: [
                btn('4', onTap: () => onDigit('4')),
                SizedBox(width: gap),
                btn('5', onTap: () => onDigit('5')),
                SizedBox(width: gap),
                btn('6', onTap: () => onDigit('6')),
                // ✓ button already occupies this space
                SizedBox(width: gap + cellW),
              ],
            ),
            SizedBox(height: gap),
            // Row 4: 1 2 3
            Row(
              children: [
                btn('1', onTap: () => onDigit('1')),
                SizedBox(width: gap),
                btn('2', onTap: () => onDigit('2')),
                SizedBox(width: gap),
                btn('3', onTap: () => onDigit('3')),
                SizedBox(width: gap + cellW),
              ],
            ),
            SizedBox(height: gap),
            // Row 5: 0(wide) .
            Row(
              children: [
                btn('0', onTap: () => onDigit('0'), colSpan: 2),
                SizedBox(width: gap),
                btn('.', onTap: onDot),
                SizedBox(width: gap + cellW),
              ],
            ),
          ],
        );
      },
    );
  }
}
