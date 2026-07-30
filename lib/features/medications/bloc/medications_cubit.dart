import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/notification_service.dart';
import '../data/medications_repository.dart';
import '../models/medication.dart';

part 'medications_state.dart';

/// Streams the patient's medications and keeps the device's dose reminders in
/// step with them.
///
/// Reminder scheduling lives here rather than in a screen so it happens
/// wherever the list is loaded — the dashboard included — and so a medication
/// added on one screen is reminded about without the patient visiting another.
class MedicationsCubit extends Cubit<MedicationsState> {
  MedicationsCubit({
    required MedicationsRepository repository,
    required NotificationService notifications,
    required String uid,
  })  : _repository = repository,
        _notifications = notifications,
        _uid = uid,
        super(const MedicationsState()) {
    if (uid.isEmpty) {
      emit(state.copyWith(status: MedicationsStatus.ready));
      return;
    }
    _subscription = _repository.watchMedications(uid).listen(
      (medications) {
        emit(state.copyWith(
          status: MedicationsStatus.ready,
          medications: medications,
        ));
        unawaited(_syncReminders(medications));
      },
      onError: (_) => emit(state.copyWith(status: MedicationsStatus.error)),
    );
  }

  final MedicationsRepository _repository;
  final NotificationService _notifications;
  final String _uid;

  StreamSubscription<List<Medication>>? _subscription;

  Future<void> add(Medication medication) async {
    await _repository.add(_uid, medication);
    // The stream re-emits and reschedules; nothing to do here.
  }

  Future<void> update(Medication medication) =>
      _repository.update(_uid, medication);

  Future<void> markTaken(Medication medication) =>
      _repository.markTaken(_uid, medication.id, DateTime.now());

  Future<void> setRemindersEnabled(Medication medication, bool enabled) =>
      _repository.setRemindersEnabled(_uid, medication.id, enabled);

  Future<void> delete(Medication medication) async {
    await _notifications.cancel(medication.notificationIds);
    await _repository.delete(_uid, medication.id);
  }

  /// Asks the OS for notification permission, then re-schedules so a patient
  /// who grants it late still gets today's remaining doses.
  Future<bool> requestReminderPermission() async {
    final granted = await _notifications.requestPermission();
    emit(state.copyWith(remindersPermitted: granted));
    if (granted) await _syncReminders(state.medications);
    return granted;
  }

  /// Rebuilds the whole reminder schedule from [medications].
  ///
  /// Cancelling everything first is deliberate: it is the only way to be sure
  /// a deleted medication, a removed dose time, or a finished course stops
  /// firing, and these are the only notifications the app posts.
  Future<void> _syncReminders(List<Medication> medications) async {
    final now = DateTime.now();
    final reminders = <ReminderSchedule>[];
    for (final medication in medications) {
      if (!medication.remindersEnabled || !medication.isCurrentAt(now)) continue;
      for (var i = 0; i < medication.times.length; i++) {
        final time = medication.times[i];
        reminders.add(
          ReminderSchedule(
            id: medication.notificationId(i),
            title: 'Time for ${medication.name}',
            body: [
              if (medication.dosage.isNotEmpty) medication.dosage,
              if (medication.instructions.isNotEmpty) medication.instructions,
            ].join(' • '),
            hour: time.hour,
            minute: time.minute,
          ),
        );
      }
    }
    await _notifications.cancelAll();
    await _notifications.schedule(reminders);

    final permitted = await _notifications.hasPermission();
    if (!isClosed && permitted != state.remindersPermitted) {
      emit(state.copyWith(remindersPermitted: permitted));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
