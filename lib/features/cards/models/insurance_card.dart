import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/models/stored_attachment.dart';
import '../../../core/theme/app_colors.dart';

/// The health-cover schemes a MediCarry patient is likely to hold.
///
/// Rwanda's public schemes (Mutuelle de Santé / CBHI, RAMA, MMI) now sit under
/// RSSB, but patients still carry and name the older cards, so each is listed
/// separately rather than collapsed — a card the patient can't find by name is
/// a card they won't add. [other] carries a free-text name for anything not
/// covered here, so the list is never a dead end.
enum InsuranceProvider {
  rssb('RSSB', 'Rwanda Social Security Board', AppColors.navy),
  mutuelle('Mutuelle de Santé', 'Community-Based Health Insurance (CBHI)',
      AppColors.olive),
  rama('RAMA', 'La Rwandaise d’Assurance Maladie', AppColors.indigo),
  mmi('MMI', 'Military Medical Insurance', AppColors.slate),
  radiant('Radiant', 'Radiant Insurance Company', AppColors.indigoFinal),
  sanlam('Sanlam', 'Sanlam / Saham Assurance', AppColors.slateGray),
  britam('Britam', 'Britam Insurance', AppColors.indigo),
  prime('Prime Insurance', 'Prime Insurance Rwanda', AppColors.navy),
  edenCare('Eden Care', 'Eden Care Medical', AppColors.olive),
  oldMutual('Old Mutual', 'Old Mutual / UAP', AppColors.slate),
  jubilee('Jubilee', 'Jubilee Health Insurance', AppColors.indigoFinal),
  nhif('NHIF / SHA', 'National health insurance (Kenya)', AppColors.slateGray),
  aar('AAR', 'AAR Insurance', AppColors.indigo),
  other('Other', 'Another provider', AppColors.slate);

  const InsuranceProvider(this.label, this.description, this.accent);

  /// Short name shown on the card.
  final String label;

  /// Longer name shown in the picker.
  final String description;

  /// Card treatment colour.
  final Color accent;

  String get id => name;

  static InsuranceProvider fromId(String? id) =>
      InsuranceProvider.values.firstWhere(
        (p) => p.name == id,
        orElse: () => InsuranceProvider.other,
      );
}

/// What kind of card this is — patients often hold a national scheme card and
/// a private top-up, plus a hospital patient card.
enum CardType {
  insurance('Insurance'),
  patientId('Patient ID'),
  loyalty('Clinic card');

  const CardType(this.label);
  final String label;

  String get id => name;

  static CardType fromId(String? id) => CardType.values.firstWhere(
        (t) => t.name == id,
        orElse: () => CardType.insurance,
      );
}

/// An insurance / patient-ID card, stored at `users/{uid}/cards/{id}`.
///
/// The scanned card itself lives in [documents]; the typed fields exist so the
/// key numbers are readable (and shareable) without opening an image, which
/// matters at a reception desk with no signal.
class InsuranceCard extends Equatable {
  const InsuranceCard({
    required this.id,
    required this.provider,
    this.providerName = '',
    this.type = CardType.insurance,
    this.memberName = '',
    required this.memberNumber,
    this.policyNumber = '',
    this.scheme = '',
    this.validFrom,
    this.validUntil,
    this.notes = '',
    this.documents = const [],
    required this.createdAt,
  });

  final String id;
  final InsuranceProvider provider;

  /// Free-text provider name, used when [provider] is [InsuranceProvider.other].
  final String providerName;

  final CardType type;

  /// Who the card belongs to (often a dependant rather than the account owner).
  final String memberName;

  /// The membership / card number — the field a clinic actually asks for.
  final String memberNumber;

  final String policyNumber;

  /// Plan or scheme name, e.g. "Category 3", "Gold".
  final String scheme;

  final DateTime? validFrom;
  final DateTime? validUntil;

  final String notes;

  /// Photos or PDFs of the physical card.
  final List<StoredAttachment> documents;

  final DateTime createdAt;

  /// The name to display: the free-text one for "Other", the enum label
  /// otherwise.
  String get displayProvider =>
      provider == InsuranceProvider.other && providerName.trim().isNotEmpty
          ? providerName.trim()
          : provider.label;

  bool get isExpired {
    final until = validUntil;
    return until != null && DateTime.now().isAfter(until);
  }

  /// True within 30 days of expiry — worth warning about before a visit.
  bool get expiresSoon {
    final until = validUntil;
    if (until == null || isExpired) return false;
    return until.difference(DateTime.now()).inDays <= 30;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  /// e.g. "Valid to Dec 31, 2026" / "Expired Jan 2, 2024".
  String? get validityLabel {
    final until = validUntil;
    if (until == null) return null;
    return '${isExpired ? 'Expired' : 'Valid to'} ${formatDate(until)}';
  }

  InsuranceCard copyWith({
    InsuranceProvider? provider,
    String? providerName,
    CardType? type,
    String? memberName,
    String? memberNumber,
    String? policyNumber,
    String? scheme,
    DateTime? validFrom,
    DateTime? validUntil,
    String? notes,
    List<StoredAttachment>? documents,
  }) =>
      InsuranceCard(
        id: id,
        provider: provider ?? this.provider,
        providerName: providerName ?? this.providerName,
        type: type ?? this.type,
        memberName: memberName ?? this.memberName,
        memberNumber: memberNumber ?? this.memberNumber,
        policyNumber: policyNumber ?? this.policyNumber,
        scheme: scheme ?? this.scheme,
        validFrom: validFrom ?? this.validFrom,
        validUntil: validUntil ?? this.validUntil,
        notes: notes ?? this.notes,
        documents: documents ?? this.documents,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'provider': provider.id,
        'providerName': providerName,
        'type': type.id,
        'memberName': memberName,
        'memberNumber': memberNumber,
        'policyNumber': policyNumber,
        'scheme': scheme,
        'validFrom': validFrom == null ? null : Timestamp.fromDate(validFrom!),
        'validUntil':
            validUntil == null ? null : Timestamp.fromDate(validUntil!),
        'notes': notes,
        'documents': documents.map((d) => d.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory InsuranceCard.fromMap(String id, Map<String, dynamic> map) =>
      InsuranceCard(
        id: id,
        provider: InsuranceProvider.fromId(map['provider'] as String?),
        providerName: map['providerName'] as String? ?? '',
        type: CardType.fromId(map['type'] as String?),
        memberName: map['memberName'] as String? ?? '',
        memberNumber: map['memberNumber'] as String? ?? '',
        policyNumber: map['policyNumber'] as String? ?? '',
        scheme: map['scheme'] as String? ?? '',
        validFrom: _toDate(map['validFrom']),
        validUntil: _toDate(map['validUntil']),
        notes: map['notes'] as String? ?? '',
        documents: [
          for (final d in (map['documents'] as List? ?? const []))
            StoredAttachment.fromMap(Map<String, dynamic>.from(d as Map)),
        ],
        createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      );

  static DateTime? _toDate(Object? value) => switch (value) {
        Timestamp t => t.toDate(),
        String s => DateTime.tryParse(s),
        _ => null,
      };

  @override
  List<Object?> get props => [
        id,
        provider,
        providerName,
        type,
        memberName,
        memberNumber,
        policyNumber,
        scheme,
        validFrom,
        validUntil,
        notes,
        documents,
        createdAt,
      ];
}
