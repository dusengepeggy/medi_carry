import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/secure_storage_service.dart';
import 'package:medi_carry/features/auth/bloc/signup/signup_cubit.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockSecureStorage secureStorage;

  setUpAll(() {
    registerFallbackValue(
      const PatientProfile(uid: '', fullName: '', email: '', patientId: ''),
    );
  });

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    secureStorage = MockSecureStorage();
  });

  SignUpCubit build() => SignUpCubit(
        authRepository: authRepository,
        userRepository: userRepository,
        secureStorage: secureStorage,
      );

  void fillValidWizard(SignUpCubit cubit) {
    cubit.updateAccount(
      fullName: 'Sarah Johnson',
      email: 'sarah@example.com',
      password: 'password1',
    );
    cubit.updateMedicalProfile(
      bloodType: 'O+',
      allergies: const ['Penicillin'],
      chronicConditions: const [],
    );
    cubit.setBiometric(true);
    cubit.setPin('1234');
  }

  group('SignUpCubit.submit', () {
    blocTest<SignUpCubit, SignUpState>(
      'creates the user, writes the profile, persists PIN + biometric, then '
      'emits success',
      setUp: () {
        when(
          () => authRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => const AppUser(uid: 'u1'));
        when(() => userRepository.createProfile(any()))
            .thenAnswer((_) async {});
        when(() => secureStorage.setPin(any())).thenAnswer((_) async {});
        when(() => secureStorage.setBiometricEnabled(any()))
            .thenAnswer((_) async {});
      },
      build: build,
      act: (cubit) {
        fillValidWizard(cubit);
        return cubit.submit();
      },
      skip: 4, // the four update* emissions before submit
      expect: () => [
        isA<SignUpState>()
            .having((s) => s.status, 'status', SignUpStatus.submitting),
        isA<SignUpState>()
            .having((s) => s.status, 'status', SignUpStatus.success),
      ],
      verify: (_) {
        verify(() => userRepository.createProfile(any())).called(1);
        verify(() => secureStorage.setPin('1234')).called(1);
        verify(() => secureStorage.setBiometricEnabled(true)).called(1);
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'fails when no 4-digit PIN is set',
      build: build,
      act: (cubit) {
        cubit.updateAccount(
          fullName: 'Sarah',
          email: 'sarah@example.com',
          password: 'password1',
        );
        return cubit.submit();
      },
      skip: 1,
      expect: () => [
        isA<SignUpState>()
            .having((s) => s.status, 'status', SignUpStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Please set a 4-digit PIN.'),
      ],
      verify: (_) {
        verifyNever(() => authRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            ));
      },
    );

    blocTest<SignUpCubit, SignUpState>(
      'surfaces the auth error when account creation fails',
      setUp: () => when(
        () => authRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(const AuthException('An account already exists.')),
      build: build,
      act: (cubit) {
        fillValidWizard(cubit);
        return cubit.submit();
      },
      skip: 5, // four updates + submitting
      expect: () => [
        isA<SignUpState>()
            .having((s) => s.status, 'status', SignUpStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'An account already exists.'),
      ],
    );
  });
}
