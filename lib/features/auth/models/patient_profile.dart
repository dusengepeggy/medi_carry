import 'package:equatable/equatable.dart';

/// The patient's profile document stored at Firestore `users/{uid}`.
///
/// Combines account fields (captured at sign-up step 1), the medical profile
/// (step 2), and the details captured on the Edit Profile screen. Everything
/// beyond the account identity is optional so the profile can be created
/// before every field is filled in.
class PatientProfile extends Equatable {
  const PatientProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.patientId,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.dateOfBirth,
    this.gender,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final String uid;
  final String fullName;
  final String email;

  /// Human-readable ID shown on the profile screen, e.g. `MC-8829-41`.
  final String patientId;

  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;

  /// Stored as an ISO-8601 date (`yyyy-MM-dd`) so it sorts and parses cleanly
  /// regardless of the display locale.
  final String? dateOfBirth;

  final String? gender;

  /// Who to contact in an emergency — surfaced by the Emergency Info feature,
  /// so it must be readable offline.
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'patientId': patientId,
        'bloodType': bloodType,
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
      };

  factory PatientProfile.fromMap(Map<String, dynamic> map) => PatientProfile(
        uid: map['uid'] as String? ?? '',
        fullName: map['fullName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        patientId: map['patientId'] as String? ?? '',
        bloodType: map['bloodType'] as String?,
        allergies: List<String>.from(map['allergies'] as List? ?? const []),
        chronicConditions:
            List<String>.from(map['chronicConditions'] as List? ?? const []),
        dateOfBirth: map['dateOfBirth'] as String?,
        gender: map['gender'] as String?,
        emergencyContactName: map['emergencyContactName'] as String?,
        emergencyContactPhone: map['emergencyContactPhone'] as String?,
      );

  PatientProfile copyWith({
    String? fullName,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? dateOfBirth,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) =>
      PatientProfile(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email,
        patientId: patientId,
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
      );

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        patientId,
        bloodType,
        allergies,
        chronicConditions,
        dateOfBirth,
        gender,
        emergencyContactName,
        emergencyContactPhone,
      ];
}
