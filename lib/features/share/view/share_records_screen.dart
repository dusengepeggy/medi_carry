import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/data/user_repository.dart';
import '../../dashboard/widgets/medi_bottom_nav.dart' show MediTab;
import '../../records/data/records_repository.dart';
import '../bloc/share_cubit.dart';
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

class _ShareView extends StatelessWidget {
  const _ShareView();

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
              onNotifications: () {},
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
                              onOpenSettings: () {},
                            ),
                            const SizedBox(height: 24),
                            ExportOptionsCard(onDownloadPdf: () {}),
                            const SizedBox(height: 24),
                            _ActiveShares(uid: uid),
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
  const _ActiveShares({required this.uid});

  final String uid;

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
          onSeeAll: () {},
          onRevoke: (g) => repo.revoke(uid, g.id),
        );
      },
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
