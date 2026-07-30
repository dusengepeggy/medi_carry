import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  const user = AppUser(uid: 'u1', email: 'a@b.com');

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.user)
        .thenAnswer((_) => const Stream<AppUser>.empty());
  });

  group('AuthBloc', () {
    test('initial state is unknown', () {
      final bloc = AuthBloc(authRepository: authRepository);
      expect(bloc.state.status, AuthStatus.unknown);
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits authenticated when the user stream yields a user',
      setUp: () => when(() => authRepository.user)
          .thenAnswer((_) => Stream<AppUser>.value(user)),
      build: () => AuthBloc(authRepository: authRepository),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when the user stream yields empty',
      setUp: () => when(() => authRepository.user)
          .thenAnswer((_) => Stream<AppUser>.value(AppUser.empty)),
      build: () => AuthBloc(authRepository: authRepository),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-in success toggles isBusy on then off',
      setUp: () => when(
        () => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user),
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'a@b.com', password: 'password1'),
      ),
      expect: () => [
        isA<AuthState>().having((s) => s.isBusy, 'isBusy', true),
        isA<AuthState>().having((s) => s.isBusy, 'isBusy', false),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-in failure surfaces an error message',
      setUp: () => when(
        () => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Incorrect email or password.')),
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'a@b.com', password: 'wrong'),
      ),
      expect: () => [
        isA<AuthState>().having((s) => s.isBusy, 'isBusy', true),
        isA<AuthState>()
            .having((s) => s.isBusy, 'isBusy', false)
            .having((s) => s.errorMessage, 'errorMessage',
                'Incorrect email or password.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-out delegates to the repository',
      setUp: () => when(() => authRepository.signOut()).thenAnswer((_) async {}),
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      verify: (_) => verify(() => authRepository.signOut()).called(1),
    );
  });
}
