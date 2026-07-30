part of 'medications_cubit.dart';

enum MedicationsStatus { loading, ready, error }

class MedicationsState extends Equatable {
  const MedicationsState({
    this.status = MedicationsStatus.loading,
    this.medications = const [],
    this.remindersPermitted = true,
  });

  final MedicationsStatus status;
  final List<Medication> medications;

  /// False when the OS has refused notification permission, so the UI can say
  /// reminders are off instead of implying doses will be announced.
  final bool remindersPermitted;

  /// Courses that are running today, soonest dose first.
  List<Medication> currentAt(DateTime now) {
    final current =
        medications.where((m) => m.isCurrentAt(now)).toList();
    current.sort((a, b) {
      final aNext = a.dueDose(now);
      final bNext = b.dueDose(now);
      if (aNext == null && bNext == null) return a.name.compareTo(b.name);
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });
    return current;
  }

  /// The medication whose dose is due soonest — the dashboard's hero card.
  Medication? nextDue(DateTime now) {
    final current = currentAt(now).where((m) => m.dueDose(now) != null);
    return current.isEmpty ? null : current.first;
  }

  MedicationsState copyWith({
    MedicationsStatus? status,
    List<Medication>? medications,
    bool? remindersPermitted,
  }) =>
      MedicationsState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        remindersPermitted: remindersPermitted ?? this.remindersPermitted,
      );

  @override
  List<Object?> get props => [status, medications, remindersPermitted];
}
