import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication.dart';

/// Reads/writes the patient's medications at `users/{uid}/medications/{id}`.
///
/// Firestore offline persistence means the list resolves from the local cache
/// with no connectivity, which matters because the dashboard's "next dose"
/// must be right whether or not the phone has signal.
class MedicationsRepository {
  MedicationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _medications(String uid) =>
      _firestore.collection('users').doc(uid).collection('medications');

  /// Newest first.
  Stream<List<Medication>> watchMedications(String uid) => _medications(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Medication.fromMap(d.id, d.data())).toList());

  Future<String> add(String uid, Medication medication) async {
    final ref = await _medications(uid).add(medication.toMap());
    return ref.id;
  }

  Future<void> update(String uid, Medication medication) =>
      _medications(uid).doc(medication.id).set(medication.toMap());

  /// Records that a dose was just taken.
  Future<void> markTaken(String uid, String id, DateTime at) =>
      _medications(uid).doc(id).update({'lastTakenAt': Timestamp.fromDate(at)});

  Future<void> setRemindersEnabled(String uid, String id, bool enabled) =>
      _medications(uid).doc(id).update({'remindersEnabled': enabled});

  Future<void> delete(String uid, String id) =>
      _medications(uid).doc(id).delete();
}
