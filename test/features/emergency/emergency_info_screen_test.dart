import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/emergency_card_store.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/emergency/view/emergency_info_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockEmergencyCardStore extends Mock implements EmergencyCardStore {}

void main() {
  late MockEmergencyCardStore store;

  setUp(() => store = MockEmergencyCardStore());

  Future<void> pumpEmergency(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<EmergencyCardStore>.value(
        value: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmergencyInfoScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the emergency card from the on-device snapshot alone',
      (tester) async {
    // No Firestore, no network — only the local snapshot, which is the whole
    // point: this must work locked, offline, and cold-started.
    when(() => store.read()).thenAnswer(
      (_) async => const EmergencyCard(
        fullName: 'Sarah Johnson',
        patientId: 'MC-8829-41',
        bloodType: 'O+',
        allergies: ['Penicillin', 'Peanuts'],
        chronicConditions: ['Asthma'],
        emergencyContactName: 'James Johnson',
        emergencyContactPhone: '+254 700 000 000',
      ),
    );

    await pumpEmergency(tester);

    expect(find.text('EMERGENCY MEDICAL INFORMATION'), findsOneWidget);
    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.text('Patient ID: MC-8829-41'), findsOneWidget);

    expect(find.text('BLOOD TYPE'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);

    expect(find.text('ALLERGIES'), findsOneWidget);
    expect(find.text('• Penicillin'), findsOneWidget);
    expect(find.text('• Peanuts'), findsOneWidget);

    expect(find.text('CHRONIC CONDITIONS'), findsOneWidget);
    expect(find.text('• Asthma'), findsOneWidget);

    expect(find.text('EMERGENCY CONTACT'), findsOneWidget);
    expect(find.text('James Johnson'), findsOneWidget);
    expect(find.text('+254 700 000 000'), findsOneWidget);
  });

  testWidgets('shows an explanatory empty state when nothing is stored',
      (tester) async {
    when(() => store.read()).thenAnswer((_) async => null);

    await pumpEmergency(tester);

    expect(find.text('No emergency information yet'), findsOneWidget);
    // The header still renders so the screen is recognisable.
    expect(find.text('EMERGENCY MEDICAL INFORMATION'), findsOneWidget);
  });

  testWidgets('missing fields read as "None recorded", never blank',
      (tester) async {
    when(() => store.read()).thenAnswer(
      (_) async => const EmergencyCard(
        fullName: 'Alex Mwangi',
        patientId: 'MC-1234-56',
      ),
    );

    await pumpEmergency(tester);

    expect(find.text('Not recorded'), findsOneWidget); // blood type
    expect(find.text('None recorded'), findsNWidgets(3)); // allergies/conditions/contact
  });

  test('EmergencyCard survives a JSON round-trip', () {
    const profile = PatientProfile(
      uid: 'u1',
      fullName: 'Sarah Johnson',
      email: 'sarah@example.com',
      patientId: 'MC-8829-41',
      bloodType: 'O+',
      allergies: ['Penicillin'],
      chronicConditions: ['Asthma'],
      emergencyContactName: 'James Johnson',
      emergencyContactPhone: '+254 700 000 000',
    );

    final card = EmergencyCard.fromProfile(profile);
    final restored = EmergencyCard.fromJson(card.toJson());

    expect(restored.fullName, 'Sarah Johnson');
    expect(restored.bloodType, 'O+');
    expect(restored.allergies, ['Penicillin']);
    expect(restored.chronicConditions, ['Asthma']);
    expect(restored.emergencyContactPhone, '+254 700 000 000');
    expect(restored.hasContact, isTrue);
  });
}
