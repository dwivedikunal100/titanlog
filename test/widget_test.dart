import 'package:flutter_test/flutter_test.dart';
import 'package:titanlog/main.dart';

void main() {
  testWidgets('TitanLog app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TitanLogApp());
    expect(find.text('TITAN'), findsOneWidget);
  });
}
