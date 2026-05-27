import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../providers/shell_provider.dart';
import '../providers/subscription_provider.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';
import 'perfiles_screen.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  static const _tabs = [
    _TabDef(label: 'Inicio', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, semantics: 'Inicio'),
    _TabDef(label: 'Escanear', icon: Icons.document_scanner_outlined, activeIcon: Icons.document_scanner_rounded, semantics: 'Escáner de facturas'),
    _TabDef(label: 'Historial', icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart_rounded, semantics: 'Historial de tasas'),
    _TabDef(label: 'Perfil', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, semantics: 'Perfil y QR de pago'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabProvider);
    final isPremium = ref.watch(isPremiumProvider);

    const screens = [
      HomeScreen(),
      ScannerScreen(),
      HistoryScreen(),
      PerfilesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                // Badge PRO en tab Perfil (índice 3) para usuarios free
                final badge = (!isPremium && i == 3) ? 'PRO' : null;
                return _NavItem(
                  label: tab.label,
                  icon: tab.icon,
                  activeIcon: tab.activeIcon,
                  semanticsLabel: tab.semantics,
                  isActive: currentIndex == i,
                  badgeLabel: badge,
                  onTap: () => ref.read(shellTabProvider.notifier).state = i,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String semantics;
  const _TabDef({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.semantics,
  });
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String semanticsLabel;
  final bool isActive;
  final VoidCallback onTap;
  final String? badgeLabel;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.semanticsLabel,
    required this.isActive,
    required this.onTap,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 16) / 4;

    return Semantics(
      button: true,
      selected: isActive,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive ? Colors.white : AppColors.text3,
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: GoogleFonts.dmSans(
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: isActive ? Colors.white : AppColors.text3,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
