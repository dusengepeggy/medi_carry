import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../app/app_shell.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../dashboard/widgets/medi_bottom_nav.dart' show MediTab;
import '../widgets/access_settings_card.dart';
import '../widgets/active_shares_list.dart';
import '../widgets/export_options_card.dart';
import '../widgets/quick_share_card.dart';
import '../widgets/share_app_bar.dart';

/// Share Records — an implementation of the "Share Records (Final)" Figma
/// frame (node 2:137). This is MediCarry's core differentiator: handing a
/// clinician access to records, including offline via QR.
///
/// The QR artwork and the active-shares row are still the design's sample
/// content; they need the records/sharing feature behind them.
class ShareRecordsScreen extends StatefulWidget {
  const ShareRecordsScreen({super.key});

  @override
  State<ShareRecordsScreen> createState() => _ShareRecordsScreenState();
}

class _ShareRecordsScreenState extends State<ShareRecordsScreen> {
  static const _durations = ['1 Hour', '24 Hours', '7 Days', '30 Days'];

  String _duration = '24 Hours';

  /// Placeholder, mirroring the design's sample row.
  static const _shares = [
    ActiveShare(
      recipient: 'Nairobi General Hospital',
      expiry: 'Expires in 2 days',
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc b) => b.state.user.displayName);

    return Scaffold(
      backgroundColor: Colors.white,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeaderSection(),
                      const SizedBox(height: 32),
                      QuickShareCard(onShowQr: () {}),
                      const SizedBox(height: 24),
                      ExportOptionsCard(onDownloadPdf: () {}),
                      const SizedBox(height: 24),
                      AccessSettingsCard(
                        duration: _duration,
                        durations: _durations,
                        onDurationChanged: (v) =>
                            setState(() => _duration = v),
                        onSendLink: () {},
                        onOpenSettings: () {},
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 16),
                      ActiveSharesList(
                        shares: _shares,
                        onSeeAll: () {},
                        onRevoke: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
              color: AppColors.navy,
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
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
