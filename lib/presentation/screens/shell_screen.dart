import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import '../providers/accessibility_provider.dart';
import '../providers/shell_provider.dart';
import 'home_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'remesas_screen.dart';
import 'alerts_screen.dart';
import 'perfiles_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  InterstitialAd? _interstitialAd;
  int _navCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: AdConfig.INTERSTITIAL,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialIfNeeded() {
    final userPlan = ref.read(userPlanProvider);
    if (userPlan == 'premium' || kIsWeb) return;
    _navCount++;
    if (_navCount % 3 == 0 && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  final _screens = const [
    HomeScreen(),
    CalculatorScreen(),
    HistoryScreen(),
    RemesasScreen(),
    PerfilesScreen(),
    AlertsScreen(),
  ];

  void _goTo(int index) {
    ref.read(shellTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(label: 'INICIO', isActive: currentIndex == 0,
                  onTap: () => _goTo(0)),
                _NavItem(label: 'CALCULAR', isActive: currentIndex == 1,
                  onTap: () => _goTo(1)),
                _NavItem(label: 'HIST', isActive: currentIndex == 2,
                  onTap: () {
                    if (currentIndex != 2) _showInterstitialIfNeeded();
                    _goTo(2);
                  }),
                _NavItem(label: 'REMESAS', isActive: currentIndex == 3,
                  onTap: () => _goTo(3)),
                _NavItem(label: 'PERFILES', isActive: currentIndex == 4,
                  onTap: () => _goTo(4)),
                _NavItem(label: 'ALERTAS', isActive: currentIndex == 5,
                  onTap: () => _goTo(5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green bar indicator
            Container(
              width: 16, height: 2,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                letterSpacing: 0.5,
                color: isActive ? AppColors.green : AppColors.text3,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
