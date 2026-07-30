import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';

void main() {
  test('MedicalRecord round-trips its attachments through toMap/fromMap', () {
    final record = MedicalRecord(
      id: 'r1',
      category: RecordCategory.labResult,
      title: 'CMP',
      date: DateTime(2023, 10, 24),
      createdAt: DateTime(2023, 10, 24),
      attachments: const [
        RecordAttachment(url: 'https://cdn/x.jpg', name: 'x.jpg', kind: 'image'),
        RecordAttachment(url: 'https://cdn/y.pdf', name: 'y.pdf', kind: 'pdf'),
      ],
    );

    final restored = MedicalRecord.fromMap('r1', record.toMap());

    expect(restored.attachments.length, 2);
    expect(restored.attachments.first.url, 'https://cdn/x.jpg');
    expect(restored.attachments.first.isImage, isTrue);
    expect(restored.attachments.last.kind, 'pdf');
    expect(restored.attachments.last.isImage, isFalse);
  });

  test('a record with no attachments decodes to an empty list', () {
    final restored = MedicalRecord.fromMap('r1', {
      'category': 'diagnosis',
      'title': 'Acute Bronchitis',
    });
    expect(restored.attachments, isEmpty);
  });

  test('PatientProfile round-trips photoUrl', () {
    const profile = PatientProfile(
      uid: 'u1',
      fullName: 'Sarah Johnson',
      email: 'sarah@example.com',
      patientId: 'MC-8829-41',
      photoUrl: 'https://cdn/avatar.jpg',
    );
    final restored = PatientProfile.fromMap(profile.toMap());
    expect(restored.photoUrl, 'https://cdn/avatar.jpg');

    // copyWith preserves it when not overridden.
    expect(profile.copyWith(fullName: 'Sarah J').photoUrl,
        'https://cdn/avatar.jpg');
  });
}
