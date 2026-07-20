import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/share/view/share_records_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Sarah Johnson'),
      ),
    );
  });

  Future<void> pumpShare(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(authRepository: authRepository),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ShareRecordsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the header and quick share QR card', (tester) async {
    await pumpShare(tester);

    expect(find.text('Hi, Sarah'), findsOneWidget);
    expect(find.text('Share Records'), findsOneWidget);
    expect(
      find.text(
        'Securely provide access to your health history to doctors, clinics, '
        'or caregivers.',
      ),
      findsOneWidget,
    );

    // Quick Share card — the offline QR hand-off.
    expect(find.text('In-Person Quick Share'), findsOneWidget);
    expect(find.text('Generate QR Code'), findsOneWidget);
    expect(
      find.text(
        'Immediate, temporary access during a consultation. Works perfectly '
        'offline.',
      ),
      findsOneWidget,
    );
    expect(find.text('Show QR'), findsOneWidget);
  });

  testWidgets('renders export, access settings and active shares',
      (tester) async {
    await pumpShare(tester);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.text('Export History'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Access Settings'), findsOneWidget);
    expect(find.text('DURATION'), findsOneWidget);
    expect(find.text('End-to-End Encrypted'), findsOneWidget);
    expect(find.text('Send Link'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pump();

    expect(find.text('Active Shares'), findsOneWidget);
    expect(find.text('Nairobi General Hospital'), findsOneWidget);
    expect(find.text('Expires in 2 days'), findsOneWidget);
  });

  testWidgets('duration selection updates the field', (tester) async {
    await pumpShare(tester);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.text('24 Hours'), findsOneWidget);

    await tester.tap(find.text('24 Hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 Days').last);
    await tester.pumpAndSettle();

    expect(find.text('7 Days'), findsOneWidget);
    expect(find.text('24 Hours'), findsNothing);
  });
}
