import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/share_grant.dart';

/// Reads/writes the patient's share grants at `users/{uid}/shares/{id}`.
///
/// This is the audit/revoke surface for the "Active Shares" list. Mirrors
/// `RecordsRepository`.
class SharesRepository {
  SharesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _shares(String uid) =>
      _firestore.collection('users').doc(uid).collection('shares');

  /// All grants, newest first (the UI filters to the active ones).
  Stream<List<ShareGrant>> watchShares(String uid) => _shares(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ShareGrant.fromMap(d.id, d.data())).toList());

  Future<String> add(String uid, ShareGrant grant) async {
    final ref = await _shares(uid).add(grant.toMap());
    return ref.id;
  }

  Future<void> revoke(String uid, String id) =>
      _shares(uid).doc(id).update({'revoked': true});

  /// Revokes every grant that is still live — the patient's panic button when
  /// they no longer know who holds a code.
  ///
  /// Written as one batch so the list never ends up half-revoked if the
  /// connection drops midway.
  Future<int> revokeAllActive(String uid) async {
    final snapshot = await _shares(uid).get();
    final live = snapshot.docs.where(
      (doc) => ShareGrant.fromMap(doc.id, doc.data()).isActive,
    );
    if (live.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final doc in live) {
      batch.update(doc.reference, {'revoked': true});
    }
    await batch.commit();
    return live.length;
  }
}
