import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/notification_service.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/dashboard/view/home_screen.dart';
import 'package:medi_carry/features/medications/bloc/medications_cubit.dart';
import 'package:medi_carry/features/medications/data/medications_repository.dart';
import 'package:medi_carry/features/medications/models/medication.dart';
import 'package:medi_carry/features/records/data/records_repository.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/test_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late FakeFirebaseFirestore firestore;
  late RecordsRepository recordsRepository;
  late MedicationsRepository medicationsRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Sarah Johnson'),
      ),
    );
    firestore = FakeFirebaseFirestore();
    recordsRepository = RecordsRepository(firestore: firestore);
    medicationsRepository = MedicationsRepository(firestore: firestore);

    await recordsRepository.add(
      'u1',
      MedicalRecord(
        id: '',
        category: RecordCategory.labResult,
        title: 'Comprehensive Metabolic Panel',
        provider: 'City Lab',
        date: DateTime(2023, 10, 12),
        createdAt: DateTime(2023, 10, 12),
      ),
    );
  });

  Future<void> seedMedication() => medicationsRepository.add(
        'u1',
        Medication(
          id: '',
          name: 'Lisinopril',
          dosage: '10mg',
          instructions: 'Take with food',
          // Doses at both ends of the day, so one is always still ahead
          // whatever time the suite happens to run at.
          times: const [DoseTime(0, 1), DoseTime(23, 59)],
          startDate: DateTime(2020, 1, 1),
          createdAt: DateTime(2020, 1, 1),
        ),
      );

  Future<void> seedVitals() => recordsRepository.add(
        'u1',
        MedicalRecord(
          id: '',
          category: RecordCategory.vitals,
          title: 'Blood pressure',
          detail: '118/76 mmHg',
          date: DateTime(2024, 5, 2),
          createdAt: DateTime(2024, 5, 2),
        ),
      );

  Future<void> pumpDashboard(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so layout overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RecordsRepository>.value(value: recordsRepository),
          RepositoryProvider<MedicationsRepository>.value(
              value: medicationsRepository),
        ],
        child: withMediBlocs(
          authRepository: authRepository,
          userRepository: fakeUserRepository(firestore),
          child: BlocProvider(
            // An uninitialised notification service: every scheduling call is
            // a no-op, so the test never reaches the platform channel.
            create: (_) => MedicationsCubit(
              repository: medicationsRepository,
              notifications: NotificationService(),
              uid: 'u1',
            ),
            child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
          ),
        ),
      ),
    );
    // Auth resolves the uid → the cubits are rekeyed → the streams emit.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders the welcome header and emergency action',
      (tester) async {
    await pumpDashboard(tester);

    expect(find.textContaining('Sarah'), findsOneWidget);
    expect(find.text('Here is your health overview for today.'), findsOneWidget);
    expect(find.text('Emergency Info'), findsOneWidget);
  });

  testWidgets('shows the next dose from the real medication schedule',
      (tester) async {
    await seedMedication();
    await pumpDashboard(tester);

    expect(find.text('NEXT MEDICATION'), findsOneWidget);
    expect(find.text('Lisinopril'), findsOneWidget);
    expect(find.text('10mg - Take with food'), findsOneWidget);
    expect(find.text('Mark as Taken'), findsOneWidget);
  });

  testWidgets('the medication card opens the full regimen', (tester) async {
    await seedMedication();
    await pumpDashboard(tester);

    // Tapping the card is the only route to the rest of the schedule and the
    // reminder switches once a medication exists.
    await tester.tap(find.text('Lisinopril'));
    await tester.pumpAndSettle();

    expect(find.text('Medications'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('prompts to add a medication when none are scheduled',
      (tester) async {
    await pumpDashboard(tester);

    expect(find.text('No medications yet'), findsOneWidget);
    expect(find.text('Add medication'), findsOneWidget);
    expect(find.text('NEXT MEDICATION'), findsNothing);
  });

  testWidgets('shows the latest vitals record', (tester) async {
    await seedVitals();
    await pumpDashboard(tester);

    expect(find.text('BLOOD PRESSURE'), findsOneWidget);
    expect(find.text('118/76 mmHg'), findsOneWidget);
    expect(find.textContaining('Recorded May 2, 2024'), findsOneWidget);
  });

  testWidgets('prompts to add vitals when none are recorded', (tester) async {
    await pumpDashboard(tester);

    expect(find.text('No vitals recorded'), findsOneWidget);
    expect(find.text('Add vitals'), findsOneWidget);
  });

  testWidgets('renders activity and add-record cards', (tester) async {
    await pumpDashboard(tester);

    // Scroll the lower cards into view.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('See All'), findsOneWidget);
    // The seeded real record shows in the activity list.
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);
    expect(find.text('Add New Record'), findsOneWidget);
    // The bottom nav now lives in AppShell — see test/app/app_shell_test.dart.
  });

  testWidgets('greeting falls back gracefully with no display name',
      (tester) async {
    when(() => authRepository.user)
        .thenAnswer((_) => Stream<AppUser>.value(const AppUser(uid: 'u1')));
    await pumpDashboard(tester);

    expect(find.textContaining('Good'), findsOneWidget);
  });
}
