import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/records/view/record_details_screen.dart';
import 'package:medi_carry/features/records/widgets/clinical_details_card.dart';
import 'package:medi_carry/features/records/widgets/doctor_notes_card.dart';

void main() {
  Future<void> pumpDetails(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const RecordDetailsScreen()),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the header, status badge and metadata', (tester) async {
    await pumpDetails(tester);

    expect(find.text('Record Details'), findsOneWidget);
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);
    expect(find.text('REVIEW REQUIRED'), findsOneWidget);
    expect(find.text('Oct 24, 2023 • 08:15 AM'), findsOneWidget);
    expect(find.text('Nairobi Central Clinic'), findsOneWidget);
  });

  testWidgets('renders clinical details fields', (tester) async {
    await pumpDetails(tester);

    expect(find.byType(ClinicalDetailsCard), findsOneWidget);
    expect(find.text('Clinical Details'), findsOneWidget);
    expect(find.text('REFERRING PHYSICIAN'), findsOneWidget);
    expect(find.text('Dr. Amina Ochieng'), findsOneWidget);
    expect(find.text('Endocrinology'), findsOneWidget);
    expect(find.text('PATIENT ID'), findsOneWidget);
    expect(find.text('MC-8492-771'), findsOneWidget);
    expect(find.text('RESULT SUMMARY'), findsOneWidget);
  });

  testWidgets('renders attachments, notes and actions', (tester) async {
    await pumpDetails(tester);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pump();

    expect(find.text('Scanned Documents'), findsOneWidget);
    expect(find.text('2 Files'), findsOneWidget);
    expect(find.text('Lab_Results_Pg1.pdf'), findsOneWidget);
    expect(find.text('1.2 MB'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.byType(DoctorNotesCard), findsOneWidget);
    expect(find.text("Doctor's Notes"), findsOneWidget);
    expect(find.text('Signed Digitally'), findsOneWidget);
    expect(find.text('Share Record'), findsOneWidget);
    expect(find.text('Print PDF'), findsOneWidget);
  });
}
