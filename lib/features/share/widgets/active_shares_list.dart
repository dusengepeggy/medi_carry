import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../models/share_grant.dart';

/// "Active Shares" list from the Share Records (Final) design, backed by the
/// patient's real grants. Revoking is the patient's escape hatch, so each row
/// exposes it directly.
class ActiveSharesList extends StatelessWidget {
  const ActiveSharesList({
    super.key,
    required this.shares,
    this.onSeeAll,
    this.onRevoke,
  });

  final List<ShareGrant> shares;
  final VoidCallback? onSeeAll;
  final void Function(ShareGrant share)? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Shares',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  height: 24 / 16,
                  color: context.colors.textPrimary,
                ),
              ),
              // Always offered: the history is also where expired and revoked
              // shares are auditable, and those are exactly the cases where
              // the active list is empty.
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See All',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.slate,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (shares.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'No active shares. Anything you share will appear here so you can '
              'revoke it.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                color: context.colors.textSecondary,
              ),
            ),
          )
        else
          for (var i = 0; i < shares.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ShareRow(
              share: shares[i],
              onRevoke: onRevoke == null ? null : () => onRevoke!(shares[i]),
            ),
          ],
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share, this.onRevoke});

  final ShareGrant share;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.hospital,
                width: 18,
                height: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.recipientLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    height: 24 / 16,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${share.expiryLabel} • ${share.categories.length} '
                  '${share.categories.length == 1 ? 'category' : 'categories'}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    height: 16 / 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRevoke,
            tooltip: 'Revoke access',
            icon: SvgPicture.asset(
              AppAssets.revoke,
              width: 16.667,
              height: 16.667,
            ),
          ),
        ],
      ),
    );
  }
}
