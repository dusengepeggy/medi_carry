import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/secure_storage_service.dart';
import 'package:medi_carry/features/auth/bloc/signup/signup_cubit.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/profile/bloc/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late MockAuthRepository authRepository;
  late MockSecureStorage secureStorage;
  late UserRepository userRepository;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    authRepository = MockAuthRepository();
    secureStorage = MockSecureStorage();
    firestore = FakeFirebaseFirestore();
    userRepository = UserRepository(firestore: firestore);
    when(() => secureStorage.setPin(any())).thenAnswer((_) async {});
    when(() => secureStorage.setBiometricEnabled(any()))
        .thenAnswer((_) async {});
  });

  SignUpCubit buildCubit() => SignUpCubit(
        authRepository: authRepository,
        userRepository: userRepository,
        secureStorage: secureStorage,
      );

  group('onboarding an already-authenticated (Google) user', () {
    test('writes the profile without creating a second account', () async {
      final cubit = buildCubit()
        ..adoptAuthenticatedUser(
          uid: 'google-uid',
          fullName: 'Peggy Dusenge',
          email: 'peggy@example.com',
        )
        ..updateMedicalProfile(
          bloodType: 'O+',
          allergies: ['Penicillin'],
          chronicConditions: ['Asthma'],
        )
        ..setPin('1234');

      await cubit.submit();

      expect(cubit.state.status, SignUpStatus.success);
      // Crucially: Google already made the account. Creating another would
      // fail with email-already-in-use.
      verifyNever(() => authRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ));

      final saved = await userRepository.fetchProfile('google-uid');
      expect(saved, isNotNull);
      expect(saved!.fullName, 'Peggy Dusenge');
      expect(saved.email, 'peggy@example.com');
      expect(saved.bloodType, 'O+');
      expect(saved.allergies, ['Penicillin']);
      expect(saved.chronicConditions, ['Asthma']);
      // The patient ID is what the rest of the app identifies them by.
      expect(saved.patientId, isNotEmpty);
      expect(saved.patientId, startsWith('MC-'));
    });

    test('sets the offline app-lock PIN, as manual sign-up does', () async {
      final cubit = buildCubit()
        ..adoptAuthenticatedUser(
          uid: 'google-uid',
          fullName: 'Peggy Dusenge',
          email: 'peggy@example.com',
        )
        ..setBiometric(true)
        ..setPin('4321');

      await cubit.submit();

      verify(() => secureStorage.setPin('4321')).called(1);
      verify(() => secureStorage.setBiometricEnabled(true)).called(1);
    });

    test('still requires a PIN before it will commit', () async {
      final cubit = buildCubit()
        ..adoptAuthenticatedUser(
          uid: 'google-uid',
          fullName: 'Peggy Dusenge',
          email: 'peggy@example.com',
        );

      await cubit.submit();

      expect(cubit.state.status, SignUpStatus.failure);
      expect(cubit.state.errorMessage, contains('PIN'));
      expect(await userRepository.fetchProfile('google-uid'), isNull);
    });

    test('does not demand a password it can never have', () {
      final state = const SignUpState().copyWith(
        existingUid: 'google-uid',
        fullName: 'Peggy Dusenge',
        email: 'peggy@example.com',
      );

      // A Google identity carries no password, so the manual-signup rule would
      // permanently block onboarding.
      expect(state.isStep1Valid, isFalse);
      expect(state.isAccountReady, isTrue);
      expect(state.isOnboardingExistingUser, isTrue);
    });
  });

  group('ProfileState.needsOnboarding', () {
    test('is true when Google has authenticated but written no profile', () {
      const state = ProfileState(status: ProfileStatus.ready);
      expect(state.needsOnboarding, isTrue);
    });

    test('is true for a profile left without a patient ID', () {
      const state = ProfileState(
        status: ProfileStatus.ready,
        profile: PatientProfile(
          uid: 'u1',
          fullName: 'Peggy',
          email: 'peggy@example.com',
          patientId: '  ',
        ),
      );
      expect(state.needsOnboarding, isTrue);
    });

    test('is false once the profile is complete', () {
      const state = ProfileState(
        status: ProfileStatus.ready,
        profile: PatientProfile(
          uid: 'u1',
          fullName: 'Peggy',
          email: 'peggy@example.com',
          patientId: 'MC-8829-41',
        ),
      );
      expect(state.needsOnboarding, isFalse);
    });
  });

  group('manual sign-up is unchanged', () {
    test('still creates the account, then the profile and PIN', () async {
      when(() => authRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => const AppUser(uid: 'email-uid'));

      final cubit = buildCubit()
        ..updateAccount(
          fullName: 'Alex Mwangi',
          email: 'alex@example.com',
          password: 'supersecret',
        )
        ..setPin('1111');

      await cubit.submit();

      expect(cubit.state.status, SignUpStatus.success);
      verify(() => authRepository.signUpWithEmail(
            email: 'alex@example.com',
            password: 'supersecret',
            displayName: 'Alex Mwangi',
          )).called(1);
      final saved = await userRepository.fetchProfile('email-uid');
      expect(saved!.patientId, startsWith('MC-'));
    });
  });
}
