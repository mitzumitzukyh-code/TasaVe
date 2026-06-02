import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/subscription_constants.dart';
import '../../providers/theme_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/tasa_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAccessible = ref.watch(accessibilityProvider);
    final isDark = ref.watch(themeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final defaultRate = prefs.getString(AppConstants.kPrefDefaultRate) ?? 'BCV USD';
    final decimalFormat = prefs.getString(AppConstants.kPrefDecimalFormat) ?? 'Coma (,)';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Text(
                'Ajustes',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // Premium card
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TasaVe Premium',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sin anuncios · Alertas ilimitadas · Widgets',
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.85),
                        disabledForegroundColor: AppColors.primary,
                      ),
                      child: const Text('Próximamente · \$1.99 pago único'),
                    ),
                  ],
                ),
              ),
            ),

            // PREFERENCIAS
            _SectionLabel('PREFERENCIAS', theme),

            _SettingsRow(
              label: 'Tasa por defecto',
              sub: '¿Cuál mostrar primero?',
              value: defaultRate,
              theme: theme,
              onTap: () => _showDefaultRateSheet(context, ref),
            ),
            _SettingsRow(
              label: 'Formato de número',
              sub: 'Separador decimal',
              value: decimalFormat,
              theme: theme,
              onTap: () => _showDecimalFormatSheet(context, ref),
            ),
            _SettingsRowToggle(
              label: 'Accesibilidad',
              sub: 'Texto más grande',
              value: isAccessible,
              theme: theme,
              onTap: () => ref.read(accessibilityProvider.notifier).toggle(),
            ),
            _SettingsRowToggle(
              label: 'Modo oscuro',
              sub: 'Tema oscuro para la app',
              value: isDark,
              theme: theme,
              onTap: () => ref.read(themeProvider.notifier).toggle(),
            ),

            // INFORMACIÓN
            _SectionLabel('INFORMACIÓN', theme),

            _SettingsRow(
              label: 'Fuente de datos',
              value: 'BCV oficial',
              theme: theme,
              onTap: () => _launchUrl('https://bcv.org.ve'),
            ),
            _SettingsRow(
              label: 'Versión',
              value: '1.0.0 (build 1)',
              theme: theme,
              showChevron: false,
            ),
            _SettingsRow(
              label: 'Política de privacidad',
              labelColor: AppColors.primary,
              chevronColor: AppColors.primary,
              theme: theme,
              onTap: () => _launchUrl(SubscriptionConstants.privacyPolicyUrl),
            ),
            _SettingsRow(
              label: 'Contacto / Soporte',
              value: 'soporte@tasave.app',
              theme: theme,
              onTap: () => _launchUrl('mailto:soporte@tasave.app'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDefaultRateSheet(BuildContext context, WidgetRef ref) {
    _showOptionSheet(
      context,
      title: 'Tasa por defecto',
      options: ['BCV USD', 'USDT P2P', 'EUR BCV'],
      onSelected: (value) {
        ref.read(sharedPreferencesProvider).setString(AppConstants.kPrefDefaultRate, value);
      },
    );
  }

  void _showDecimalFormatSheet(BuildContext context, WidgetRef ref) {
    _showOptionSheet(
      context,
      title: 'Formato de número',
      options: ['Coma (,)', 'Punto (.)'],
      onSelected: (value) {
        ref.read(sharedPreferencesProvider).setString(AppConstants.kPrefDecimalFormat, value);
      },
    );
  }

  void _showOptionSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      onSelected(opt);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? labelColor;
  final Color? chevronColor;
  final ThemeData theme;

  const _SettingsRow({
    required this.label,
    required this.theme,
    this.sub,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.labelColor,
    this.chevronColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        sub!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                if (showChevron && onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: chevronColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRowToggle extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SettingsRowToggle({
    required this.label,
    required this.value,
    required this.onTap,
    required this.theme,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      sub!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
