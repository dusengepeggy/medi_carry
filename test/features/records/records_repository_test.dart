import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/features/records/data/records_repository.dart';
import 'package:medi_carry/features/records/models/medical_record.dart';

MedicalRecord _record(String title, RecordCategory category, DateTime when) =>
    MedicalRecord(
      id: '',
      category: category,
      title: title,
      date: when,
      createdAt: when,
    );

void main() {
  late FakeFirebaseFirestore firestore;
  late RecordsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = RecordsRepository(firestore: firestore);
  });

  test('add then watch returns the record, newest first', () async {
    await repo.add('u1', _record('Older', RecordCategory.labResult,
        DateTime(2023, 1, 1)));
    await repo.add('u1', _record('Newer', RecordCategory.medication,
        DateTime(2023, 6, 1)));

    final records = await repo.watchRecords('u1').first;
    expect(records.map((r) => r.title), ['Newer', 'Older']);
  });

  test("records are scoped to the owner's uid", () async {
    await repo.add('u1', _record('Mine', RecordCategory.diagnosis,
        DateTime(2023, 1, 1)));

    expect((await repo.watchRecords('u1').first).length, 1);
    expect((await repo.watchRecords('other').first), isEmpty);
  });

  test('delete removes the record', () async {
    final id = await repo.add(
        'u1', _record('Temp', RecordCategory.vitals, DateTime(2023, 1, 1)));
    expect((await repo.watchRecords('u1').first).length, 1);

    await repo.delete('u1', id);
    expect(await repo.watchRecords('u1').first, isEmpty);
  });

  test('fields survive the Firestore round-trip', () async {
    await repo.add(
      'u1',
      MedicalRecord(
        id: '',
        category: RecordCategory.labResult,
        title: 'CMP',
        provider: 'City Lab',
        detail: 'Glucose 108',
        notes: 'Follow up in 3 months',
        date: DateTime(2023, 10, 24),
        createdAt: DateTime(2023, 10, 24),
      ),
    );
    final r = (await repo.watchRecords('u1').first).single;
    expect(r.title, 'CMP');
    expect(r.provider, 'City Lab');
    expect(r.detail, 'Glucose 108');
    expect(r.notes, 'Follow up in 3 months');
    expect(r.category, RecordCategory.labResult);
    expect(r.formattedDate, 'Oct 24, 2023');
  });
}
