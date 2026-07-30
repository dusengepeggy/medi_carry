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
      isBiometricAvailable: await _biometric.isAvailable(),
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
      isBiometricAvailable: await _biometric.isAvailable(),
    ));
  }

  /// Re-reads the stored lock settings without changing the lock status.
  /// Used by the security settings screen when it opens.
  Future<void> refresh() async {
    emit(state.copyWith(
      isPinSet: await _secureStorage.hasPin(),
      isBiometricEnabled: await _secureStorage.isBiometricEnabled(),
      isBiometricAvailable: await _biometric.isAvailable(),
    ));
  }

  /// Sets the app-lock PIN for an account that has none — accounts created
  /// before the security step existed, which would otherwise have no way to
  /// ever turn the lock on.
  Future<void> setPin(String pin) async {
    await _secureStorage.setPin(pin);
    emit(state.copyWith(isPinSet: true));
  }

  /// Replaces the PIN, but only on proof of the current one.
  ///
  /// Returns false when [currentPin] is wrong — without this check anyone
  /// holding an unlocked phone could lock the owner out of their own records.
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await _secureStorage.verifyPin(currentPin)) {
      emit(state.copyWith(errorMessage: 'That is not your current PIN.'));
      return false;
    }
    await _secureStorage.setPin(newPin);
    emit(state.copyWith(isPinSet: true));
    return true;
  }

  /// Turns biometric unlock on, proving it works before storing the choice.
  ///
  /// Requires a PIN: the biometric is a shortcut past the PIN, never a
  /// replacement for it — a failed or unenrolled scanner must still leave the
  /// patient a way in.
  Future<bool> enableBiometric() async {
    if (!state.isPinSet) {
      emit(state.copyWith(
        errorMessage: 'Set a PIN first — it is the fallback if a scan fails.',
      ));
      return false;
    }
    if (!await _biometric.isAvailable()) {
      emit(state.copyWith(
        errorMessage: 'This device has no biometric or screen lock set up.',
        isBiometricAvailable: false,
      ));
      return false;
    }
    final confirmed = await _biometric.authenticate(
      reason: 'Confirm your identity to enable biometric unlock',
    );
    if (!confirmed) {
      emit(state.copyWith(errorMessage: 'Biometric check failed.'));
      return false;
    }
    await _secureStorage.setBiometricEnabled(true);
    emit(state.copyWith(isBiometricEnabled: true, isBiometricAvailable: true));
    return true;
  }

  Future<void> disableBiometric() async {
    await _secureStorage.setBiometricEnabled(false);
    emit(state.copyWith(isBiometricEnabled: false));
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
