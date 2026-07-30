import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_shell.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../medications/bloc/medications_cubit.dart';
import '../../medications/models/medication.dart';
import '../../profile/bloc/profile_cubit.dart';
import '../../records/bloc/records_cubit.dart';
import '../../records/data/records_repository.dart';
import '../../records/models/medical_record.dart';
import '../widgets/activity_card.dart';
import '../widgets/add_record_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/medication_card.dart';
import '../widgets/medi_bottom_nav.dart' show MediTab;
import '../widgets/vitals_card.dart';

/// The MediCarry dashboard — an implementation of the "Dashboard (Final)"
/// Figma frame (node 2:2).
///
/// Everything on it is the patient's own live data: the next dose from their
/// medication schedule, their most recent vitals record, and their most recent
/// records. Nothing here is illustrative.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthBloc b) => b.state.user.uid);
    return BlocProvider(
      // Keyed on uid so the cubit is recreated once auth resolves the user.
      key: ValueKey(uid),
      create: (_) => RecordsCubit(
        repository: context.read<RecordsRepository>(),
        uid: uid,
      ),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  /// Drives the relative dose countdown ("in 2 hours"). Without it the label
  /// would be frozen at whatever it said when the screen was built.
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _now = DateTime.now());
    // Firestore streams push their own updates; this just re-reads the clock
    // so pulling down gives the patient the feedback they expect.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    // Prefers the profile document's name over the Firebase display name, so
    // renaming yourself on Edit Profile changes the greeting too.
    final profileName = context.select((ProfileCubit c) => c.state.firstName);
    final displayName =
        context.select((AuthBloc b) => b.state.user.displayName);

    return Scaffold(
      backgroundColor: context.colors.canvas,
      extendBody: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: DashboardAppBar(
              onAvatarTap: () => _openProfile(context),
              onSearch: () => AppShell.of(context)?.goToTab(MediTab.history),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 128),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _Welcome(
                      name: profileName ?? _firstNameOf(displayName),
                      now: _now,
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 8),
                    _NextMedication(now: _now),
                    const SizedBox(height: 16),
                    const _LatestVitals(),
                    const SizedBox(height: 16),
                    const _RecentActivity(),
                    const SizedBox(height: 16),
                    AddRecordCard(onTap: () => AppNav.openAddRecord(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _firstNameOf(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(' ').first;
  }

  void _openProfile(BuildContext context) =>
      AppShell.of(context)?.goToTab(MediTab.profile);
}

/// The hero card: the dose the patient should take next, straight from their
/// medication schedule.
class _NextMedication extends StatelessWidget {
  const _NextMedication({required this.now});

  final DateTime now;

  Future<void> _markTaken(BuildContext context, Medication medication) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<MedicationsCubit>().markTaken(medication);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${medication.name} marked as taken')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          return const _PlaceholderCard(height: 220);
        }
        final medication = state.nextDue(now);
        if (medication == null) {
          return _EmptyHeroCard(
            icon: Icons.medication_outlined,
            title: 'No medications yet',
            body: 'Add your prescriptions and MediCarry will remind you at '
                'each dose time, even offline.',
            actionLabel: 'Add medication',
            onAction: () => AppNav.openMedications(context),
          );
        }
        final due = medication.dueDose(now);
        return MedicationCard(
          name: medication.name,
          dosage: [
            if (medication.dosage.isNotEmpty) medication.dosage,
            if (medication.instructions.isNotEmpty) medication.instructions,
          ].join(' - '),
          dueLabel: due == null ? 'Scheduled' : _dueLabel(due, now),
          onMarkTaken: () => _markTaken(context, medication),
        );
      },
    );
  }

  /// "Due now" / "In 45 min" / "In 2 hours" / "Tomorrow, 8:00 AM".
  static String _dueLabel(DateTime due, DateTime now) {
    final delta = due.difference(now);
    if (delta.isNegative || delta.inMinutes < 1) return 'Due now';
    if (delta.inMinutes < 60) return 'In ${delta.inMinutes} min';
    if (due.day == now.day) {
      final h = delta.inHours;
      return 'In $h ${h == 1 ? 'hour' : 'hours'}';
    }
    return 'Tomorrow, ${DoseTime(due.hour, due.minute).label}';
  }
}

/// The patient's most recent vitals record.
class _LatestVitals extends StatelessWidget {
  const _LatestVitals();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordsCubit, RecordsState>(
      builder: (context, state) {
        if (state.status == RecordsStatus.loading) {
          return const _PlaceholderCard(height: 200);
        }
        final vitals = state.records
            .where((r) => r.category == RecordCategory.vitals)
            .toList();
        if (vitals.isEmpty) {
          return _EmptyHeroCard(
            icon: Icons.favorite_border,
            title: 'No vitals recorded',
            body: 'Add a vitals record — blood pressure, weight, sugar — and '
                'the latest reading shows here.',
            actionLabel: 'Add vitals',
            onAction: () => AppNav.openAddRecord(context),
            dark: true,
          );
        }
        final latest = vitals.first;
        return GestureDetector(
          onTap: () => AppNav.openRecordDetails(context, latest),
          child: VitalsCard(
            label: latest.title.isEmpty ? 'LATEST VITALS' : latest.title.toUpperCase(),
            reading: latest.detail.isEmpty ? '—' : latest.detail,
            unit: '',
            trendLabel: 'Recorded ${latest.formattedDate}',
          ),
        );
      },
    );
  }
}

/// The Activity card, driven by the three most recent real records.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordsCubit, RecordsState>(
      builder: (context, state) {
        final recent = state.records.take(3).toList();
        final entries = [
          for (final r in recent)
            ActivityEntry(
              title: r.title,
              subtitle: '${r.formattedDate} • ${r.category.title}',
              icon: r.category.icon,
              highlighted: r.category == RecordCategory.labResult,
            ),
        ];
        return ActivityCard(
          entries: entries,
          emptyText: state.status == RecordsStatus.loading
              ? 'Loading…'
              : 'No records yet.',
          onSeeAll: () => AppShell.of(context)?.goToTab(MediTab.history),
          onEntryTap: (entry) {
            final i = entries.indexOf(entry);
            if (i >= 0) AppNav.openRecordDetails(context, recent[i]);
          },
        );
      },
    );
  }
}

/// Stand-in for a hero card while its stream is still resolving. Sized to the
/// real card so the dashboard doesn't jump when data arrives.
class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
}

/// What a hero card shows before the patient has any data for it: says plainly
/// what is missing, and offers the action that fixes it.
class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  /// Matches the navy vitals card instead of the lime medication card.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.limeOnSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: dark ? AppColors.navy : AppColors.limeFinal,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 24),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              height: 22 / 15,
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: dark ? Colors.white : AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  color: dark ? AppColors.navy : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({this.name, required this.now});

  final String? name;
  final DateTime now;

  /// "Good Morning" / "Good Afternoon" / "Good Evening" by local time.
  String get _greeting {
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final first = name?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.isEmpty ? _greeting : '$_greeting, $first',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            height: 42 / 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your health overview for today.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: context.colors.textSecondary,
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
