import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../data/models/tasa_model.dart';
import '../../utils/formatters.dart';

/// EUR, COP, BRL del BCV + Yadio (tasa de referencia de mercado libre)
class ExtraCurrenciesSection extends StatelessWidget {
  final TasaModel tasa;

  const ExtraCurrenciesSection({super.key, required this.tasa});

  @override
  Widget build(BuildContext context) {
    final bcvRows = <_CurrencyRow>[
      if (tasa.bcvEur != null && tasa.bcvEur! > 0)
        _CurrencyRow(code: 'EUR', name: 'Euro BCV', value: tasa.bcvEur!),
      if (tasa.bcvCop != null && tasa.bcvCop! > 0)
        _CurrencyRow(code: 'COP', name: 'Peso colombiano', value: tasa.bcvCop!),
      if (tasa.bcvBrl != null && tasa.bcvBrl! > 0)
        _CurrencyRow(code: 'BRL', name: 'Real brasileño', value: tasa.bcvBrl!),
    ];

    final hasYadio = tasa.yadioRate != null && tasa.yadioRate! > 0;
    final yadioSpread = (hasYadio && tasa.bcvUsd > 0)
        ? ((tasa.yadioRate! - tasa.bcvUsd) / tasa.bcvUsd * 100)
        : null;

    final hasP2P = tasa.usdtP2P > 0 && tasa.bcvUsd > 0;
    final p2pSpread = hasP2P
        ? ((tasa.usdtP2P - tasa.bcvUsd) / tasa.bcvUsd * 100)
        : null;

    if (bcvRows.isEmpty && !hasYadio && !hasP2P) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p2pSpread != null) _SpreadBanner(spreadPct: p2pSpread),
        if (p2pSpread != null && (bcvRows.isNotEmpty || hasYadio))
          const SizedBox(height: 8),
        if (bcvRows.isNotEmpty || hasYadio)
          _CurrenciesCard(
            bcvRows: bcvRows,
            tasa: tasa,
            hasYadio: hasYadio,
            yadioSpread: yadioSpread,
          ),
      ],
    );
  }
}

class _SpreadBanner extends StatelessWidget {
  final double spreadPct;
  const _SpreadBanner({required this.spreadPct});

  @override
  Widget build(BuildContext context) {
    final Color spreadColor;
    final String spreadLabel;
    if (spreadPct < 2.0) {
      spreadColor = AppColors.green;
      spreadLabel = 'Spread bajo';
    } else if (spreadPct < 5.0) {
      spreadColor = AppColors.yellow;
      spreadLabel = 'Spread moderado';
    } else {
      spreadColor = AppColors.red;
      spreadLabel = 'Spread alto';
    }
    final sign = spreadPct >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: spreadColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.r1),
        border: Border.all(color: spreadColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, size: 15, color: spreadColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Diferencia BCV vs P2P: $sign${spreadPct.toStringAsFixed(2)}%  ·  $spreadLabel',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: spreadColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrenciesCard extends StatelessWidget {
  final List<_CurrencyRow> bcvRows;
  final TasaModel tasa;
  final bool hasYadio;
  final double? yadioSpread;

  const _CurrenciesCard({
    required this.bcvRows,
    required this.tasa,
    required this.hasYadio,
    required this.yadioSpread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sección BCV ──
          if (bcvRows.isNotEmpty) ...
            [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Text(
                  'OTRAS MONEDAS BCV',
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    letterSpacing: 2,
                    color: AppColors.text3,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ...bcvRows.map((row) => _OtrasRow(row: row)),
            ],
          // ── Sección Referencia de Mercado ──
          if (hasYadio || tasa.usdtP2P > 0) ...
            [
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Text(
                  'REFERENCIA DE MERCADO',
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    letterSpacing: 2,
                    color: AppColors.text3,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (tasa.usdtP2P > 0)
                _P2PRow(
                  value: tasa.usdtP2P,
                  spread: tasa.bcvUsd > 0
                      ? ((tasa.usdtP2P - tasa.bcvUsd) / tasa.bcvUsd * 100)
                      : null,
                ),
              if (hasYadio)
                _YadioRow(
                  value: tasa.yadioRate!,
                  spread: yadioSpread,
                ),
            ],
        ],
      ),
    );
  }
}

class _CurrencyRow {
  final String code;
  final String name;
  final double value;
  const _CurrencyRow({required this.code, required this.name, required this.value});
}

class _OtrasRow extends StatelessWidget {
  final _CurrencyRow row;
  const _OtrasRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              row.code,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.text2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.name,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
            ),
          ),
          Text(
            Formatters.formatRate(row.value),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Bs',
            style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

class _P2PRow extends StatelessWidget {
  final double value;
  final double? spread;
  const _P2PRow({required this.value, this.spread});

  @override
  Widget build(BuildContext context) {
    final isUp = (spread ?? 0) >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            ),
            child: Text(
              'P2P',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF60A5FA),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USDT Binance P2P',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
                ),
                if (spread != null)
                  Text(
                    '${isUp ? "+" : ""}${spread!.toStringAsFixed(1)}% vs BCV',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: isUp ? AppColors.yellow : AppColors.green,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.formatRate(value),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Bs',
            style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

class _YadioRow extends StatelessWidget {
  final double value;
  final double? spread;
  const _YadioRow({required this.value, this.spread});

  @override
  Widget build(BuildContext context) {
    final isUp = (spread ?? 0) >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'YAD',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.text2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yadio (ref. mercado)',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
                ),
                if (spread != null)
                  Text(
                    '${isUp ? "+" : ""}${spread!.toStringAsFixed(1)}% vs BCV',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: isUp ? AppColors.yellow : AppColors.green,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.formatRate(value),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Bs',
            style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

/// Mini tarjeta para grid secundario (EUR, etc.)
class MiniRateCard extends StatelessWidget {
  final String label;
  final Color accent;
  final double? value;
  final double? diffPercent;

  const MiniRateCard({
    super.key,
    required this.label,
    required this.accent,
    this.value,
    this.diffPercent,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value! > 0;
    final diff = diffPercent ?? 0;
    final isUp = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 7,
                  letterSpacing: 1,
                  color: AppColors.text3,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasValue ? Formatters.formatRate(value!) : '—',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasValue ? AppColors.text : AppColors.text3,
            ),
          ),
          if (hasValue && diffPercent != null) ...[
            const SizedBox(height: 2),
            Text(
              '${isUp ? "+" : ""}${diff.toStringAsFixed(1)}%',
              style: GoogleFonts.dmSans(
                fontSize: 8,
                color: isUp ? AppColors.green : AppColors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
