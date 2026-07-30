part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Internal: emitted when the Firebase auth stream reports a change.
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Clears a transient error/message after it has been shown.
class AuthMessageCleared extends AuthEvent {
  const AuthMessageCleared();
}
