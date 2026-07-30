import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/data/user_repository.dart';
import '../../dashboard/widgets/medi_bottom_nav.dart' show MediTab;
import '../../records/data/records_repository.dart';
import '../bloc/share_cubit.dart';
import '../data/records_pdf.dart';
import '../data/shares_repository.dart';
import '../models/share_grant.dart';
import '../widgets/access_selection_card.dart';
import '../widgets/access_settings_card.dart';
import '../widgets/active_shares_list.dart';
import '../widgets/export_options_card.dart';
import '../widgets/quick_share_card.dart';
import '../widgets/share_app_bar.dart';
import '../widgets/share_qr_sheet.dart';
import 'scan_screen.dart';
import 'share_history_screen.dart';

/// Share Records (node 2:137) — MediCarry's core differentiator. The patient
/// picks exactly which categories to share, sets a duration, and generates a
/// self-contained, PIN-encrypted QR that works entirely offline.
class ShareRecordsScreen extends StatelessWidget {
  const ShareRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthBloc b) => b.state.user.uid);
    return BlocProvider(
      // Keyed on uid so the cubit is recreated once auth resolves the user.
      key: ValueKey(uid),
      create: (_) => ShareCubit(
        sharesRepository: context.read<SharesRepository>(),
        uid: uid,
      ),
      child: const _ShareView(),
    );
  }
}

class _ShareView extends StatefulWidget {
  const _ShareView();

  @override
  State<_ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<_ShareView> {
  bool _exporting = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String? _firstName(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(' ').first;
  }

  /// Fetches the latest profile + records, then asks the cubit to build the
  /// encrypted QR.
  Future<void> _generate(BuildContext context) async {
    final uid = context.read<AuthBloc>().state.user.uid;
    if (uid.isEmpty) return;
    final profile = await context.read<UserRepository>().fetchProfile(uid);
    if (profile == null || !context.mounted) return;
    final records =
        await context.read<RecordsRepository>().watchRecords(uid).first;
    if (!context.mounted) return;
    await context
        .read<ShareCubit>()
        .generate(profile: profile, records: records);
  }

  /// Builds the health-summary PDF and hands it to the OS share/print sheet,
  /// which is what lets the patient save it, email it, or print it at a clinic.
  Future<void> _exportPdf() async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    final uid = context.read<AuthBloc>().state.user.uid;
    if (uid.isEmpty) return;

    setState(() => _exporting = true);
    try {
      final profile = await context.read<UserRepository>().fetchProfile(uid);
      if (profile == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Complete your profile first.')),
        );
        return;
      }
      if (!mounted) return;
      final records =
          await context.read<RecordsRepository>().watchRecords(uid).first;
      final bytes = await RecordsPdf.build(profile: profile, records: records);
      await Printing.sharePdf(
        bytes: bytes,
        filename: RecordsPdf.fileName(profile),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not create the PDF.')),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// The gear on Access Settings: what the controls mean, plus the blunt
  /// instrument — revoke everything at once.
  Future<void> _openAccessSettings() async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.read<SharesRepository>();
    final uid = context.read<AuthBloc>().state.user.uid;

    final revokeAll = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => const _AccessSettingsSheet(),
    );

    if (revokeAll != true || uid.isEmpty) return;
    final count = await repository.revokeAllActive(uid);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'There were no active shares to revoke.'
                : 'Revoked $count ${count == 1 ? 'share' : 'shares'}.',
          ),
        ),
      );
  }

  void _openHistory(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ShareHistoryScreen(uid: uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc b) => b.state.user.displayName);
    final uid = context.select((AuthBloc b) => b.state.user.uid);

    return BlocListener<ShareCubit, ShareState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == ShareStatus.ready &&
            state.code != null &&
            state.pin != null) {
          ShareQrSheet.show(
            context,
            code: state.code!,
            pin: state.pin!,
            expiresLabel: 'Expires in ${state.duration.toLowerCase()}',
          );
        } else if (state.status == ShareStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Something went wrong.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.canvas,
        extendBody: true,
        body: Column(
          children: [
            ShareAppBar(
              greeting: _greeting,
              name: _firstName(displayName),
              onAvatarTap: () => AppShell.of(context)?.goToTab(MediTab.profile),
              // The only notifications MediCarry raises are dose reminders,
              // so the bell goes where they are configured.
              onNotifications: () => AppNav.openMedications(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 128),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: BlocBuilder<ShareCubit, ShareState>(
                      builder: (context, state) {
                        final cubit = context.read<ShareCubit>();
                        final busy = state.status == ShareStatus.generating;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HeaderSection(),
                            const SizedBox(height: 16),
                            _ScanEntry(
                              onScan: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ScanScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            QuickShareCard(
                              busy: busy,
                              code: state.status == ShareStatus.ready
                                  ? state.code
                                  : null,
                              onShowQr: () => _generate(context),
                            ),
                            const SizedBox(height: 24),
                            AccessSelectionCard(
                              selected: state.categories,
                              onToggle: cubit.toggleCategory,
                            ),
                            const SizedBox(height: 24),
                            AccessSettingsCard(
                              duration: state.duration,
                              durations: ShareCubit.durations,
                              onDurationChanged: cubit.setDuration,
                              onSendLink: () => _generate(context),
                              onOpenSettings: _openAccessSettings,
                            ),
                            const SizedBox(height: 24),
                            ExportOptionsCard(
                              busy: _exporting,
                              onDownloadPdf: _exportPdf,
                            ),
                            const SizedBox(height: 24),
                            _ActiveShares(
                              uid: uid,
                              onSeeAll: () => _openHistory(uid),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streams the patient's real grants and filters to the active ones.
class _ActiveShares extends StatelessWidget {
  const _ActiveShares({required this.uid, required this.onSeeAll});

  final String uid;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SharesRepository>();
    return StreamBuilder<List<ShareGrant>>(
      stream: repo.watchShares(uid),
      builder: (context, snapshot) {
        final active =
            (snapshot.data ?? const []).where((g) => g.isActive).toList();
        return ActiveSharesList(
          shares: active,
          onSeeAll: onSeeAll,
          onRevoke: (g) => repo.revoke(uid, g.id),
        );
      },
    );
  }
}

/// Explains what the access controls actually do, and offers the one action
/// that is not expressible through them: revoking everything at once.
class _AccessSettingsSheet extends StatelessWidget {
  const _AccessSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How sharing works',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _SettingsPoint(
              icon: Icons.tune,
              title: 'You choose what is included',
              body: 'Only the categories you tick are written into the code. '
                  'Nothing else leaves your phone.',
            ),
            const _SettingsPoint(
              icon: Icons.timer_outlined,
              title: 'The code expires',
              body: 'The expiry is written inside the code itself, so a '
                  'recipient app refuses it even with no network.',
            ),
            const _SettingsPoint(
              icon: Icons.lock_outline,
              title: 'A PIN unlocks it',
              body: 'The records are encrypted with the PIN you read aloud. '
                  'Without that PIN the code is unreadable.',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Revoke all active shares'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPoint extends StatelessWidget {
  const _SettingsPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.indigoFinal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    height: 19 / 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanEntry extends StatelessWidget {
  const _ScanEntry({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onScan,
        icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.slate),
        label: Text(
          'Scan a shared code',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate,
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'Share Records',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              height: 24 / 16,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Text(
              'Securely provide access to your health history to doctors, '
              'clinics, or caregivers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                height: 24 / 16,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
