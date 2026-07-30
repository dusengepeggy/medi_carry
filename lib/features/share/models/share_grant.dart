import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A share the patient has granted — the audit + revoke record behind the
/// "Active Shares" list. Stored at `users/{uid}/shares/{id}`.
///
/// The QR itself is self-contained and offline; this grant is the patient's
/// own control surface (the privacy non-negotiable), not what the recipient
/// reads. `expiresAt` is also embedded in the QR payload so a recipient app can
/// refuse an expired share without the network.
class ShareGrant extends Equatable {
  const ShareGrant({
    required this.id,
    required this.recipientLabel,
    required this.categories,
    required this.createdAt,
    required this.expiresAt,
    this.revoked = false,
  });

  final String id;

  /// Who/what the share is for, e.g. "In-person QR" or a clinic name.
  final String recipientLabel;

  /// The [RecordCategory] ids (plus profile pseudo-categories) included.
  final List<String> categories;

  final DateTime createdAt;
  final DateTime expiresAt;
  final bool revoked;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Active = neither revoked nor expired.
  bool get isActive => !revoked && !isExpired;

  /// e.g. "Expires in 2 days" / "Expired".
  String get expiryLabel {
    if (revoked) return 'Revoked';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays >= 1) {
      final d = remaining.inDays;
      return 'Expires in $d ${d == 1 ? 'day' : 'days'}';
    }
    if (remaining.inHours >= 1) {
      final h = remaining.inHours;
      return 'Expires in $h ${h == 1 ? 'hour' : 'hours'}';
    }
    return 'Expires soon';
  }

  Map<String, dynamic> toMap() => {
        'recipientLabel': recipientLabel,
        'categories': categories,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'revoked': revoked,
      };

  factory ShareGrant.fromMap(String id, Map<String, dynamic> map) => ShareGrant(
        id: id,
        recipientLabel: map['recipientLabel'] as String? ?? 'Share',
        categories: List<String>.from(map['categories'] as List? ?? const []),
        createdAt: _toDate(map['createdAt']),
        expiresAt: _toDate(map['expiresAt']),
        revoked: map['revoked'] as bool? ?? false,
      );

  static DateTime _toDate(Object? value) => switch (value) {
        Timestamp t => t.toDate(),
        String s => DateTime.tryParse(s) ?? DateTime.now(),
        _ => DateTime.now(),
      };

  @override
  List<Object?> get props =>
      [id, recipientLabel, categories, createdAt, expiresAt, revoked];
}
