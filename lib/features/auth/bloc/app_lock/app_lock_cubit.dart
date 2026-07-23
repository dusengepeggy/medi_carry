import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/emergency_card_store.dart';
import '../../../../core/services/secure_storage_service.dart';

part 'app_lock_state.dart';

/// Manages the offline app-lock. After a Firebase session is restored on a
/// cold start, the app is [LockStatus.locked] until the user unlocks with
/// their biometric or 4-digit PIN — all of which works with no connectivity.
///
/// After an *interactive* sign-in/sign-up in the current session the app is
/// already unlocked ([markUnlocked]).
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit({
    required SecureStorageService secureStorage,
    required BiometricService biometric,
    EmergencyCardStore? emergencyCardStore,
  })  : _secureStorage = secureStorage,
        _biometric = biometric,
        _emergencyCardStore = emergencyCardStore,
        super(const AppLockState());

  final SecureStorageService _secureStorage;
  final BiometricService _biometric;

  /// Optional so tests can omit it; when present, the offline emergency
  /// snapshot is wiped on sign-out so the next patient on this device cannot
  /// read the previous one's medical data.
  final EmergencyCardStore? _emergencyCardStore;

  /// Called when the app launches with an already-authenticated user.
  /// Locks if a PIN was previously set; otherwise proceeds unlocked.
  Future<void> loadForStartup() async {
    final isPinSet = await _secureStorage.hasPin();
    final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    emit(state.copyWith(
      status: isPinSet ? LockStatus.locked : LockStatus.unlocked,
      isPinSet: isPinSet,
      isBiometricEnabled: isBiometricEnabled,
    ));
  }

  /// Called right after an interactive login/sign-up — no unlock needed.
  Future<void> markUnlocked() async {
    final isPinSet = await _secureStorage.hasPin();
    final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    emit(state.copyWith(
      status: LockStatus.unlocked,
      isPinSet: isPinSet,
      isBiometricEnabled: isBiometricEnabled,
    ));
  }

  /// Re-lock (e.g. when the app is resumed after being backgrounded).
  void lock() {
    if (state.isPinSet) emit(state.copyWith(status: LockStatus.locked));
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await _secureStorage.verifyPin(pin);
    if (ok) {
      emit(state.copyWith(status: LockStatus.unlocked));
    } else {
      emit(state.copyWith(errorMessage: 'Incorrect PIN. Try again.'));
    }
    return ok;
  }

  Future<bool> unlockWithBiometric() async {
    if (!state.isBiometricEnabled) return false;
    final ok = await _biometric.authenticate();
    if (ok) emit(state.copyWith(status: LockStatus.unlocked));
    return ok;
  }

  /// On sign-out, drop the local lock data and reset state.
  Future<void> handleSignedOut() async {
    await _secureStorage.clear();
    await _emergencyCardStore?.clear();
    emit(const AppLockState(status: LockStatus.unlocked));
  }
}
