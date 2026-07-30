import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "Latest BP" dark navy vitals card from the Dashboard (Final) design.
class VitalsCard extends StatelessWidget {
  const VitalsCard({
    super.key,
    required this.reading,
    required this.unit,
    required this.trendLabel,
    this.label = 'LATEST BP',
  });

  /// The card's eyebrow, e.g. "LATEST BP". Comes from the record's title, so a
  /// weight or blood-sugar record isn't mislabelled as a BP reading.
  final String label;

  /// e.g. "118/76".
  final String reading;

  /// e.g. "mmHg".
  final String unit;

  /// e.g. "Slightly lower than yesterday".
  final String trendLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.navy,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.heart,
                width: 16.667,
                height: 15.292,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // scaleDown keeps the reading on one line if the text scale or
              // screen is smaller than the design's; identical at 390pt.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      reading,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 40,
                        height: 60 / 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        height: 24 / 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.limeFinal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      AppAssets.trendDown,
                      width: 13.333,
                      height: 8,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        trendLabel,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: AppColors.limeFinal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
