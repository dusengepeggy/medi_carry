import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';
import '../../models/patient_profile.dart';

part 'signup_state.dart';

/// Drives the 3-step sign-up wizard: collects account (step 1), medical
/// profile (step 2), and security setup (step 3), then commits everything —
/// create Firebase user, write the Firestore profile, and persist the local
/// PIN / biometric preference.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required SecureStorageService secureStorage,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        _secureStorage = secureStorage,
        super(const SignUpState());

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final SecureStorageService _secureStorage;

  // Step 1.
  void updateAccount({
    required String fullName,
    required String email,
    required String password,
  }) =>
      emit(state.copyWith(
        fullName: fullName,
        email: email,
        password: password,
      ));

  // Step 2.
  void updateMedicalProfile({
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
  }) =>
      emit(state.copyWith(
        bloodType: bloodType,
        allergies: allergies,
        chronicConditions: chronicConditions,
      ));

  // Step 3.
  void setBiometric(bool enabled) =>
      emit(state.copyWith(enableBiometric: enabled));

  void setPin(String pin) => emit(state.copyWith(pin: pin));

  /// Commit the wizard. On success, the AuthBloc's auth stream picks up the
  /// newly created user and routes into the app.
  Future<void> submit() async {
    if (!state.isStep1Valid) {
      emit(state.copyWith(
        status: SignUpStatus.failure,
        errorMessage: 'Please complete your account details.',
      ));
      return;
    }
    if (state.pin == null || state.pin!.length != 4) {
      emit(state.copyWith(
        status: SignUpStatus.failure,
        errorMessage: 'Please set a 4-digit PIN.',
      ));
      return;
    }

    emit(state.copyWith(status: SignUpStatus.submitting));
    try {
      final user = await _authRepository.signUpWithEmail(
        email: state.email,
        password: state.password,
        displayName: state.fullName,
      );

      final profile = PatientProfile(
        uid: user.uid,
        fullName: state.fullName.trim(),
        email: state.email.trim(),
        patientId: UserRepository.generatePatientId(),
        bloodType: state.bloodType,
        allergies: state.allergies,
        chronicConditions: state.chronicConditions,
      );
      await _userRepository.createProfile(profile);

      await _secureStorage.setPin(state.pin!);
      await _secureStorage.setBiometricEnabled(state.enableBiometric);

      emit(state.copyWith(status: SignUpStatus.success));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: SignUpStatus.failure,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: SignUpStatus.failure,
        errorMessage: 'Could not complete sign-up. Please try again.',
      ));
    }
  }
}
