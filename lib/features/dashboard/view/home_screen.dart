import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_shell.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../widgets/activity_card.dart';
import '../widgets/add_record_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/medication_card.dart';
import '../widgets/medi_bottom_nav.dart' show MediTab;
import '../widgets/vitals_card.dart';

/// The MediCarry dashboard — an implementation of the "Dashboard (Final)"
/// Figma frame (node 2:2).
///
/// The medication, vitals and activity content is placeholder data matching the
/// design; it will be replaced by the records feature once that lands. The
/// greeting is already wired to the signed-in patient.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Placeholder activity, mirroring the design's sample rows.
  static const _activity = [
    ActivityEntry(
      title: 'Comprehensive Metabolic Panel',
      subtitle: 'Oct 12 • City Lab',
      icon: AppAssets.activityLab,
      iconSize: Size(18.057, 18),
    ),
    ActivityEntry(
      title: 'Prescription Renewal',
      subtitle: 'Oct 10 • Dr. Smith',
      icon: AppAssets.activityPrescription,
      iconSize: Size(20, 22),
    ),
    ActivityEntry(
      title: 'General Checkup',
      subtitle: 'Sep 28 • Main Clinic',
      icon: AppAssets.activityCheckup,
      iconSize: Size(20, 20),
      highlighted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc b) => b.state.user.displayName);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: DashboardAppBar(
              onAvatarTap: () => _openProfile(context),
              onSearch: () {},
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _Welcome(displayName: displayName),
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  MedicationCard(
                    name: 'Lisinopril',
                    dosage: '10mg - Take with food',
                    dueLabel: 'In 2 hours',
                    onMarkTaken: () {},
                  ),
                  const SizedBox(height: 16),
                  const VitalsCard(
                    reading: '118/76',
                    unit: 'mmHg',
                    trendLabel: 'Slightly lower than yesterday',
                  ),
                  const SizedBox(height: 16),
                  ActivityCard(
                    entries: _activity,
                    onSeeAll: () => _openRecords(context),
                    onEntryTap: (_) => AppNav.openRecordDetails(context),
                  ),
                  const SizedBox(height: 16),
                  AddRecordCard(onTap: () => AppNav.openAddRecord(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRecords(BuildContext context) =>
      AppShell.of(context)?.goToTab(MediTab.history);

  void _openProfile(BuildContext context) =>
      AppShell.of(context)?.goToTab(MediTab.profile);
}

class _Welcome extends StatelessWidget {
  const _Welcome({this.displayName});

  final String? displayName;

  /// "Good Morning" / "Good Afternoon" / "Good Evening" by local time.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _firstName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return '';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final name = _firstName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? _greeting : '$_greeting, $name',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            height: 42 / 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your health overview for today.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.navy.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        const _EmergencyButton(),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => AppNav.openEmergencyInfo(context),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.indigoFinal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.emergency, width: 17.3, height: 18),
            const SizedBox(width: 8),
            Text(
              'Emergency Info',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
