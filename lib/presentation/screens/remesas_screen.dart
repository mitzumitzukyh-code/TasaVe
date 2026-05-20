import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';

class RemesasScreen extends ConsumerStatefulWidget {
  const RemesasScreen({super.key});

  @override
  ConsumerState<RemesasScreen> createState() => _RemesasScreenState();
}

class _RemesasScreenState extends ConsumerState<RemesasScreen> {
  final TextEditingController _controller = TextEditingController(text: '200');
  String _input = '200';
  int _platformIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fees reales documentados de cada plataforma (mayo 2024)
  // fee: comisión sobre el monto enviado (0.0 = sin comisión)
  // spread: % que la plataforma cobra sobre la tasa paralelo (negativo = peor tasa)
  static const _platforms = [
    {'name': 'Zinli', 'fee': 0.025, 'spread': -0.005, 'note': 'Comisión 2.5%'},
    {'name': 'Zelle', 'fee': 0.0, 'spread': -0.01, 'note': 'Sin comisión, spread de cambio'},
    {'name': 'Binance P2P', 'fee': 0.0, 'spread': 0.0, 'note': '0% fee, tasa P2P directa'},
    {'name': 'Reserve', 'fee': 0.02, 'spread': -0.008, 'note': 'Comisión 2%'},
    {'name': 'PayPal', 'fee': 0.055, 'spread': -0.04, 'note': 'Fee 5.5% + peor tasa'},
  ];

  double get _amount => double.tryParse(_input) ?? 0;

  @override
  Widget build(BuildContext context) {
    final tasaAsync = ref.watch(tasaProvider);
    final tasa = tasaAsync.valueOrNull;
    final bcvRate = tasa?.bcvUsd ?? 0;
    final p2pRate = tasa?.usdtP2P ?? bcvRate;

    final platform = _platforms[_platformIndex];
    final fee = (platform['fee'] as double) * _amount;
    final neto = _amount - fee;
    final platformRate = p2pRate * (1 + (platform['spread'] as double));
    final arrives = neto * platformRate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2),
                  children: const [
                    TextSpan(text: 'TASA', style: TextStyle(color: AppColors.text)),
                    TextSpan(text: 'VE', style: TextStyle(color: AppColors.green)),
                  ],
                ),
              ),
            ),

            // Diaspora card header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 13),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.s2,
                borderRadius: BorderRadius.circular(AppColors.r2),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MODO DIÁSPORA', style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
                  const SizedBox(height: 3),
                  Text('Enviar desde el exterior', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
                  Text('Compara cuánto llega según plataforma', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text2)),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Input ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 13),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.s3,
                borderRadius: BorderRadius.circular(AppColors.r2),
                border: Border.all(color: AppColors.border2),
              ),
              child: Row(
                children: [
                  Text('USD', style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _input = v),
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Platform Chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLATAFORMA', style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: List.generate(_platforms.length, (i) {
                      final active = i == _platformIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _platformIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? AppColors.greenDim : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: active ? AppColors.green : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _platforms[i]['name'] as String,
                            style: GoogleFonts.spaceMono(
                              fontSize: 8, letterSpacing: 0.5,
                              color: active ? AppColors.green : AppColors.text3,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Breakdown ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 13),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.s2,
                borderRadius: BorderRadius.circular(AppColors.r2),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ResultRow(label: 'Monto enviado', value: '\$${Formatters.formatCurrency(_amount)}'),
                  _ResultRow(
                    label: 'Comisión ${platform["name"]} (−${((platform["fee"] as double) * 100).toStringAsFixed(1)}%)',
                    value: '−\$${Formatters.formatCurrency(fee)}',
                    valueColor: AppColors.red,
                  ),
                  _ResultRow(label: 'Neto efectivo', value: '\$${Formatters.formatCurrency(neto)}'),
                  _ResultRow(label: 'Tasa Zinli estimada', value: '${Formatters.formatRate(platformRate)} Bs/\$'),
                  _ResultRow(
                    label: 'Llega en Venezuela',
                    value: '${Formatters.formatCurrency(arrives)} Bs',
                    valueColor: AppColors.green,
                    isHighlight: true,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 5),
            // ── Comparativa Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 5),
              child: Text(
                'COMPARATIVA · \$${_amount.toStringAsFixed(0)}',
                style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
              ),
            ),
            // ── Comparison table ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppColors.r2),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _platforms.asMap().entries.map((entry) {
                  final p = entry.value;
                  final pFee = (p['fee'] as double) * _amount;
                  final pNeto = _amount - pFee;
                  final pRate = p2pRate * (1 + (p['spread'] as double));
                  final pArrives = pNeto * pRate;
                  final isBest = entry.key == _getBestPlatformIndex(p2pRate);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: isBest ? AppColors.greenDim : Colors.transparent,
                      border: entry.key < _platforms.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p["name"]}${isBest ? " ★" : ""}',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: isBest ? AppColors.green : AppColors.text2,
                          ),
                        ),
                        Text(
                          '${Formatters.formatCurrency(pArrives)} Bs',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            color: isBest ? AppColors.green : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getBestPlatformIndex(double p2pRate) {
    double best = 0;
    int bestIdx = 0;
    for (var i = 0; i < _platforms.length; i++) {
      final p = _platforms[i];
      final fee = (p['fee'] as double) * _amount;
      final neto = _amount - fee;
      final rate = p2pRate * (1 + (p['spread'] as double));
      final arrives = neto * rate;
      if (arrives > best) {
        best = arrives;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isHighlight;
  final bool isLast;

  const _ResultRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHighlight = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text3)),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: isHighlight ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
