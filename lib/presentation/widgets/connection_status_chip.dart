import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

enum DataConnectionStatus { online, cache, offline, loading }

class ConnectionStatusChip extends StatelessWidget {
  final DataConnectionStatus status;
  final bool compact;

  const ConnectionStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, dot) = switch (status) {
      DataConnectionStatus.online => ('AL DÍA', AppColors.greenLight, AppColors.green, AppColors.green),
      DataConnectionStatus.cache => ('CACHÉ', AppColors.yellowLight, const Color(0xFF6D5500), AppColors.yellow),
      DataConnectionStatus.offline => ('SIN RED', AppColors.redLight, AppColors.red, AppColors.red),
      DataConnectionStatus.loading => ('CARGANDO', AppColors.bg, AppColors.text3, AppColors.text3),
    };

    return Semantics(
      label: 'Estado de datos: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: compact ? 7 : 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
