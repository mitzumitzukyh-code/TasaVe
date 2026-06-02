import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../presentation/screens/history_screen.dart';
import '../presentation/screens/scanner_screen.dart';
import '../presentation/screens/alerts_screen.dart';
import '../presentation/screens/settings_screen.dart';

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({super.key});

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _controller.reverse();
    });
  }

  void _navigateTo(Widget screen) {
    _close();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Barrier
        if (_isOpen)
          GestureDetector(
            onTap: _close,
            child: Container(color: Colors.transparent),
          ),

        // Menú expandido
        if (_isOpen)
          Positioned(
            bottom: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  _FabItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Historial',
                    onTap: () => _navigateTo(const HistoryScreen()),
                  ),
                  const SizedBox(width: 8),
                  _FabItem(
                    icon: Icons.document_scanner,
                    label: 'Escanear',
                    onTap: () => _navigateTo(const ScannerScreen()),
                  ),
                  const SizedBox(width: 8),
                  _FabItem(
                    icon: Icons.notifications_none,
                    label: 'Alertas',
                    onTap: () => _navigateTo(const AlertsScreen()),
                  ),
                  const SizedBox(width: 8),
                  _FabItem(
                    icon: Icons.settings_outlined,
                    label: 'Ajustes',
                    onTap: () => _navigateTo(const SettingsScreen()),
                  ),
                ],
              ),
            ),
          ),

        // FAB principal
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 3.1416 * 2,
              child: child,
            );
          },
          child: SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: isDark ? AppColors.redDark : AppColors.redLight,
              elevation: 0,
              focusElevation: 0,
              highlightElevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _FabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark2
                    : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: isDark ? AppColors.textPrimD : AppColors.textPrimL),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: isDark ? AppColors.textSecD : AppColors.textSecL,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
