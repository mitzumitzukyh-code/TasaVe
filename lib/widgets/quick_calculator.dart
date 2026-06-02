import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/tasa_provider.dart';
import '../utils/formatters.dart';

class QuickCalculator extends ConsumerStatefulWidget {
  const QuickCalculator({super.key});

  @override
  ConsumerState<QuickCalculator> createState() => _QuickCalculatorState();
}

class _QuickCalculatorState extends ConsumerState<QuickCalculator> {
  final _controller = TextEditingController();

  double _parseInput(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    return parsed ?? 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasaAsync = ref.watch(tasaProvider);

    final rate = tasaAsync.whenOrNull(data: (t) => t.bcvUsd) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Fila USD
          Row(
            children: [
              Text(
                'USD',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecD : AppColors.textSecL,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SpaceMono',
                    color: isDark ? AppColors.textPrimD : AppColors.textPrimL,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          // Fila Bs
          Row(
            children: [
              Text(
                'Bs',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecD : AppColors.textSecL,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _controller.text.isEmpty
                      ? '0,00'
                      : Formatters.formatRate(_parseInput(_controller.text) * rate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SpaceMono',
                    color: isDark ? AppColors.greenDark : AppColors.greenLight,
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
