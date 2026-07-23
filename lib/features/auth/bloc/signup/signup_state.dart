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
    this.errorMessage,
  });

  final SignUpStatus status;

  // Step 1 — account.
  final String fullName;
  final String email;
  final String password;

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
        errorMessage,
      ];
}
