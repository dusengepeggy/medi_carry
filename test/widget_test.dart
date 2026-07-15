// Smoke test for the MediCarry app: verifies the app boots and renders the
// themed home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:medi_carry/main.dart';

void main() {
  testWidgets('App renders the MediCarry home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    // App bar title and a themed element from the starter screen are present.
    expect(find.text('MediCarry'), findsOneWidget);
    expect(find.text('Add New Record'), findsOneWidget);
  });
}
