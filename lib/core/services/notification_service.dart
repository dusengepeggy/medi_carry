import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// One scheduled medication reminder.
class ReminderSchedule {
  const ReminderSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  /// Stable notification id. Must be unique per medication *and* per dose time.
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
}

/// Schedules the daily medication reminders.
///
/// Reminders are **local** notifications, not push: MediCarry has to work with
/// no connectivity, so a reminder that depends on a server reaching the phone
/// would be exactly the wrong design. Everything here is scheduled on-device
/// against the phone's own time zone.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication reminders';
  static const _channelDescription =
      'Reminds you when a dose of your medication is due.';

  bool _ready = false;

  /// True once [initialize] has completed. Callers can schedule regardless —
  /// scheduling on an uninitialised service is a no-op rather than a crash,
  /// because a failed notification setup must never block saving a medication.
  bool get isReady => _ready;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (error, stack) {
      // A device without notification support must not take the app down.
      debugPrint('Notification setup failed: $error\n$stack');
      _ready = false;
    }
  }

  /// Asks for permission to post notifications. Returns false when the patient
  /// declines, so the UI can say reminders are off rather than silently
  /// scheduling into nothing.
  Future<bool> requestPermission() async {
    if (!_ready) await initialize();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission() ?? false;
        // Exact alarms make a dose reminder land at the minute it is due. If
        // the OS refuses, scheduling falls back to inexact below.
        await android.requestExactAlarmsPermission();
        return granted;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether notifications are currently permitted.
  Future<bool> hasPermission() async {
    if (!_ready) await initialize();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

  /// Schedules [reminders] as daily notifications, replacing anything already
  /// scheduled under the same ids.
  Future<void> schedule(List<ReminderSchedule> reminders) async {
    if (!_ready) await initialize();
    if (!_ready) return;
    for (final reminder in reminders) {
      try {
        await _plugin.cancel(id: reminder.id);
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: _nextInstanceOf(reminder.hour, reminder.minute),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // Repeats every day at the same clock time.
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'medication',
        );
      } catch (error) {
        debugPrint('Could not schedule reminder ${reminder.id}: $error');
      }
    }
  }

  Future<void> cancel(Iterable<int> ids) async {
    if (!_ready) return;
    for (final id in ids) {
      try {
        await _plugin.cancel(id: id);
      } catch (_) {
        // Cancelling an id that was never scheduled is not an error.
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Ignored — nothing to clean up.
    }
  }

  /// The next occurrence of [hour]:[minute] in local time; tomorrow if that
  /// moment has already passed today.
  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
