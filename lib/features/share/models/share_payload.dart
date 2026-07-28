import 'dart:convert';

import '../../auth/models/patient_profile.dart';
import '../../records/models/medical_record.dart';

/// A shareable category the patient can toggle on the Share screen — the
/// "Customize Sharing Access" control. Each maps to specific fields assembled
/// into the [SharePayload].
enum ShareCategory {
  basicProfile('Basic Profile & Blood Type'),
  allergies('Allergies'),
  conditions('Chronic Conditions'),
  medications('Current Medications'),
  labs('Recent Lab Results'),
  fullHistory('Full Medical History');

  const ShareCategory(this.label);
  final String label;

  String get id => name;

  static ShareCategory? fromId(String id) {
    for (final c in ShareCategory.values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// A compact record summary carried in the payload (never imaging/PDFs — those
/// don't fit a QR).
class SharedRecord {
  const SharedRecord({
    required this.category,
    required this.title,
    required this.detail,
    required this.date,
  });

  final String category;
  final String title;
  final String detail;
  final String date;

  Map<String, dynamic> toJson() =>
      {'c': category, 't': title, 'd': detail, 'dt': date};

  factory SharedRecord.fromJson(Map<String, dynamic> j) => SharedRecord(
        category: j['c'] as String? ?? '',
        title: j['t'] as String? ?? '',
        detail: j['d'] as String? ?? '',
        date: j['dt'] as String? ?? '',
      );

  factory SharedRecord.fromRecord(MedicalRecord r) => SharedRecord(
        category: r.category.label,
        title: r.title,
        detail: r.detail,
        date: r.formattedDate,
      );
}

/// The self-contained, offline medical summary encoded into the QR. Compact
/// JSON keys keep it within a QR's ~2.9 KB budget.
class SharePayload {
  const SharePayload({
    this.version = 1,
    required this.name,
    required this.patientId,
    required this.expiresAt,
    required this.categories,
    this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.records = const [],
  });

  final int version;
  final String name;
  final String patientId;
  final DateTime expiresAt;
  final List<String> categories;

  final String? bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// Medications / labs / full history, per the selected categories.
  final List<SharedRecord> records;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Assembles the payload from the patient's profile + records, including only
  /// the fields the selected [categories] permit.
  factory SharePayload.build({
    required PatientProfile profile,
    required List<MedicalRecord> records,
    required Set<ShareCategory> categories,
    required DateTime expiresAt,
  }) {
    final full = categories.contains(ShareCategory.fullHistory);
    final has = categories.contains;

    final shared = <SharedRecord>[
      for (final r in records)
        if (full ||
            (has(ShareCategory.medications) &&
                r.category == RecordCategory.medication) ||
            (has(ShareCategory.labs) &&
                r.category == RecordCategory.labResult))
          SharedRecord.fromRecord(r),
    ];

    return SharePayload(
      name: profile.fullName,
      patientId: profile.patientId,
      expiresAt: expiresAt,
      categories: categories.map((c) => c.id).toList(),
      // Basic profile carries identity + blood type + emergency contact.
      bloodType: has(ShareCategory.basicProfile) || full
          ? profile.bloodType
          : null,
      allergies: has(ShareCategory.allergies) || full ? profile.allergies : const [],
      conditions:
          has(ShareCategory.conditions) || full ? profile.chronicConditions : const [],
      emergencyContactName: has(ShareCategory.basicProfile) || full
          ? profile.emergencyContactName
          : null,
      emergencyContactPhone: has(ShareCategory.basicProfile) || full
          ? profile.emergencyContactPhone
          : null,
      records: shared,
    );
  }

  Map<String, dynamic> toCompactJson() => {
        'v': version,
        'n': name,
        'pid': patientId,
        'exp': expiresAt.millisecondsSinceEpoch,
        'cats': categories,
        if (bloodType != null && bloodType!.isNotEmpty) 'bt': bloodType,
        if (allergies.isNotEmpty) 'al': allergies,
        if (conditions.isNotEmpty) 'co': conditions,
        if ((emergencyContactName ?? '').isNotEmpty) 'ecn': emergencyContactName,
        if ((emergencyContactPhone ?? '').isNotEmpty) 'ecp': emergencyContactPhone,
        if (records.isNotEmpty) 'rec': records.map((r) => r.toJson()).toList(),
      };

  String encode() => jsonEncode(toCompactJson());

  factory SharePayload.decode(String json) =>
      SharePayload.fromJson(jsonDecode(json) as Map<String, dynamic>);

  factory SharePayload.fromJson(Map<String, dynamic> j) => SharePayload(
        version: j['v'] as int? ?? 1,
        name: j['n'] as String? ?? 'Patient',
        patientId: j['pid'] as String? ?? '',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(j['exp'] as int? ?? 0),
        categories: List<String>.from(j['cats'] as List? ?? const []),
        bloodType: j['bt'] as String?,
        allergies: List<String>.from(j['al'] as List? ?? const []),
        conditions: List<String>.from(j['co'] as List? ?? const []),
        emergencyContactName: j['ecn'] as String?,
        emergencyContactPhone: j['ecp'] as String?,
        records: [
          for (final r in (j['rec'] as List? ?? const []))
            SharedRecord.fromJson(r as Map<String, dynamic>),
        ],
      );
}
