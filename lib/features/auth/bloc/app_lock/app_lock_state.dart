part of 'app_lock_cubit.dart';

enum LockStatus {
  /// Not yet evaluated.
  unknown,

  /// Authenticated but the app must be unlocked (PIN/biometric) to proceed.
  locked,

  /// Unlocked (or no local lock configured).
  unlocked,
}

class AppLockState extends Equatable {
  const AppLockState({
    this.status = LockStatus.unknown,
    this.isPinSet = false,
    this.isBiometricEnabled = false,
    this.errorMessage,
  });

  final LockStatus status;
  final bool isPinSet;
  final bool isBiometricEnabled;
  final String? errorMessage;

  AppLockState copyWith({
    LockStatus? status,
    bool? isPinSet,
    bool? isBiometricEnabled,
    String? errorMessage,
  }) =>
      AppLockState(
        status: status ?? this.status,
        isPinSet: isPinSet ?? this.isPinSet,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, isPinSet, isBiometricEnabled, errorMessage];
}
