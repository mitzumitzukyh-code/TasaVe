import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('es', null),
    SharedPreferences.getInstance(),
  ]);

  runApp(
    const ProviderScope(
      child: TasaVeApp(),
    ),
  );
}

class TasaVeApp extends StatelessWidget {
  const TasaVeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TasaVe',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('TasaVe — En construcción'),
        ),
      ),
    );
  }
}
