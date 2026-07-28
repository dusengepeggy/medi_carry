import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/records/data/records_repository.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';
import 'package:medi_carry/features/records/view/medical_records_screen.dart';
import 'package:medi_carry/features/records/widgets/record_card.dart';
import 'package:medi_carry/features/records/widgets/record_filter_chips.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late RecordsRepository recordsRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Alex Mwangi'),
      ),
    );
    recordsRepository = RecordsRepository(firestore: FakeFirebaseFirestore());
    // Seed the three records the design/tests exercise (newest first).
    await recordsRepository.add('u1', MedicalRecord(
      id: '',
      category: RecordCategory.diagnosis,
      title: 'Acute Bronchitis',
      provider: 'Aga Khan University Hospital',
      date: DateTime(2023, 9, 15),
      createdAt: DateTime(2023, 9, 15),
    ));
    await recordsRepository.add('u1', MedicalRecord(
      id: '',
      category: RecordCategory.medication,
      title: 'Amoxicillin 500mg',
      detail: '1 capsule every 8 hours for 7 days',
      date: DateTime(2023, 10, 10),
      createdAt: DateTime(2023, 10, 10),
    ));
    await recordsRepository.add('u1', MedicalRecord(
      id: '',
      category: RecordCategory.labResult,
      title: 'Comprehensive Metabolic Panel',
      provider: 'Nairobi Hospital Central Lab • Dr. J. Kamau',
      date: DateTime(2023, 10, 24),
      createdAt: DateTime(2023, 10, 24),
    ));
  });

  Future<void> pumpRecords(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<RecordsRepository>.value(
        value: recordsRepository,
        child: BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MedicalRecordsScreen(),
          ),
        ),
      ),
    );
    // Several async hops: auth resolves the uid → the cubit is rekeyed →
    // the records stream emits → the cubit rebuilds.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders the app bar, search, filters and record cards',
      (tester) async {
    await pumpRecords(tester);

    expect(find.text('Hi, Alex'), findsOneWidget);
    expect(find.text('Search records by name or doctor...'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    // All three record cards from the design.
    expect(find.byType(RecordCard), findsNWidgets(3));
    expect(find.text('LAB RESULT'), findsOneWidget);
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('Acute Bronchitis'), findsOneWidget);
  });

  testWidgets('filter chips narrow the list to one category', (tester) async {
    await pumpRecords(tester);

    // The chip row scrolls horizontally by design, so scroll each chip into
    // view before tapping it.
    final chipRow = find.descendant(
      of: find.byType(RecordFilterChips),
      matching: find.byType(Scrollable),
    );

    await tester.ensureVisible(find.text('Medications'));
    await tester.pump();
    await tester.tap(find.text('Medications'));
    await tester.pump();

    expect(find.byType(RecordCard), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('Acute Bronchitis'), findsNothing);

    // Scrolling right disposed the "All" chip, so bring the row back first.
    await tester.drag(chipRow, const Offset(400, 0));
    await tester.pump();
    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.byType(RecordCard), findsNWidgets(3));
  });

  testWidgets('search matches title and subtitle, and can empty the list',
      (tester) async {
    await pumpRecords(tester);

    await tester.enterText(find.byType(TextField), 'bronchitis');
    await tester.pump();
    expect(find.byType(RecordCard), findsOneWidget);
    expect(find.text('Acute Bronchitis'), findsOneWidget);

    // Subtitle match — the doctor's name.
    await tester.enterText(find.byType(TextField), 'kamau');
    await tester.pump();
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nothing matches this');
    await tester.pump();
    expect(find.byType(RecordCard), findsNothing);
    expect(find.text('No records match your search.'), findsOneWidget);
  });
}
