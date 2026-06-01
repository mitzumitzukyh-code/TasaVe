import 'package:flutter_test/flutter_test.dart';

import 'package:calculaya/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TasaVeApp());
    expect(find.text('TasaVe'), findsOneWidget);
  });
}
