import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teklif_pro/main.dart';
import 'package:teklif_pro/core/storage.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();

    await tester.pumpWidget(const TeklifProApp());
    expect(find.byType(TeklifProApp), findsOneWidget);
  });
}
