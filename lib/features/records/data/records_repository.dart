import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medical_record.dart';

/// Reads/writes a patient's records at Firestore `users/{uid}/records/{id}`.
///
/// Firestore offline persistence (enabled in `main.dart`) means reads resolve
/// from the local cache when offline — core to the app's offline-first promise.
/// Mirrors the shape of `UserRepository`.
class RecordsRepository {
  RecordsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _records(String uid) =>
      _firestore.collection('users').doc(uid).collection('records');

  /// Newest first.
  Stream<List<MedicalRecord>> watchRecords(String uid) => _records(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => MedicalRecord.fromMap(d.id, d.data()))
          .toList());

  Future<MedicalRecord?> getRecord(String uid, String id) async {
    final snap = await _records(uid).doc(id).get();
    final data = snap.data();
    return data == null ? null : MedicalRecord.fromMap(snap.id, data);
  }

  /// Adds a record and returns its generated id.
  Future<String> add(String uid, MedicalRecord record) async {
    final ref = await _records(uid).add(record.toMap());
    return ref.id;
  }

  Future<void> delete(String uid, String id) => _records(uid).doc(id).delete();
}
