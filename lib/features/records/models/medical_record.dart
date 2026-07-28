import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/theme/app_assets.dart';
import '../widgets/record_card.dart';

/// The kind of medical record. Drives the card treatment and icon, and is the
/// unit the Records screen filters by and the Share feature selects by.
enum RecordCategory {
  labResult,
  medication,
  diagnosis,
  imaging,
  vitals;

  /// Stored/parsed value (stable across renames of the enum).
  String get id => name;

  static RecordCategory fromId(String? id) => RecordCategory.values.firstWhere(
        (c) => c.name == id,
        orElse: () => RecordCategory.diagnosis,
      );

  /// Uppercase label shown on the card, e.g. "LAB RESULT".
  String get label => switch (this) {
        RecordCategory.labResult => 'LAB RESULT',
        RecordCategory.medication => 'MEDICATION',
        RecordCategory.diagnosis => 'DIAGNOSIS',
        RecordCategory.imaging => 'IMAGING',
        RecordCategory.vitals => 'VITALS',
      };

  /// Human label for pickers, e.g. "Lab result".
  String get title => switch (this) {
        RecordCategory.labResult => 'Lab result',
        RecordCategory.medication => 'Medication',
        RecordCategory.diagnosis => 'Diagnosis',
        RecordCategory.imaging => 'Imaging',
        RecordCategory.vitals => 'Vitals',
      };

  RecordCardStyle get style => switch (this) {
        RecordCategory.labResult => RecordCardStyle.lime,
        RecordCategory.medication => RecordCardStyle.navy,
        RecordCategory.diagnosis => RecordCardStyle.light,
        RecordCategory.imaging => RecordCardStyle.light,
        RecordCategory.vitals => RecordCardStyle.navy,
      };

  String get icon => switch (this) {
        RecordCategory.labResult => AppAssets.activityLab,
        RecordCategory.medication => AppAssets.activityPrescription,
        RecordCategory.diagnosis => AppAssets.activityCheckup,
        RecordCategory.imaging => AppAssets.activityCheckup,
        RecordCategory.vitals => AppAssets.activityPrescription,
      };
}

/// A patient's medical record, stored at Firestore `users/{uid}/records/{id}`.
class MedicalRecord extends Equatable {
  const MedicalRecord({
    required this.id,
    required this.category,
    required this.title,
    this.provider = '',
    this.detail = '',
    this.notes = '',
    required this.date,
    required this.createdAt,
  });

  final String id;
  final RecordCategory category;

  /// e.g. "Comprehensive Metabolic Panel", "Amoxicillin 500mg".
  final String title;

  /// Facility / clinician, e.g. "Nairobi Hospital Central Lab • Dr. J. Kamau".
  final String provider;

  /// One-line summary shown under the title (dosage, result, etc.).
  final String detail;

  /// Longer clinician notes, shown on the details screen.
  final String notes;

  /// The clinical date of the record.
  final DateTime date;

  /// When the record was added to MediCarry (for ordering).
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'category': category.id,
        'title': title,
        'provider': provider,
        'detail': detail,
        'notes': notes,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MedicalRecord.fromMap(String id, Map<String, dynamic> map) =>
      MedicalRecord(
        id: id,
        category: RecordCategory.fromId(map['category'] as String?),
        title: map['title'] as String? ?? '',
        provider: map['provider'] as String? ?? '',
        detail: map['detail'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        date: _toDate(map['date']),
        createdAt: _toDate(map['createdAt']),
      );

  static DateTime _toDate(Object? value) => switch (value) {
        Timestamp t => t.toDate(),
        String s => DateTime.tryParse(s) ?? DateTime.now(),
        _ => DateTime.now(),
      };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "Oct 24, 2023".
  String get formattedDate =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  /// Adapts this record to the display model the [RecordCard] renders.
  RecordEntry toEntry() => RecordEntry(
        category: category.label,
        title: title,
        subtitle: provider.isEmpty ? detail : provider,
        meta: formattedDate,
        icon: category.icon,
        style: category.style,
      );

  @override
  List<Object?> get props =>
      [id, category, title, provider, detail, notes, date, createdAt];
}
