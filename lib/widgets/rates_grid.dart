import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/tasa_provider.dart';
import 'rate_mini_card.dart';

class RatesGrid extends ConsumerWidget {
  const RatesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasaAsync = ref.watch(tasaProvider);

    final tasa = tasaAsync.whenOrNull(data: (t) => t);

    String fmt(double? v) {
      if (v == null || v <= 0) return '—';
      return v.toStringAsFixed(2).replaceAll('.', ',');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 2.2,
        ),
        children: [
          RateMiniCard(
            name: 'EUR/BCV',
            value: tasa != null ? 'Bs ${fmt(tasa.bcvEur)}' : '—',
            isDiscrete: false,
          ),
          RateMiniCard(
            name: 'COP',
            value: tasa != null ? 'Bs ${fmt(tasa.bcvCop)}' : '—',
            isDiscrete: false,
          ),
          RateMiniCard(
            name: 'USDT',
            value: tasa != null ? 'Bs ${fmt(tasa.usdtP2P)}' : '—',
            isDiscrete: true,
          ),
          RateMiniCard(
            name: 'BRL',
            value: tasa != null ? 'Bs ${fmt(tasa.bcvBrl)}' : '—',
            isDiscrete: false,
          ),
        ],
      ),
    );
  }
}
