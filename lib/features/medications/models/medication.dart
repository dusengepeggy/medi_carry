import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A time of day a dose is due, stored as `HH:mm` so it survives locale and
/// time-zone changes.
class DoseTime extends Equatable implements Comparable<DoseTime> {
  const DoseTime(this.hour, this.minute);

  final int hour;
  final int minute;

  static DoseTime? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return DoseTime(hour, minute);
  }

  String get stored =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// e.g. "8:00 AM".
  String get label {
    final period = hour < 12 ? 'AM' : 'PM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  /// This dose time on the calendar day of [day].
  DateTime onDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  @override
  int compareTo(DoseTime other) =>
      (hour * 60 + minute).compareTo(other.hour * 60 + other.minute);

  @override
  List<Object?> get props => [hour, minute];
}

/// A medication the patient is taking, stored at
/// Firestore `users/{uid}/medications/{id}`.
///
/// Doses are a list of daily times rather than a free-text frequency, because
/// a reminder can only be scheduled against an actual clock time.
class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.name,
    this.dosage = '',
    this.instructions = '',
    this.times = const [],
    required this.startDate,
    this.endDate,
    this.remindersEnabled = true,
    this.active = true,
    this.lastTakenAt,
    required this.createdAt,
  });

  final String id;

  /// e.g. "Lisinopril".
  final String name;

  /// e.g. "10mg".
  final String dosage;

  /// e.g. "Take with food".
  final String instructions;

  /// Daily dose times, kept sorted.
  final List<DoseTime> times;

  final DateTime startDate;

  /// When the course ends. Null means ongoing (e.g. a chronic condition).
  final DateTime? endDate;

  final bool remindersEnabled;

  /// False when the patient has stopped the medication but wants the history.
  final bool active;

  /// When the most recent dose was marked as taken.
  final DateTime? lastTakenAt;

  final DateTime createdAt;

  /// Whether the course covers [when] — used to hide finished courses from the
  /// dashboard without deleting them.
  bool isCurrentAt(DateTime when) {
    if (!active) return false;
    final day = DateTime(when.year, when.month, when.day);
    if (day.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    final end = endDate;
    if (end != null && day.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    return true;
  }

  /// The next dose due strictly after [from], or null when the course has no
  /// times or has already finished.
  ///
  /// A dose is skipped when it was already marked as taken — otherwise the
  /// dashboard would keep pointing at the 8am dose all morning after the
  /// patient took it.
  DateTime? nextDoseAfter(DateTime from) {
    if (times.isEmpty || !active) return null;
    final sorted = [...times]..sort();
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final day = from.add(Duration(days: dayOffset));
      if (!isCurrentAt(day)) continue;
      for (final time in sorted) {
        final at = time.onDay(day);
        if (!at.isAfter(from)) continue;
        return at;
      }
    }
    return null;
  }

  /// The dose the patient should act on right now: the most recent one that is
  /// due (within [grace]) and not yet taken, otherwise the next upcoming one.
  DateTime? dueDose(
    DateTime now, {
    Duration grace = const Duration(hours: 2),
  }) {
    if (times.isEmpty || !active) return null;
    final sorted = [...times]..sort();
    final taken = lastTakenAt;
    for (final time in sorted.reversed) {
      final at = time.onDay(now);
      if (at.isAfter(now)) continue;
      if (now.difference(at) > grace) break;
      if (taken != null && !taken.isBefore(at)) continue;
      if (!isCurrentAt(at)) continue;
      return at;
    }
    return nextDoseAfter(now);
  }

  /// A stable notification id for the dose at [timeIndex].
  ///
  /// Derived from the document id so the id survives app restarts, and kept
  /// inside 31 bits because Android notification ids are `int`.
  int notificationId(int timeIndex) =>
      ((id.hashCode.abs() % 1000000) * 100 + timeIndex) & 0x3FFFFFFF;

  /// Every notification id this medication owns, for cancellation.
  List<int> get notificationIds =>
      [for (var i = 0; i < times.length; i++) notificationId(i)];

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? instructions,
    List<DoseTime>? times,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? remindersEnabled,
    bool? active,
    DateTime? lastTakenAt,
  }) =>
      Medication(
        id: id ?? this.id,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        instructions: instructions ?? this.instructions,
        times: times ?? this.times,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        active: active ?? this.active,
        lastTakenAt: lastTakenAt ?? this.lastTakenAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'instructions': instructions,
        'times': times.map((t) => t.stored).toList(),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'remindersEnabled': remindersEnabled,
        'active': active,
        'lastTakenAt':
            lastTakenAt == null ? null : Timestamp.fromDate(lastTakenAt!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Medication.fromMap(String id, Map<String, dynamic> map) => Medication(
        id: id,
        name: map['name'] as String? ?? '',
        dosage: map['dosage'] as String? ?? '',
        instructions: map['instructions'] as String? ?? '',
        times: _parseTimes(map['times']),
        startDate: _toDate(map['startDate']) ?? DateTime.now(),
        endDate: _toDate(map['endDate']),
        remindersEnabled: map['remindersEnabled'] as bool? ?? true,
        active: map['active'] as bool? ?? true,
        lastTakenAt: _toDate(map['lastTakenAt']),
        createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      );

  /// Parses stored `HH:mm` strings, dropping anything malformed rather than
  /// failing the whole document.
  static List<DoseTime> _parseTimes(Object? value) {
    final parsed = <DoseTime>[];
    for (final entry in (value as List? ?? const [])) {
      final time = DoseTime.tryParse('$entry');
      if (time != null) parsed.add(time);
    }
    return parsed..sort();
  }

  static DateTime? _toDate(Object? value) => switch (value) {
        Timestamp t => t.toDate(),
        String s => DateTime.tryParse(s),
        _ => null,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        dosage,
        instructions,
        times,
        startDate,
        endDate,
        remindersEnabled,
        active,
        lastTakenAt,
        createdAt,
      ];
}
