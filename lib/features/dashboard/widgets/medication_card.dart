import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "Next medication" neon-accent card from the Dashboard (Final) design.
class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.dueLabel,
    this.onMarkTaken,
    this.onManage,
  });

  /// e.g. "Lisinopril".
  final String name;

  /// e.g. "10mg - Take with food".
  final String dosage;

  /// e.g. "In 2 hours".
  final String dueLabel;

  final VoidCallback? onMarkTaken;

  /// Opens the full regimen. The card shows one dose; without this the rest of
  /// the schedule — and the reminder switches — had no route from the
  /// dashboard once a medication existed.
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onManage,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.limeFinal,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible so a narrow screen or a large text scale ellipsizes
              // the label instead of overflowing; unchanged at design width.
              Flexible(
                child: Opacity(
                  opacity: 0.9,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppAssets.medication,
                        width: 11.667,
                        height: 15,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'NEXT MEDICATION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                            color: AppColors.limeOnSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  dueLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.limeOnSurface,
                  ),
                ),
              ),
              if (onManage != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.limeOnSurface.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32), // 16 gap + 16 top margin
          Text(
            name,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 40,
              height: 60 / 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: AppColors.limeOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dosage,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w500,
              color: AppColors.limeOnSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onMarkTaken,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Mark as Taken',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
