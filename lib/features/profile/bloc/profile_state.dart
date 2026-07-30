part of 'profile_cubit.dart';

enum ProfileStatus { signedOut, loading, ready, error }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.signedOut, this.profile});

  final ProfileStatus status;

  /// Null while loading, when signed out, or when the document does not exist
  /// yet (a Google sign-in whose profile has not been written).
  final PatientProfile? profile;

  /// The patient's photo, or null for the placeholder avatar.
  String? get photoUrl => profile?.photoUrl;

  /// Whether this account still has to go through the profile + security
  /// steps that manual sign-up performs.
  ///
  /// True when there is no profile document at all (a Google sign-in, which
  /// creates a Firebase user and nothing else), and also when one exists
  /// without a patient ID — which is what an account created before this
  /// onboarding step existed looks like, so those get repaired rather than
  /// left half-configured.
  ///
  /// Only meaningful once [status] is [ProfileStatus.ready]; while loading it
  /// reports true simply because nothing has arrived yet.
  bool get needsOnboarding =>
      profile == null || profile!.patientId.trim().isEmpty;

  /// The best name available, falling back through the profile document.
  String? get fullName {
    final name = profile?.fullName.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  /// First name only, for greetings.
  String? get firstName => fullName?.split(' ').first;

  ProfileState copyWith({
    ProfileStatus? status,
    PatientProfile? profile,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
      );

  @override
  List<Object?> get props => [status, profile];
}
