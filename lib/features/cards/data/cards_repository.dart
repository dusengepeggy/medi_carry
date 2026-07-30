import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insurance_card.dart';

/// Reads/writes the patient's insurance and ID cards at `users/{uid}/cards`.
///
/// Firestore's offline cache is what makes this useful: the whole point of
/// carrying a card in the app is being able to show the number at a reception
/// desk with no signal.
class CardsRepository {
  CardsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cards(String uid) =>
      _firestore.collection('users').doc(uid).collection('cards');

  /// Newest first.
  Stream<List<InsuranceCard>> watchCards(String uid) => _cards(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => InsuranceCard.fromMap(d.id, d.data())).toList());

  Future<String> add(String uid, InsuranceCard card) async {
    final ref = await _cards(uid).add(card.toMap());
    return ref.id;
  }

  Future<void> update(String uid, InsuranceCard card) =>
      _cards(uid).doc(card.id).set(card.toMap());

  Future<void> delete(String uid, String id) => _cards(uid).doc(id).delete();
}
