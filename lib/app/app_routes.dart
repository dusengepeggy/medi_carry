import 'package:flutter/material.dart';

import '../features/auth/models/patient_profile.dart';
import '../features/emergency/view/emergency_info_screen.dart';
import '../features/profile/view/edit_profile_screen.dart';
import '../features/records/models/medical_record.dart';
import '../features/records/view/add_record_screen.dart';
import '../features/records/view/record_details_screen.dart';
import '../features/share/view/share_records_screen.dart';

/// Navigation helpers, so call sites stop hand-rolling `MaterialPageRoute`
/// and the push target (tab navigator vs root) is decided in one place.
///
/// **Tab pushes** keep the shell's bottom bar visible and the current tab lit —
/// used by screens whose designs include the bar (Record Details, Share).
/// **Root pushes** cover the whole shell — used for focused tasks (Edit
/// Profile) and high-stakes surfaces (Emergency Info, Add Record).
abstract final class AppNav {
  AppNav._();

  // ---- Pushed inside the current tab (bottom bar stays visible) ----------
  static Future<void> openRecordDetails(
    BuildContext context,
    MedicalRecord record,
  ) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RecordDetailsScreen(record: record),
        ),
      );

  static Future<void> openShare(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ShareRecordsScreen()),
      );

  // ---- Pushed on the root navigator (covers the shell) -------------------

  /// Emergency info must also open from the lock screen, where no shell
  /// exists, so it always uses the root navigator.
  static Future<void> openEmergencyInfo(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const EmergencyInfoScreen()),
      );

  static Future<PatientProfile?> openEditProfile(
    BuildContext context,
    PatientProfile profile,
  ) =>
      Navigator.of(context, rootNavigator: true).push<PatientProfile>(
        MaterialPageRoute<PatientProfile>(
          builder: (_) => EditProfileScreen(profile: profile),
        ),
      );

  static Future<void> openAddRecord(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const AddRecordScreen(),
          fullscreenDialog: true,
        ),
      );
}
