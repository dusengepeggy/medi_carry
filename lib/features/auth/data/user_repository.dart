import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_profile.dart';

/// Reads/writes the patient profile document at Firestore `users/{uid}`.
///
/// Firestore offline persistence (enabled at app start) means reads resolve
/// from the local cache when offline.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createProfile(PatientProfile profile) =>
      _users.doc(profile.uid).set(profile.toMap());

  /// Merges edited fields into the existing profile document. Uses `merge` so
  /// a partial write never clobbers fields this screen doesn't manage (e.g.
  /// allergies captured at sign-up).
  Future<void> updateProfile(PatientProfile profile) =>
      _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));

  Future<PatientProfile?> fetchProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return PatientProfile.fromMap(data);
  }

  Stream<PatientProfile?> watchProfile(String uid) =>
      _users.doc(uid).snapshots().map(
            (snap) => snap.data() == null
                ? null
                : PatientProfile.fromMap(snap.data()!),
          );

  /// Generates a human-readable patient ID like `MC-8829-41`.
  static String generatePatientId([Random? random]) {
    final rand = random ?? Random();
    final part1 = rand.nextInt(9000) + 1000; // 4 digits
    final part2 = rand.nextInt(90) + 10; // 2 digits
    return 'MC-$part1-$part2';
  }
}
