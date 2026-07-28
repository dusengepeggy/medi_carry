import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/share_crypto.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';
import 'package:medi_carry/features/share/data/shares_repository.dart';
import 'package:medi_carry/features/share/models/share_grant.dart';
import 'package:medi_carry/features/share/models/share_payload.dart';

const _profile = PatientProfile(
  uid: 'u1',
  fullName: 'Sarah Johnson',
  email: 'sarah@example.com',
  patientId: 'MC-8829-41',
  bloodType: 'O+',
  allergies: ['Penicillin'],
  chronicConditions: ['Asthma'],
  emergencyContactName: 'James Johnson',
  emergencyContactPhone: '+254 700 000 000',
);

final _records = [
  MedicalRecord(
    id: 'r1',
    category: RecordCategory.medication,
    title: 'Amoxicillin 500mg',
    detail: '1 capsule every 8 hours',
    date: DateTime(2023, 10, 10),
    createdAt: DateTime(2023, 10, 10),
  ),
  MedicalRecord(
    id: 'r2',
    category: RecordCategory.labResult,
    title: 'CMP',
    date: DateTime(2023, 10, 24),
    createdAt: DateTime(2023, 10, 24),
  ),
];

void main() {
  group('SharePayload.build honors the selected categories', () {
    test('basic profile only shares identity + blood type + contact, no records',
        () {
      final payload = SharePayload.build(
        profile: _profile,
        records: _records,
        categories: {ShareCategory.basicProfile},
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(payload.bloodType, 'O+');
      expect(payload.emergencyContactPhone, '+254 700 000 000');
      expect(payload.allergies, isEmpty); // not selected
      expect(payload.records, isEmpty);
    });

    test('medications category includes only medication records', () {
      final payload = SharePayload.build(
        profile: _profile,
        records: _records,
        categories: {ShareCategory.medications},
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(payload.records.map((r) => r.title), ['Amoxicillin 500mg']);
    });

    test('full history includes everything', () {
      final payload = SharePayload.build(
        profile: _profile,
        records: _records,
        categories: {ShareCategory.fullHistory},
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(payload.allergies, ['Penicillin']);
      expect(payload.conditions, ['Asthma']);
      expect(payload.records.length, 2);
    });
  });

  test('payload survives encrypt → QR string → decrypt → decode', () {
    final payload = SharePayload.build(
      profile: _profile,
      records: _records,
      categories: {ShareCategory.basicProfile, ShareCategory.allergies},
      expiresAt: DateTime(2030, 1, 1),
    );
    final code = ShareCrypto.encryptToCode(payload.encode(), '4271');
    final restored = SharePayload.decode(
      ShareCrypto.decryptFromCode(code, '4271'),
    );

    expect(restored.name, 'Sarah Johnson');
    expect(restored.patientId, 'MC-8829-41');
    expect(restored.bloodType, 'O+');
    expect(restored.allergies, ['Penicillin']);
    expect(restored.isExpired, isFalse);
  });

  group('SharesRepository', () {
    late FakeFirebaseFirestore firestore;
    late SharesRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = SharesRepository(firestore: firestore);
    });

    test('a granted share is active, then drops out when revoked', () async {
      final id = await repo.add(
        'u1',
        ShareGrant(
          id: '',
          recipientLabel: 'In-person QR',
          categories: const ['basicProfile'],
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      var active = (await repo.watchShares('u1').first).where((g) => g.isActive);
      expect(active.length, 1);

      await repo.revoke('u1', id);
      active = (await repo.watchShares('u1').first).where((g) => g.isActive);
      expect(active, isEmpty);
    });

    test('an expired grant is not active', () async {
      await repo.add(
        'u1',
        ShareGrant(
          id: '',
          recipientLabel: 'Old',
          categories: const ['basicProfile'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      final active =
          (await repo.watchShares('u1').first).where((g) => g.isActive);
      expect(active, isEmpty);
    });
  });
}
