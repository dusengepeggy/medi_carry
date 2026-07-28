import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/patient_profile.dart';

/// The curated subset of a patient's profile that may be read in an emergency
/// — deliberately narrow, because it is the only data exposed before the app
/// is unlocked.
class EmergencyCard {
  const EmergencyCard({
    required this.fullName,
    required this.patientId,
    this.bloodType,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.updatedAt,
  });

  final String fullName;
  final String patientId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// When this snapshot was taken, so a responder can judge how current it is.
  final DateTime? updatedAt;

  factory EmergencyCard.fromProfile(PatientProfile p) => EmergencyCard(
        fullName: p.fullName,
        patientId: p.patientId,
        bloodType: p.bloodType,
        allergies: p.allergies,
        chronicConditions: p.chronicConditions,
        emergencyContactName: p.emergencyContactName,
        emergencyContactPhone: p.emergencyContactPhone,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'patientId': patientId,
        'bloodType': bloodType,
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory EmergencyCard.fromJson(Map<String, dynamic> json) => EmergencyCard(
        fullName: json['fullName'] as String? ?? '',
        patientId: json['patientId'] as String? ?? '',
        bloodType: json['bloodType'] as String?,
        allergies: List<String>.from(json['allergies'] as List? ?? const []),
        chronicConditions:
            List<String>.from(json['chronicConditions'] as List? ?? const []),
        emergencyContactName: json['emergencyContactName'] as String?,
        emergencyContactPhone: json['emergencyContactPhone'] as String?,
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.tryParse(json['updatedAt'] as String),
      );

  bool get hasContact =>
      (emergencyContactPhone ?? '').trim().isNotEmpty;
}

/// Persists the [EmergencyCard] on-device so it can be shown while the app is
/// **locked, offline, and cold-started**.
///
/// The brief's emergency scenario is an unconscious patient, so this data
/// cannot depend on the network or on the Firestore cache being warm — hence a
/// dedicated snapshot, refreshed whenever the profile is read.
class EmergencyCardStore {
  EmergencyCardStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _key = 'emergency_card';

  /// Refresh the snapshot. Called whenever a profile is loaded.
  Future<void> save(PatientProfile profile) => _storage.write(
        key: _key,
        value: jsonEncode(EmergencyCard.fromProfile(profile).toJson()),
      );

  /// Read the snapshot, or null if none has been stored yet.
  Future<EmergencyCard?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return EmergencyCard.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // A corrupt snapshot must not block the emergency screen.
      return null;
    }
  }

  /// Clear on sign-out — the next patient on this device must not see it.
  Future<void> clear() => _storage.delete(key: _key);
}
