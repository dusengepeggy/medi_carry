import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/app/app_shell.dart';
import 'package:medi_carry/core/services/emergency_card_store.dart';
import 'package:medi_carry/core/services/theme_mode_store.dart';
import 'package:medi_carry/core/theme/theme_cubit.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/cards/view/cards_screen.dart';
import 'package:medi_carry/features/dashboard/view/home_screen.dart';
import 'package:medi_carry/features/profile/view/profile_screen.dart';
import 'package:medi_carry/features/records/view/medical_records_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockEmergencyCardStore extends Mock implements EmergencyCardStore {}

class MockThemeModeStore extends Mock implements ThemeModeStore {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockEmergencyCardStore emergencyCardStore;

  setUpAll(() {
    registerFallbackValue(
      const PatientProfile(uid: '', fullName: '', email: '', patientId: ''),
    );
  });

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    emergencyCardStore = MockEmergencyCardStore();
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Sarah Johnson'),
      ),
    );
    when(() => userRepository.watchProfile(any()))
        .thenAnswer((_) => const Stream<PatientProfile?>.empty());
    when(() => emergencyCardStore.save(any())).thenAnswer((_) async {});
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<UserRepository>.value(value: userRepository),
          RepositoryProvider<EmergencyCardStore>.value(
              value: emergencyCardStore),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)),
            BlocProvider(create: (_) => ThemeCubit(store: MockThemeModeStore())),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const AppShell()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the shared bottom nav and starts on Home',
      (tester) async {
    await pumpShell(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('My Cards'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('switching tabs swaps the visible screen', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('History'));
    await tester.pump();
    expect(find.byType(MedicalRecordsScreen), findsOneWidget);

    await tester.tap(find.text('My Cards'));
    await tester.pump();
    expect(find.byType(CardsScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets(
      'REGRESSION: repeatedly switching tabs does not grow the navigator stack',
      (tester) async {
    await pumpShell(tester);

    // Previously each tab tap was a Navigator.push, so this loop would stack
    // ~8 routes and leave duplicate screens alive.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('History'));
      await tester.pump();
      await tester.tap(find.text('Profile'));
      await tester.pump();
    }

    // Each tab root is instantiated exactly once by the IndexedStack.
    // skipOffstage: false is required because IndexedStack keeps inactive
    // tabs offstage — and counting them is precisely the point here.
    expect(
      find.byType(MedicalRecordsScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);

    // Profile is the tab we ended on, so it is the one actually on screen.
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('back from a non-Home tab returns to Home', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Simulate the Android system back gesture.
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    // Home is the visible tab again — the nav bar still shows all four tabs.
    expect(find.text('Home'), findsOneWidget);
  });
}
