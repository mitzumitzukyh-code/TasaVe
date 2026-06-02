import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RateMiniCard extends StatelessWidget {
  final String name;
  final String value;
  final double? change;
  final bool isDiscrete;

  const RateMiniCard({
    super.key,
    required this.name,
    required this.value,
    this.change,
    this.isDiscrete = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isDiscrete ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(9),
          border: isDark
              ? Border.all(color: AppColors.borderDark, width: 0.5)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + optional badge
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? AppColors.textSecD : AppColors.textSecL,
                  ),
                ),
                if (isDiscrete) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'ref',
                      style: TextStyle(
                        fontSize: 7,
                        color: isDark ? AppColors.textSecD : AppColors.textSecL,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'SpaceMono',
                color: isDark ? AppColors.textPrimD : AppColors.textPrimL,
              ),
            ),
            const SizedBox(height: 2),
            // Change
            if (change != null) ...[
              Builder(
                builder: (context) {
                  if (isDiscrete) {
                    return Text(
                      'P2P ref.',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? AppColors.textSecD : AppColors.textSecL,
                      ),
                    );
                  }
                  if (change! > 0) {
                    return Text(
                      '▲ ${change!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? AppColors.greenDark : AppColors.greenLight,
                      ),
                    );
                  }
                  if (change! < 0) {
                    return Text(
                      '▼ ${change!.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? AppColors.redDark : AppColors.redLight,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
