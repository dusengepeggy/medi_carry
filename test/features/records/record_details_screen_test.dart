import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';
import 'package:medi_carry/features/records/view/record_details_screen.dart';
import 'package:medi_carry/features/records/widgets/clinical_details_card.dart';
import 'package:medi_carry/features/records/widgets/doctor_notes_card.dart';

final _record = MedicalRecord(
  id: 'r1',
  category: RecordCategory.labResult,
  title: 'Comprehensive Metabolic Panel',
  provider: 'Nairobi Central Clinic • Dr. Amina Ochieng',
  detail: 'Fasting glucose mildly elevated (108 mg/dL).',
  notes: 'Discussed dietary adjustments; re-test next quarter.',
  date: DateTime(2023, 10, 24),
  createdAt: DateTime(2023, 10, 24),
);

void main() {
  Future<void> pumpDetails(WidgetTester tester, {MedicalRecord? record}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RecordDetailsScreen(record: record ?? _record),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the header, category and metadata from the record',
      (tester) async {
    await pumpDetails(tester);

    expect(find.text('Record Details'), findsOneWidget);
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);
    expect(find.text('LAB RESULT'), findsOneWidget);
    expect(find.text('Oct 24, 2023'), findsOneWidget);
    // The provider shows in both the header and the clinical details card.
    expect(find.text('Nairobi Central Clinic • Dr. Amina Ochieng'),
        findsWidgets);
  });

  testWidgets('renders clinical details from the record', (tester) async {
    await pumpDetails(tester);

    expect(find.byType(ClinicalDetailsCard), findsOneWidget);
    expect(find.text('Clinical Details'), findsOneWidget);
    expect(find.text('REFERRING PHYSICIAN'), findsOneWidget);
    expect(find.text('Lab result'), findsOneWidget); // speciality = category
    expect(find.text('RESULT SUMMARY'), findsOneWidget);
    expect(find.text('Fasting glucose mildly elevated (108 mg/dL).'),
        findsOneWidget);
    // A generic record has no patient-ID field.
    expect(find.text('PATIENT ID'), findsNothing);
  });

  testWidgets('renders notes and action buttons', (tester) async {
    await pumpDetails(tester);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pump();

    expect(find.byType(DoctorNotesCard), findsOneWidget);
    expect(find.text('Share Record'), findsOneWidget);
    expect(find.text('Print PDF'), findsOneWidget);
  });

  testWidgets('hides the notes card when the record has none', (tester) async {
    await pumpDetails(
      tester,
      record: MedicalRecord(
        id: 'r2',
        category: RecordCategory.vitals,
        title: 'Blood Pressure',
        date: DateTime(2023, 10, 24),
        createdAt: DateTime(2023, 10, 24),
      ),
    );

    expect(find.byType(DoctorNotesCard), findsNothing);
  });
}
