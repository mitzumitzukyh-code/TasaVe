import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tasave/data/api/bcv_service.dart';
import 'package:tasave/data/cache/local_storage.dart';
import 'package:tasave/data/models/tasa_model.dart';
import 'package:tasave/presentation/providers/tasa_provider.dart';
import 'package:tasave/main.dart';
import 'package:tasave/presentation/screens/shell_screen.dart';

class FakeBcvService extends BcvService {
  @override
  Future<TasaModel> fetchCurrentRate() async {
    return TasaModel(
      bcvUsd: 36.50,
      usdtP2P: 38.00,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<TasaHistoryEntry>> fetchHistory({int days = 30}) async {
    return [
      TasaHistoryEntry(
        date: DateTime.now().subtract(const Duration(days: 1)),
        bcvUsd: 36.40,
        variation: 0.10,
      ),
      TasaHistoryEntry(
        date: DateTime.now(),
        bcvUsd: 36.50,
        variation: 0.10,
      ),
    ];
  }
}

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await initializeDateFormatting('es', null);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          sharedPreferencesProvider.overrideWithValue(prefs),
          bcvServiceProvider.overrideWithValue(FakeBcvService()),
        ],
        child: const TasaVeApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(ShellScreen), findsOneWidget);
  });
}
