import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/core/services/emergency_card_store.dart';
import 'package:medi_carry/core/services/theme_mode_store.dart';
import 'package:medi_carry/core/theme/theme_cubit.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/profile/view/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockEmergencyCardStore extends Mock implements EmergencyCardStore {}

class MockThemeModeStore extends Mock implements ThemeModeStore {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockEmergencyCardStore emergencyCardStore;
  late MockThemeModeStore themeModeStore;

  const profile = PatientProfile(
    uid: 'u1',
    fullName: 'Sarah Johnson',
    email: 'sarah@example.com',
    patientId: 'MC-8829-41',
  );

  setUpAll(() {
    registerFallbackValue(
      const PatientProfile(uid: '', fullName: '', email: '', patientId: ''),
    );
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    emergencyCardStore = MockEmergencyCardStore();
    themeModeStore = MockThemeModeStore();
    when(() => themeModeStore.read()).thenAnswer((_) async => ThemeMode.system);
    when(() => themeModeStore.write(any())).thenAnswer((_) async {});
    when(() => emergencyCardStore.save(any())).thenAnswer((_) async {});
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Sarah Johnson'),
      ),
    );
    when(() => authRepository.signOut()).thenAnswer((_) async {});
    when(() => userRepository.watchProfile(any()))
        .thenAnswer((_) => Stream<PatientProfile?>.value(profile));
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
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
            BlocProvider(create: (_) => ThemeCubit(store: themeModeStore)),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
        ),
      ),
    );
    // Two async hops: the auth stream resolves the user, and only then does
    // the profile stream subscribe and emit.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('shows the patient name and ID from their profile',
      (tester) async {
    await pumpProfile(tester);

    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.text('PATIENT ID: MC-8829-41'), findsOneWidget);
  });

  testWidgets('renders the four settings options', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Update your name, age, and records'), findsOneWidget);
    expect(find.text('Health Insurance'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Password, FaceID, and data privacy'), findsOneWidget);
  });

  testWidgets('sign out delegates to the auth repository', (tester) async {
    await pumpProfile(tester);

    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pump();
    await tester.tap(find.text('Sign Out'));
    await tester.pump();

    verify(() => authRepository.signOut()).called(1);
  });

  testWidgets('falls back to the auth display name when no profile doc exists',
      (tester) async {
    when(() => userRepository.watchProfile(any()))
        .thenAnswer((_) => Stream<PatientProfile?>.value(null));
    await pumpProfile(tester);

    expect(find.text('Sarah Johnson'), findsOneWidget);
    // No patient ID is known, so the pill is hidden rather than showing blank.
    expect(find.textContaining('PATIENT ID'), findsNothing);
  });
}
