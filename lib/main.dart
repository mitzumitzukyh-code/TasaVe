import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'presentation/providers/tasa_provider.dart';
import 'presentation/providers/accessibility_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'services/widget_service.dart';
import 'utils/accessibility.dart';
import 'utils/error_monitor.dart';
import 'presentation/screens/shell_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/widgets/responsive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorMonitor.install();

  final initFutures = <Future<void>>[
    initializeDateFormatting('es', null),
    SharedPreferences.getInstance(),
  ];
  if (!kIsWeb) {
    initFutures.add(MobileAds.instance.initialize());
    if (Platform.isAndroid) {
      initFutures.add(WidgetService.init());
    }
  }
  final results = await Future.wait(initFutures);
  final prefs = results[1] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TasaVeApp(),
    ),
  );
}

class TasaVeApp extends ConsumerStatefulWidget {
  const TasaVeApp({super.key});

  @override
  ConsumerState<TasaVeApp> createState() => _TasaVeAppState();
}

class _TasaVeAppState extends ConsumerState<TasaVeApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      Future.microtask(() => ref.read(subscriptionServiceProvider).init());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAccessible = ref.watch(accessibilityProvider);
    final scale = Accessibility.fontScale(isAccessible);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'TasaVe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: ResponsiveWrapper(child: child!),
        );
      },
      home: const SplashScreen(child: _OnboardingGate()),
    );
  }
}

class _OnboardingGate extends ConsumerStatefulWidget {
  const _OnboardingGate();

  @override
  ConsumerState<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<_OnboardingGate> {
  bool? _done;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _done = prefs.getBool('onboarding_done') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) return const SizedBox.shrink();
    if (_done!) return const ShellScreen();
    return OnboardingScreen(
      onComplete: () => setState(() => _done = true),
    );
  }
}
