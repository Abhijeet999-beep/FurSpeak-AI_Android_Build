import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/main.dart';

void main() {
  testWidgets('FurSpeak AI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('FurSpeak AI'), findsOneWidget);
  });
}
