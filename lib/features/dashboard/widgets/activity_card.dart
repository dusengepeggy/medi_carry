import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// One row of the recent-activity list.
class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconSize = const Size(18, 18),
    this.highlighted = false,
  });

  final String title;

  /// e.g. "Oct 12 • City Lab".
  final String subtitle;

  /// Path to the exported SVG for this entry.
  final String icon;
  final Size iconSize;

  /// When true the icon chip uses the lime tint instead of pale indigo.
  final bool highlighted;
}

/// "Activity" white card listing recent records, from the Dashboard (Final)
/// design.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.entries,
    this.emptyText = 'No recent activity.',
    this.onSeeAll,
    this.onEntryTap,
  });

  final List<ActivityEntry> entries;

  /// Shown in place of the list when [entries] is empty.
  final String emptyText;
  final VoidCallback? onSeeAll;
  final void Function(ActivityEntry entry)? onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    height: 30 / 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See All',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: AppColors.indigoFinal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                emptyText,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: context.colors.textSecondary,
                ),
              ),
            )
          else
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              _ActivityRow(
                entry: entries[i],
                onTap:
                    onEntryTap == null ? null : () => onEntryTap!(entries[i]),
              ),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, this.onTap});

  final ActivityEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.highlighted
                    ? AppColors.limeFinal.withValues(alpha: 0.2)
                    : context.colors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  entry.icon,
                  width: entry.iconSize.width,
                  height: entry.iconSize.height,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 24 / 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SvgPicture.asset(
              AppAssets.chevronRight,
              width: 6.167,
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}
