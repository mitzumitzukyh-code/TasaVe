import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import '../../utils/formatters.dart';
import '../providers/tasa_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/shell_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasaAsync = ref.watch(tasaProvider);
    final userPlan = ref.watch(userPlanProvider);
    final variation = ref.watch(variationProvider).valueOrNull ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () => ref.read(tasaProvider.notifier).refresh(),
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 20,
          ),
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2),
                      children: const [
                        TextSpan(text: 'TASA', style: TextStyle(color: AppColors.text)),
                        TextSpan(text: 'VE', style: TextStyle(color: AppColors.green)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _CircleBtn(icon: Icons.notifications_none_rounded, onTap: () {
                    ref.read(shellTabProvider.notifier).state = 5; // Alertas
                  }),
                  const SizedBox(width: 7),
                  _CircleBtn(icon: Icons.settings_outlined, onTap: () {
                    _showSettingsSheet(context, ref);
                  }),
                ],
              ),
            ),

            // ── Banner Ad TOP (solo free) ──
            if (userPlan == 'free') _AdBannerSlot(),

            // ── Main BCV Card ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 0),
              child: tasaAsync.when(
                data: (tasa) => _MainCard(
                  rate: tasa.bcvUsd,
                  variation: variation,
                  timestamp: tasa.timestamp,
                  isFromCache: tasa.isFromCache,
                  bcvStatus: tasa.bcvStatus,
                ),
                loading: () => _MainCard(rate: 0, variation: 0, isLoading: true),
                error: (_, __) => _MainCard(rate: 0, variation: 0, isError: true),
              ),
            ),

            // ── Mini Grid (4 cards) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 7, 13, 0),
              child: tasaAsync.when(
                data: (tasa) => _MiniGrid(
                  p2p: tasa.usdtP2P ?? 0,
                  yadio: tasa.yadioRate ?? 0,
                  eurBcv: tasa.bcvEur,
                  bcvUsd: tasa.bcvUsd,
                  variation: variation,
                ),
                loading: () => _MiniGrid(p2p: 0, yadio: 0, eurBcv: 0, bcvUsd: 0, variation: 0, loading: true),
                error: (_, __) => _MiniGrid(p2p: 0, yadio: 0, eurBcv: 0, bcvUsd: 0, variation: 0),
              ),
            ),

            // ── Otras monedas BCV ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 7, 13, 0),
              child: tasaAsync.when(
                data: (tasa) {
                  final extras = <_CurrencyRow>[];
                  if (tasa.bcvCop != null && tasa.bcvCop! > 0)
                    extras.add(_CurrencyRow(code: 'COP', name: 'Peso colombiano', value: tasa.bcvCop!));
                  if (tasa.bcvBrl != null && tasa.bcvBrl! > 0)
                    extras.add(_CurrencyRow(code: 'BRL', name: 'Real brasileño', value: tasa.bcvBrl!));
                  if (tasa.bcvCny != null && tasa.bcvCny! > 0)
                    extras.add(_CurrencyRow(code: 'CNY', name: 'Yuan chino', value: tasa.bcvCny!));
                  if (tasa.bcvTry != null && tasa.bcvTry! > 0)
                    extras.add(_CurrencyRow(code: 'TRY', name: 'Lira turca', value: tasa.bcvTry!));
                  if (tasa.bcvRub != null && tasa.bcvRub! > 0)
                    extras.add(_CurrencyRow(code: 'RUB', name: 'Rublo ruso', value: tasa.bcvRub!));
                  if (extras.isEmpty) return const SizedBox.shrink();
                  return _OtrasMonedas(rows: extras);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Spread BCV vs Paralelo ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 7, 13, 0),
              child: tasaAsync.when(
                data: (tasa) {
                  final sp = tasa.usdtP2P != null && tasa.bcvUsd > 0
                      ? ((tasa.usdtP2P! - tasa.bcvUsd) / tasa.bcvUsd * 100)
                      : 0.0;
                  return _SpreadRow(spread: sp);
                },
                loading: () => _SpreadRow(spread: 0),
                error: (_, __) => _SpreadRow(spread: 0),
              ),
            ),

            // ── Alert Row (dynamic) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 0),
              child: tasaAsync.when(
                data: (tasa) => _AlertRow(spread: tasa.spreadPercent, status: tasa.bcvStatus),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final plan = ref.read(userPlanProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.s2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('AJUSTES',
                style: GoogleFonts.spaceMono(fontSize: 10, letterSpacing: 2, color: AppColors.text3)),
              const SizedBox(height: 14),
              // Accessible mode
              StatefulBuilder(
                builder: (ctx, setLocal) {
                  var val = ref.read(accessibilityProvider);
                  return _SettingsTile(
                    label: 'Modo accesible',
                    subtitle: val ? 'Fuente grande activada' : 'Tamaño normal',
                    trailing: GestureDetector(
                      onTap: () {
                        ref.read(accessibilityProvider.notifier).toggle();
                        setLocal(() {});
                      },
                      child: _Toggle(isOn: val, color: AppColors.green),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              // Plan
              _SettingsTile(
                label: 'Plan actual',
                subtitle: plan == 'premium' ? 'Premium activo' : 'Versión gratuita',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan == 'premium' ? AppColors.greenDim : AppColors.s4,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    plan == 'premium' ? 'PRO' : 'FREE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8, letterSpacing: 1,
                      color: plan == 'premium' ? AppColors.green : AppColors.text3,
                    ),
                  ),
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              // App version
              _SettingsTile(
                label: 'Versión',
                subtitle: 'TasaVe v1.0.0',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Tile ──
class _SettingsTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget trailing;
  const _SettingsTile({required this.label, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── Toggle mini ──
class _Toggle extends StatelessWidget {
  final bool isOn;
  final Color color;
  const _Toggle({required this.isOn, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 20,
      decoration: BoxDecoration(
        color: isOn ? color : AppColors.s4,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16, height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Circle Button ──
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.s3,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.text2),
      ),
    );
  }
}

// ── Main BCV Rate Card ──
class _MainCard extends StatelessWidget {
  final double rate;
  final double variation;
  final DateTime? timestamp;
  final bool isFromCache;
  final bool isLoading;
  final bool isError;
  final String? bcvStatus;

  const _MainCard({
    required this.rate,
    required this.variation,
    this.timestamp,
    this.isFromCache = false,
    this.isLoading = false,
    this.isError = false,
    this.bcvStatus,
  });

  @override
  Widget build(BuildContext context) {
    final pct = rate > 0 ? (variation / rate * 100) : 0.0;
    final isUp = variation >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(AppColors.r3),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live indicator
                Row(
                  children: [
                    _LiveDot(),
                    const SizedBox(width: 5),
                    Text(
                      'BCV OFICIAL',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8, letterSpacing: 2, color: AppColors.green,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenDim,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFromCache ? 'CACHÉ' : 'EN VIVO',
                        style: GoogleFonts.spaceMono(
                          fontSize: 7, letterSpacing: 1, color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'TASA DEL DÍA',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8, letterSpacing: 2, color: AppColors.text3,
                  ),
                ),
                const SizedBox(height: 2),
                // Rate
                isLoading
                    ? Container(
                        width: 200, height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.s3,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Formatters.formatRate(rate),
                            style: GoogleFonts.bebasNeue(
                              fontSize: 58, height: 1, letterSpacing: 1,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bs/\$',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12, color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 6),
                // Variation + time
                if (!isLoading)
                  Row(
                    children: [
                      Text(
                        '${isUp ? "▲" : "▼"} ${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: isUp ? AppColors.green : AppColors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        timestamp != null ? Formatters.timeAgo(timestamp!) : '',
                        style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Sparkline
          if (!isLoading)
            SizedBox(
              height: 36,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter()),
            ),
        ],
      ),
    );
  }
}

// ── Sparkline Painter ──
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.78);
    path.cubicTo(w * 0.12, h * 0.72, w * 0.21, h * 0.64, w * 0.31, h * 0.56);
    path.cubicTo(w * 0.44, h * 0.47, w * 0.56, h * 0.39, w * 0.69, h * 0.28);
    path.cubicTo(w * 0.83, h * 0.19, w * 0.92, h * 0.14, w, h * 0.08);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.green.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Live Dot (animated) ──
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.3 + 0.7 * _ctrl.value,
        child: Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Mini Grid (2×2) ──
class _MiniGrid extends StatelessWidget {
  final double p2p;
  final double yadio;
  final double eurBcv;
  final double bcvUsd;
  final double variation;
  final bool loading;
  const _MiniGrid({
    required this.p2p,
    required this.yadio,
    required this.eurBcv,
    required this.bcvUsd,
    required this.variation,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular variaciones reales respecto al BCV
    final p2pDiff = bcvUsd > 0 && p2p > 0 ? ((p2p - bcvUsd) / bcvUsd * 100) : 0.0;
    final yadioDiff = bcvUsd > 0 && yadio > 0 ? ((yadio - bcvUsd) / bcvUsd * 100) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MiniCard(
              label: 'USDT P2P', value: p2p, dot: AppColors.green,
              diffPercent: p2pDiff, loading: loading,
            )),
            const SizedBox(width: 7),
            Expanded(child: _MiniCard(
              label: 'YADIO', value: yadio, dot: AppColors.blue,
              diffPercent: yadioDiff, loading: loading,
            )),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(child: _MiniCard(
              label: 'BCV EUR', value: eurBcv, dot: AppColors.purple,
              diffPercent: variation, loading: loading,
            )),
            const SizedBox(width: 7),
            Expanded(child: _MiniCard(
              label: 'BCV USD', value: bcvUsd, dot: AppColors.amber,
              diffPercent: variation, loading: loading,
            )),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double value;
  final Color dot;
  final double diffPercent;
  final bool loading;
  const _MiniCard({
    required this.label,
    required this.value,
    required this.dot,
    required this.diffPercent,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = diffPercent >= 0;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
              const Spacer(),
              Container(width: 5, height: 5, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 5),
          loading
              ? Container(width: 60, height: 20, color: AppColors.s3)
              : Text(
                  value > 0 ? Formatters.formatRate(value) : '—',
                  style: GoogleFonts.bebasNeue(fontSize: 20, color: AppColors.text),
                ),
          const SizedBox(height: 2),
          if (!loading && value > 0)
            Text(
              '${isUp ? "+" : ""}${diffPercent.toStringAsFixed(2)}%',
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: isUp ? AppColors.green : AppColors.red,
              ),
            ),
          if (!loading && value == 0)
            Text('sin datos', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3)),
        ],
      ),
    );
  }
}

// ── Spread Row ──
class _SpreadRow extends StatelessWidget {
  final double spread;
  const _SpreadRow({required this.spread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.amberDim2,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.amber),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spread BCV vs Paralelo',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paralelo corre por encima del oficial',
                  style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text2),
                ),
              ],
            ),
          ),
          Text(
            '+${spread.toStringAsFixed(1)}%',
            style: GoogleFonts.bebasNeue(fontSize: 30, color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

// ── Alert Row (dynamic) ──
class _AlertRow extends StatelessWidget {
  final double spread;
  final String? status;
  const _AlertRow({required this.spread, this.status});

  @override
  Widget build(BuildContext context) {
    // Determine alert message based on real data
    String title;
    String subtitle;
    Color badgeColor;
    String badgeText;

    if (spread.abs() > 30) {
      title = 'Spread inusual detectado';
      subtitle = 'Paralelo ${spread > 0 ? "+" : ""}${spread.toStringAsFixed(1)}% vs BCV';
      badgeColor = AppColors.amber;
      badgeText = 'ALERTA';
    } else if (status != null && status!.contains('Monitoreando')) {
      title = 'Monitoreando BCV';
      subtitle = 'Ventana de publicación activa (4-6 PM)';
      badgeColor = AppColors.green;
      badgeText = 'EN VIVO';
    } else {
      title = 'Tasa del día actualizada';
      subtitle = status ?? 'BCV publica entre 4:00-6:00 PM VET';
      badgeColor = AppColors.s4;
      badgeText = 'INFO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text2)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(badgeText,
              style: GoogleFonts.spaceMono(
                fontSize: 8, fontWeight: FontWeight.w700,
                letterSpacing: 1, color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Otras Monedas BCV ──
class _CurrencyRow {
  final String code;
  final String name;
  final double value;
  const _CurrencyRow({required this.code, required this.name, required this.value});
}

class _OtrasMonedas extends StatelessWidget {
  final List<_CurrencyRow> rows;
  const _OtrasMonedas({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 5),
            child: Row(
              children: [
                Text('OTRAS MONEDAS BCV',
                  style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3)),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.s3,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: Text(rows[i].code,
                      style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.text2)),
                  ),
                  const SizedBox(width: 10),
                  Text(rows[i].name,
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text2)),
                  const Spacer(),
                  Text(
                    Formatters.formatRate(rows[i].value),
                    style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.text),
                  ),
                  const SizedBox(width: 4),
                  Text('Bs', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.text3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Ad Banner Slot ──
class _AdBannerSlot extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends ConsumerState<_AdBannerSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _bannerAd = BannerAd(
        adUnitId: AdConfig.BANNER_HOME,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isLoaded = true),
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            setState(() => _isLoaded = false);
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      // Placeholder slot visible
      return Container(
        height: 46,
        margin: const EdgeInsets.fromLTRB(13, 6, 13, 0),
        decoration: BoxDecoration(
          color: AppColors.s1,
          borderRadius: BorderRadius.circular(AppColors.r1),
          border: Border.all(color: AppColors.border2, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          'BANNER 320×50',
          style: GoogleFonts.spaceMono(fontSize: 8, letterSpacing: 2, color: AppColors.text3),
        ),
      );
    }
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(13, 6, 13, 0),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.r1),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
