import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../data/shares_repository.dart';
import '../models/share_grant.dart';
import '../models/share_payload.dart';
import '../widgets/active_shares_list.dart';

/// Every share the patient has ever granted — live, expired and revoked.
///
/// The Share screen only lists what is currently active; this is the audit
/// trail behind it, which is the half of "granular sharing" that makes the
/// control meaningful.
class ShareHistoryScreen extends StatelessWidget {
  const ShareHistoryScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final repository = context.read<SharesRepository>();
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Share history',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ShareGrant>>(
          stream: repository.watchShares(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final shares = snapshot.data ?? const <ShareGrant>[];
            if (shares.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'You have not shared anything yet. Every share you create '
                    'is listed here so you can revoke it.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 24 / 16,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            final active = shares.where((s) => s.isActive).toList();
            final past = shares.where((s) => !s.isActive).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (active.isNotEmpty) ...[
                  ActiveSharesList(
                    shares: active,
                    onRevoke: (grant) => repository.revoke(uid, grant.id),
                  ),
                  const SizedBox(height: 24),
                ],
                if (past.isNotEmpty) ...[
                  Text(
                    'NO LONGER ACTIVE',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final grant in past) ...[
                    _PastShareRow(grant: grant),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PastShareRow extends StatelessWidget {
  const _PastShareRow({required this.grant});

  final ShareGrant grant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = grant.categories
        .map((id) => ShareCategory.fromId(id)?.label ?? id)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            grant.revoked ? Icons.block : Icons.history,
            size: 20,
            color: grant.revoked ? AppColors.danger : colors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.recipientLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${grant.expiryLabel}'
                  '${categories.isEmpty ? '' : ' • $categories'}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    height: 16 / 12,
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
