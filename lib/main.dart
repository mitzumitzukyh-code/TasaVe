import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/cache/local_storage.dart';
import 'presentation/providers/tasa_provider.dart';
import 'presentation/providers/accessibility_provider.dart';
import 'presentation/screens/shell_screen.dart';
import 'providers/theme_provider.dart';
import 'utils/accessibility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    initializeDateFormatting('es', null),
    SharedPreferences.getInstance(),
  ]);
  final prefs = results[1] as SharedPreferences;
  final storage = LocalStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TasaVeApp(),
    ),
  );
}

class TasaVeApp extends ConsumerWidget {
  const TasaVeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccessible = ref.watch(accessibilityProvider);
    final scale = Accessibility.fontScale(isAccessible);

    return MaterialApp(
      title: 'TasaVe',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeProvider) ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        Widget result = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
        if (kIsWeb) {
          result = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: result,
            ),
          );
        }
        return result;
      },
      home: const ShellScreen(),
    );
  }
}
