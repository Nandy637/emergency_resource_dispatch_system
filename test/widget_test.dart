// Widget test updated to match SafeCallApp entry point.
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_resource_dispatch_system/main.dart';

void main() {
  testWidgets('SafeCallApp smoke test', (WidgetTester tester) async {
    // Pumps the app and verifies the role selector renders.
    await tester.pumpWidget(const SafeCallApp());
    expect(find.text('SafeCall SOS'), findsOneWidget);
  });
}
