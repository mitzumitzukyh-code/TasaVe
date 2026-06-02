import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class HeroRateCard extends StatelessWidget {
  final double rate;
  final double? change;
  final double buyRate;
  final double sellRate;

  const HeroRateCard({
    super.key,
    required this.rate,
    this.change,
    required this.buyRate,
    required this.sellRate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formatted = Formatters.formatRate(rate);
    final parts = formatted.split(',');
    final intPart = parts.isNotEmpty ? parts[0] : '0';
    final decPart = parts.length > 1 ? parts[1] : '00';

    String subtitle;
    if (change != null) {
      subtitle = 'Bs por 1 USD · ${change! >= 0 ? "▲" : "▼"} ${change!.abs().toStringAsFixed(2)}%';
    } else {
      subtitle = 'Bs por 1 USD';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.redLight,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: AppColors.surfaceDark3, width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'DÓLAR BCV',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textSecD : Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),

          // Número
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimD : Colors.white,
              ),
              children: [
                TextSpan(
                  text: intPart,
                  style: const TextStyle(
                    fontSize: 36,
                    letterSpacing: -2,
                  ),
                ),
                TextSpan(
                  text: ',$decPart',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? const Color(0xFF444444)
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Subtítulo
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? (change != null && change! > 0 ? AppColors.redDark : AppColors.textSecD)
                  : Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),

          // Spread row
          Row(
            children: [
              _SpreadPill(
                label: 'Compra',
                value: buyRate,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _SpreadPill(
                label: 'Venta',
                value: sellRate,
                isDark: isDark,
              ),
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
  final bool isDark;

  const _SpreadPill({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark2
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: isDark
            ? Border.all(color: AppColors.borderDark, width: 0.5)
            : null,
      ),
      child: Text(
        '$label: Bs ${Formatters.formatRate(value)}',
        style: TextStyle(
          fontSize: 9,
          color: isDark ? AppColors.textSecD : Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
