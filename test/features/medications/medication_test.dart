import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/features/medications/models/medication.dart';

Medication _medication({
  List<DoseTime> times = const [DoseTime(8, 0), DoseTime(20, 0)],
  DateTime? start,
  DateTime? end,
  DateTime? lastTakenAt,
  bool active = true,
}) =>
    Medication(
      id: 'm1',
      name: 'Lisinopril',
      dosage: '10mg',
      instructions: 'Take with food',
      times: times,
      startDate: start ?? DateTime(2026, 1, 1),
      endDate: end,
      lastTakenAt: lastTakenAt,
      active: active,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('DoseTime', () {
    test('parses and re-serialises HH:mm', () {
      final time = DoseTime.tryParse('08:05');
      expect(time, const DoseTime(8, 5));
      expect(time!.stored, '08:05');
    });

    test('rejects malformed and out-of-range values', () {
      expect(DoseTime.tryParse('8'), isNull);
      expect(DoseTime.tryParse('24:00'), isNull);
      expect(DoseTime.tryParse('10:75'), isNull);
      expect(DoseTime.tryParse('abc:def'), isNull);
    });

    test('labels in 12-hour time', () {
      expect(const DoseTime(0, 0).label, '12:00 AM');
      expect(const DoseTime(8, 5).label, '8:05 AM');
      expect(const DoseTime(12, 30).label, '12:30 PM');
      expect(const DoseTime(20, 0).label, '8:00 PM');
    });
  });

  group('nextDoseAfter', () {
    test('returns the next time later today', () {
      final medication = _medication();
      final next = medication.nextDoseAfter(DateTime(2026, 6, 1, 9));
      expect(next, DateTime(2026, 6, 1, 20));
    });

    test('rolls over to tomorrow after the last dose', () {
      final medication = _medication();
      final next = medication.nextDoseAfter(DateTime(2026, 6, 1, 21));
      expect(next, DateTime(2026, 6, 2, 8));
    });

    test('returns null once the course has ended', () {
      final medication = _medication(end: DateTime(2026, 5, 30));
      expect(medication.nextDoseAfter(DateTime(2026, 6, 1, 9)), isNull);
    });

    test('returns null for an inactive medication', () {
      final medication = _medication(active: false);
      expect(medication.nextDoseAfter(DateTime(2026, 6, 1, 9)), isNull);
    });
  });

  group('dueDose', () {
    test('surfaces a dose that is due but not yet taken', () {
      final medication = _medication();
      // 08:30 — the 8am dose is 30 minutes overdue.
      expect(
        medication.dueDose(DateTime(2026, 6, 1, 8, 30)),
        DateTime(2026, 6, 1, 8),
      );
    });

    test('skips a dose already marked as taken', () {
      final medication =
          _medication(lastTakenAt: DateTime(2026, 6, 1, 8, 10));
      expect(
        medication.dueDose(DateTime(2026, 6, 1, 8, 30)),
        DateTime(2026, 6, 1, 20),
      );
    });

    test('stops treating a dose as due once the grace window passes', () {
      final medication = _medication();
      // 11:00 is more than two hours past the 8am dose.
      expect(
        medication.dueDose(DateTime(2026, 6, 1, 11)),
        DateTime(2026, 6, 1, 20),
      );
    });
  });

  group('notification ids', () {
    test('are stable, distinct per dose time, and fit an Android int', () {
      final medication = _medication();
      final ids = medication.notificationIds;
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      expect(medication.notificationId(0), ids.first);
      for (final id in ids) {
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(0x40000000));
      }
    });
  });

  test('round-trips through toMap/fromMap', () {
    final medication = _medication(lastTakenAt: DateTime(2026, 6, 1, 8, 10));
    final restored = Medication.fromMap('m1', medication.toMap());

    expect(restored.name, 'Lisinopril');
    expect(restored.dosage, '10mg');
    expect(restored.times, medication.times);
    expect(restored.lastTakenAt, medication.lastTakenAt);
    expect(restored.remindersEnabled, isTrue);
  });

  test('drops malformed stored dose times rather than failing the document',
      () {
    final restored = Medication.fromMap('m1', {
      'name': 'Metformin',
      'times': ['08:00', 'not-a-time', '25:00'],
    });
    expect(restored.times, [const DoseTime(8, 0)]);
  });
}
