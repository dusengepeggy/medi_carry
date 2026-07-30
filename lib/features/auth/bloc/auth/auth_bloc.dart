import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/auth_repository.dart';
import '../../models/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns global authentication state. Listens to [AuthRepository.user] and
/// exposes actions for sign-in, Google sign-in, password reset, and sign-out.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthMessageCleared>(_onMessageCleared);

    _userSubscription = _authRepository.user.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<AppUser> _userSubscription;

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: event.user.isNotEmpty
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: event.user,
      ),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true));
    try {
      await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      // Auth stream drives the status change; just clear the busy flag.
      emit(state.copyWith(isBusy: false));
    } on AuthException catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true));
    try {
      await _authRepository.signInWithGoogle();
      emit(state.copyWith(isBusy: false));
    } on AuthException catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
    } catch (error) {
      // Anything the repository failed to translate still has to clear the
      // busy flag, or the sign-in button spins for ever with no explanation.
      emit(state.copyWith(
        isBusy: false,
        errorMessage: 'Google sign-in failed: $error',
      ));
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true));
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(state.copyWith(
        isBusy: false,
        infoMessage: 'Password reset email sent to ${event.email}.',
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  void _onMessageCleared(AuthMessageCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith());
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
