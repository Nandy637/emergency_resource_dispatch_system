// This is a basic Flutter widget test for the Emergency Dispatch System.

import 'package:flutter_test/flutter_test.dart';

import 'package:emergency_resource_dispatch_system/main.dart';

void main() {
  testWidgets('SOS button appears on home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmergencyDispatchApp());

    // Verify that the SOS button is displayed.
    expect(find.text('SOS'), findsOneWidget);
  });
}
