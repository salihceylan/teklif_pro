import 'package:flutter_test/flutter_test.dart';
import 'package:teklif_pro/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TeklifProApp());
    expect(find.byType(TeklifProApp), findsOneWidget);
  });
}
