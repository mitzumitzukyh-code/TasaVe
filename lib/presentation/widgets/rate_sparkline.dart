import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/tasa_model.dart';

/// Mini gráfica de línea con datos reales del historial (sin curvas inventadas).
class RateSparkline extends StatelessWidget {
  final List<TasaHistoryEntry> entries;
  final double height;

  const RateSparkline({
    super.key,
    required this.entries,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _PlaceholderSparklinePainter()),
      );
    }

    final sorted = List<TasaHistoryEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DataSparklinePainter(
          values: sorted.map((e) => e.bcvUsd).toList(),
        ),
      ),
    );
  }
}

class _DataSparklinePainter extends CustomPainter {
  final List<double> values;

  _DataSparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    final pad = range > 0 ? range * 0.08 : 1.0;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final norm = range > 0
          ? (values[i] - minV + pad) / (range + pad * 2)
          : 0.5;
      final y = size.height * (1 - norm);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = AppColors.green.withValues(alpha: 0.08));
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DataSparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _PlaceholderSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
