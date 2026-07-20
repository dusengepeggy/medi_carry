import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// A share the patient has granted and can revoke.
class ActiveShare {
  const ActiveShare({required this.recipient, required this.expiry});

  /// e.g. "Nairobi General Hospital".
  final String recipient;

  /// e.g. "Expires in 2 days".
  final String expiry;
}

/// "Active Shares" list from the Share Records (Final) design. Revoking is the
/// patient's escape hatch, so each row exposes it directly.
class ActiveSharesList extends StatelessWidget {
  const ActiveSharesList({
    super.key,
    required this.shares,
    this.onSeeAll,
    this.onRevoke,
  });

  final List<ActiveShare> shares;
  final VoidCallback? onSeeAll;
  final void Function(ActiveShare share)? onRevoke;

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
                  color: AppColors.navy,
                ),
              ),
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

  final ActiveShare share;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
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
              color: AppColors.lavenderSurface,
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
                  share.recipient,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    height: 24 / 16,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  share.expiry,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGray,
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
