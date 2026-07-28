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
/// The Activity list is the patient's real recent records (via [RecordsCubit]).
/// The medication and vitals hero cards remain illustrative summaries until
/// those specific features land.
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

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc b) => b.state.user.displayName);

    return Scaffold(
      backgroundColor: context.colors.canvas,
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
                  _RecentActivity(),
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

  void _openProfile(BuildContext context) =>
      AppShell.of(context)?.goToTab(MediTab.profile);
}

/// The Activity card, driven by the three most recent real records.
class _RecentActivity extends StatelessWidget {
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
