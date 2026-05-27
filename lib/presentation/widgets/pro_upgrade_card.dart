import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';

class ProUpgradeCard extends ConsumerWidget {
  const ProUpgradeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final service = ref.read(subscriptionServiceProvider);

    if (sub.isPremium) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'TasaVe Pro activo',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TasaVe Pro',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub.priceLabel ?? SubscriptionConstants.fallbackPriceLabel,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          _feat('Sin anuncios'),
          _feat('Widget en pantalla de inicio'),
          _feat('Historial 1 año + exportar CSV'),
          _feat('Euro, COP y BRL'),
          _feat('Escáner ilimitado'),
          _feat('Perfiles de pago ilimitados'),
          if (sub.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              sub.errorMessage!,
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.red),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: sub.purchasePending || sub.isLoading
                ? null
                : () => service.buyPro(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              sub.purchasePending ? 'Procesando…' : 'Suscribirme a Pro',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: sub.isLoading ? null : () => service.restorePurchases(),
            child: Text(
              'Restaurar compra',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(SubscriptionConstants.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              'Política de privacidad',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feat(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text2),
            ),
          ),
        ],
      ),
    );
  }
}
