part of 'signup_cubit.dart';

enum SignUpStatus { editing, submitting, success, failure }

/// Accumulated state of the 3-step sign-up wizard.
class SignUpState extends Equatable {
  const SignUpState({
    this.status = SignUpStatus.editing,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.enableBiometric = false,
    this.pin,
    this.existingUid,
    this.errorMessage,
  });

  final SignUpStatus status;

  // Step 1 — account.
  final String fullName;
  final String email;
  final String password;

  /// Set when the wizard is completing onboarding for a user who is already
  /// authenticated (Google). Null for a normal email sign-up, where the
  /// account is created by [SignUpCubit.submit] itself.
  final String? existingUid;

  /// True when this run is finishing a Google sign-in rather than creating an
  /// account from scratch.
  bool get isOnboardingExistingUser => existingUid != null;

  // Step 2 — medical profile.
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;

  // Step 3 — security.
  final bool enableBiometric;
  final String? pin;

  final String? errorMessage;

  bool get isStep1Valid =>
      fullName.trim().isNotEmpty &&
      email.trim().contains('@') &&
      password.length >= 8;

  /// Whether the account half of the wizard is satisfied.
  ///
  /// An onboarding run has no password to validate — the identity already
  /// exists — so it only needs the name and email Google supplied.
  bool get isAccountReady => isOnboardingExistingUser
      ? fullName.trim().isNotEmpty && email.trim().contains('@')
      : isStep1Valid;

  SignUpState copyWith({
    SignUpStatus? status,
    String? fullName,
    String? email,
    String? password,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    bool? enableBiometric,
    String? pin,
    String? existingUid,
    String? errorMessage,
  }) =>
      SignUpState(
        status: status ?? this.status,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        password: password ?? this.password,
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        enableBiometric: enableBiometric ?? this.enableBiometric,
        pin: pin ?? this.pin,
        existingUid: existingUid ?? this.existingUid,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        fullName,
        email,
        password,
        bloodType,
        allergies,
        chronicConditions,
        enableBiometric,
        pin,
        existingUid,
        errorMessage,
      ];
}
