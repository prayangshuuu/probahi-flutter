import 'package:flutter_test/flutter_test.dart';

import 'package:probahi/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProbahiApp());

    // Before the async bootstrap (base URL load + session restore)
    // resolves, the auth gate shows the splash screen.
    expect(find.text('Probahi'), findsOneWidget);
  });
}
