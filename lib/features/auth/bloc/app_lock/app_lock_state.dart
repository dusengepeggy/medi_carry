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
    this.isBiometricAvailable = false,
    this.errorMessage,
  });

  final LockStatus status;
  final bool isPinSet;
  final bool isBiometricEnabled;

  /// Whether the device actually offers a biometric (or device passcode).
  /// Distinct from [isBiometricEnabled], which is the patient's choice — the
  /// settings screen has to be able to say "this phone can't do it" rather
  /// than offering a switch that silently does nothing.
  final bool isBiometricAvailable;

  final String? errorMessage;

  AppLockState copyWith({
    LockStatus? status,
    bool? isPinSet,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    String? errorMessage,
  }) =>
      AppLockState(
        status: status ?? this.status,
        isPinSet: isPinSet ?? this.isPinSet,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
        isBiometricAvailable:
            isBiometricAvailable ?? this.isBiometricAvailable,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        isPinSet,
        isBiometricEnabled,
        isBiometricAvailable,
        errorMessage,
      ];
}
