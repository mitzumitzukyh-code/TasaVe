import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'presentation/providers/tasa_provider.dart';
import 'presentation/providers/accessibility_provider.dart';
import 'presentation/providers/alerts_provider.dart';
import 'data/services/notification_service.dart';
import 'utils/accessibility.dart';
import 'presentation/screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CalculaYaApp(),
    ),
  );
}

class CalculaYaApp extends ConsumerWidget {
  const CalculaYaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccessible = ref.watch(accessibilityProvider);
    final scale = Accessibility.fontScale(isAccessible);

    // Initialize notifications and register token with alerts provider
    _initNotifications(ref);

    return MaterialApp(
      title: 'CalculaYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      home: const ShellScreen(),
    );
  }

  static bool _notificationsInitialized = false;

  void _initNotifications(WidgetRef ref) {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    Future.microtask(() async {
      final notifService = NotificationService();
      final success = await notifService.initialize();
      if (success && notifService.token != null) {
        ref.read(alertsProvider.notifier).setFcmToken(notifService.token!);
      }
    });
  }
}
