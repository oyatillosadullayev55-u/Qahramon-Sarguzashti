import 'package:flutter_test/flutter_test.dart';
import 'package:super_adventure/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OyinApp());
    expect(find.byType(OyinApp), findsOneWidget);
  });
}
