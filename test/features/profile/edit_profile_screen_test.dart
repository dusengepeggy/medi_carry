import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/profile/view/edit_profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository userRepository;

  const profile = PatientProfile(
    uid: 'u1',
    fullName: 'Alex Johnston',
    email: 'alex@example.com',
    patientId: 'MC-88291',
    bloodType: 'O+',
    allergies: ['Penicillin'],
    gender: 'Male',
    dateOfBirth: '1992-05-14',
    emergencyContactName: 'Sarah Johnston',
    emergencyContactPhone: '+1 (555) 012-3456',
  );

  setUpAll(() {
    registerFallbackValue(
      const PatientProfile(uid: '', fullName: '', email: '', patientId: ''),
    );
  });

  setUp(() {
    userRepository = MockUserRepository();
    when(() => userRepository.updateProfile(any())).thenAnswer((_) async {});
  });

  Future<void> pumpEdit(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<UserRepository>.value(
        value: userRepository,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EditProfileScreen(profile: profile),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('pre-fills the form from the existing profile', (tester) async {
    await pumpEdit(tester);

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);
    expect(find.text('MediCarry ID: MC-88291'), findsOneWidget);

    // Section headings.
    expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
    expect(find.text('HEALTH DATA'), findsOneWidget);
    expect(find.text('EMERGENCY CONTACT'), findsOneWidget);

    // Existing values, including the date formatted for display.
    expect(find.text('Alex Johnston'), findsNWidgets(2)); // header + field
    expect(find.text('05/14/1992'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Sarah Johnston'), findsOneWidget);
    expect(find.text('+1 (555) 012-3456'), findsOneWidget);
  });

  testWidgets('saving persists edited fields and preserves untouched ones',
      (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextField).first, 'Alexandra Johnston');
    await tester.pump();

    await tester.tap(find.text('SAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = verify(() => userRepository.updateProfile(captureAny()))
        .captured
        .single as PatientProfile;

    expect(saved.fullName, 'Alexandra Johnston');
    // Untouched fields survive the edit.
    expect(saved.patientId, 'MC-88291');
    expect(saved.email, 'alex@example.com');
    expect(saved.allergies, ['Penicillin']);
    expect(saved.dateOfBirth, '1992-05-14');
    expect(saved.emergencyContactName, 'Sarah Johnston');
  });

  testWidgets('refuses to save an empty name', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();

    await tester.tap(find.text('SAVE'));
    await tester.pump();

    verifyNever(() => userRepository.updateProfile(any()));
    expect(find.text('Please enter your name.'), findsOneWidget);
  });

  testWidgets('clearing the emergency contact stores null, not an empty string',
      (tester) async {
    await pumpEdit(tester);

    final contactField = find.byType(TextField).at(1);
    await tester.ensureVisible(contactField);
    await tester.pump();
    await tester.enterText(contactField, '');
    await tester.pump();

    await tester.tap(find.text('SAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = verify(() => userRepository.updateProfile(captureAny()))
        .captured
        .single as PatientProfile;
    expect(saved.emergencyContactName, isNull);
  });
}
