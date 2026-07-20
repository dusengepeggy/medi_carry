import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/dashboard/view/home_screen.dart';
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

  Future<void> pumpDashboard(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so layout overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(authRepository: authRepository),
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the dashboard sections from the design', (tester) async {
    await pumpDashboard(tester);

    // Welcome + emergency action.
    expect(find.textContaining('Sarah'), findsOneWidget);
    expect(find.text('Here is your health overview for today.'), findsOneWidget);
    expect(find.text('Emergency Info'), findsOneWidget);

    // Medication card.
    expect(find.text('NEXT MEDICATION'), findsOneWidget);
    expect(find.text('Lisinopril'), findsOneWidget);
    expect(find.text('In 2 hours'), findsOneWidget);
    expect(find.text('Mark as Taken'), findsOneWidget);

    // Vitals card.
    expect(find.text('LATEST BP'), findsOneWidget);
    expect(find.text('118/76'), findsOneWidget);
    expect(find.text('mmHg'), findsOneWidget);
  });

  testWidgets('renders activity and add-record cards', (tester) async {
    await pumpDashboard(tester);

    // Scroll the lower cards into view.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('See All'), findsOneWidget);
    expect(find.text('Comprehensive Metabolic Panel'), findsOneWidget);
    expect(find.text('Oct 12 • City Lab'), findsOneWidget);
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
