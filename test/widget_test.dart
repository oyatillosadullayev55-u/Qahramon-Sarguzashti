import 'package:flutter_test/flutter_test.dart';
import 'package:oyin/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OyinApp());
    expect(find.byType(OyinApp), findsOneWidget);
  });
}
