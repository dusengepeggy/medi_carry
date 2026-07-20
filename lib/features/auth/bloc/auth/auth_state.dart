part of 'auth_bloc.dart';

enum AuthStatus {
  /// Startup — we don't yet know if a user is signed in.
  unknown,

  /// A Firebase user is signed in.
  authenticated,

  /// No user is signed in.
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user = AppUser.empty,
    this.isBusy = false,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthStatus status;
  final AppUser user;

  /// True while an auth action (sign-in/out, reset) is in flight.
  final bool isBusy;

  /// Transient error to surface (e.g. via SnackBar), then clear.
  final String? errorMessage;

  /// Transient info to surface (e.g. "Reset email sent"), then clear.
  final String? infoMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isBusy,
    String? errorMessage,
    String? infoMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
        infoMessage: infoMessage,
      );

  @override
  List<Object?> get props =>
      [status, user, isBusy, errorMessage, infoMessage];
}
