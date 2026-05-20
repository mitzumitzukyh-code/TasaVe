import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';
import '../providers/history_provider.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  String _input = '0';
  int _modeIndex = 0; // 0: $→Bs, 1: Bs→$, 2: Histórico
  int _sourceIndex = 0; // 0: BCV, 1: P2P, 2: Yadio

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _input = '0';
      } else if (key == '⌫') {
        _input = _input.length > 1 ? _input.substring(0, _input.length - 1) : '0';
      } else if (key == '.') {
        if (!_input.contains('.')) _input += '.';
      } else {
        if (_input == '0') {
          _input = key;
        } else {
          _input += key;
        }
      }
    });
  }

  double get _amount => double.tryParse(_input) ?? 0;

  @override
  Widget build(BuildContext context) {
    final tasa = ref.watch(tasaProvider).valueOrNull;
    final bcvRate = tasa?.bcvUsd ?? 0;
    final p2pRate = tasa?.usdtP2P ?? bcvRate;
    final yadioRate = tasa?.yadioRate ?? 0.0;

    double activeRate;
    String srcLabel;
    switch (_sourceIndex) {
      case 1: activeRate = p2pRate; srcLabel = 'P2P'; break;
      case 2: activeRate = yadioRate; srcLabel = 'Yadio'; break;
      default: activeRate = bcvRate; srcLabel = 'BCV'; break;
    }

    double result = 0;
    double p2pResult = 0;
    if (_modeIndex == 0) {
      result = _amount * activeRate;
      p2pResult = _amount * p2pRate;
    } else {
      result = activeRate > 0 ? _amount / activeRate : 0;
      p2pResult = p2pRate > 0 ? _amount / p2pRate : 0;
    }

    final diffBs = _modeIndex == 0 ? (p2pResult - result) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
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

            // ── Mode Tabs ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 13),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.s3,
                borderRadius: BorderRadius.circular(AppColors.r1),
              ),
              child: Row(
                children: [
                  _Tab(label: '\$ → Bs', active: _modeIndex == 0, onTap: () => setState(() => _modeIndex = 0)),
                  _Tab(label: 'Bs → \$', active: _modeIndex == 1, onTap: () => setState(() => _modeIndex = 1)),
                  _Tab(label: 'Histórico', active: _modeIndex == 2, onTap: () => setState(() => _modeIndex = 2)),
                ],
              ),
            ),

            // ── Content ──
            if (_modeIndex == 2)
              Expanded(child: _HistoricoView(ref: ref))
            else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 6, 13, 8),
                children: [
                  // Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.s3,
                      borderRadius: BorderRadius.circular(AppColors.r2),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _modeIndex == 0 ? 'USD' : 'Bs',
                          style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
                        ),
                        Expanded(
                          child: Text(
                            _input,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Result BCV
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.s2,
                      borderRadius: BorderRadius.circular(AppColors.r2),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TASA APLICADA · $srcLabel ${Formatters.formatRate(activeRate)}',
                          style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Formatters.formatCurrency(result),
                              style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.text),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _modeIndex == 0 ? 'Bs' : '\$',
                              style: GoogleFonts.spaceMono(fontSize: 13, color: AppColors.text2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // P2P Comparison (green card)
                  if (_sourceIndex != 1 && _modeIndex == 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.greenDim,
                        borderRadius: BorderRadius.circular(AppColors.r2),
                        border: Border.all(color: AppColors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CON USDT P2P · ${Formatters.formatRate(p2pRate)}',
                            style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.green),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.formatCurrency(p2pResult),
                                style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.green),
                              ),
                              const SizedBox(width: 3),
                              Text('Bs', style: GoogleFonts.spaceMono(fontSize: 13, color: AppColors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '▲ +${Formatters.formatCurrency(diffBs.abs())} Bs más usando P2P',
                            style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.green),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 5),

                  // Native Ad Slot
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.s1,
                      borderRadius: BorderRadius.circular(AppColors.r1),
                      border: Border.all(color: AppColors.border2, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('NATIVE SMALL', style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
                        Text('Entre resultados y teclado', style: GoogleFonts.spaceMono(fontSize: 7, color: AppColors.text4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Keypad (4 columns) — only in calculator modes ──
            if (_modeIndex != 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
                child: Column(
                  children: [
                    _buildRow(['7', '8', '9'], 'BCV'),
                    const SizedBox(height: 4),
                    _buildRow(['4', '5', '6'], 'P2P'),
                    const SizedBox(height: 4),
                    _buildRow(['1', '2', '3'], 'Yadio'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: _Key(label: '.', isFunc: true, onTap: () => _onKey('.'))),
                        const SizedBox(width: 4),
                        Expanded(child: _Key(label: '0', onTap: () => _onKey('0'))),
                        const SizedBox(width: 4),
                        Expanded(child: _Key(icon: Icons.backspace_outlined, isFunc: true, onTap: () => _onKey('⌫'))),
                        const SizedBox(width: 4),
                        Expanded(child: _Key(label: '=', isAction: true, onTap: () {
                          final text = _modeIndex == 0
                              ? '${Formatters.formatCurrency(result)} Bs'
                              : '\$${Formatters.formatCurrency(result)}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copiado: $text'),
                              backgroundColor: AppColors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        })),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> nums, String srcLabel) {
    final srcIdx = srcLabel == 'BCV' ? 0 : srcLabel == 'P2P' ? 1 : 2;
    return Row(
      children: [
        ...nums.map((n) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _Key(label: n, onTap: () => _onKey(n)),
          ),
        )),
        Expanded(
          child: _Key(
            label: srcLabel,
            isFunc: true,
            isActive: _sourceIndex == srcIdx,
            onTap: () => setState(() => _sourceIndex = srcIdx),
          ),
        ),
      ],
    );
  }
}

// ── Histórico View (real data from history provider) ──
class _HistoricoView extends StatelessWidget {
  final WidgetRef ref;
  const _HistoricoView({required this.ref});

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider(7));
    return historyAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text('Sin datos históricos disponibles',
              style: GoogleFonts.dmSans(color: AppColors.text3)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 8),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            final isUp = e.variation >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.s2,
                borderRadius: BorderRadius.circular(AppColors.r1),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.date.day}/${e.date.month}/${e.date.year}',
                          style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.text3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatRate(e.bcvUsd),
                          style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isUp ? "+" : ""}${e.variation.toStringAsFixed(2)} Bs',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: isUp ? AppColors.green : AppColors.red,
                        ),
                      ),
                      if (e.bcvEur > 0)
                        Text(
                          'EUR ${Formatters.formatRate(e.bcvEur)}',
                          style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.green)),
      error: (_, __) => Center(
        child: Text('Error cargando historial', style: GoogleFonts.dmSans(color: AppColors.red)),
      ),
    );
  }
}

// ── Tab ──
class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.s4 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 8, letterSpacing: 0.5,
              color: active ? AppColors.green : AppColors.text3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Keypad Key ──
class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isFunc;
  final bool isAction;
  final bool isActive;
  final VoidCallback onTap;

  const _Key({
    this.label,
    this.icon,
    this.isFunc = false,
    this.isAction = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.s3;
    Color fgColor = AppColors.text;

    if (isAction) {
      bgColor = AppColors.green;
      fgColor = const Color(0xFFFFFFFF);
    } else if (isFunc) {
      bgColor = AppColors.s3;
      fgColor = isActive ? AppColors.green : AppColors.text2;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppColors.r1),
          border: Border.all(color: isAction ? AppColors.green : AppColors.border),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 16, color: fgColor)
            : Text(
                label ?? '',
                style: isFunc
                    ? GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 0.5, color: fgColor)
                    : GoogleFonts.bebasNeue(fontSize: 18, color: fgColor),
              ),
      ),
    );
  }
}
