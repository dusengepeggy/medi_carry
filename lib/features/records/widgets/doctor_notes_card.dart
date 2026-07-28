import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "Doctor's Notes" navy card from the Record Details (Final) design.
class DoctorNotesCard extends StatelessWidget {
  const DoctorNotesCard({
    super.key,
    required this.notes,
    this.isSigned = true,
  });

  final String notes;
  final bool isSigned;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
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
        child: Stack(
          children: [
            // Decorative quarter-round bleeding off the top-right corner.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppAssets.detailNotes,
                            width: 13.5,
                            height: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Doctor's Notes",
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: 0.9,
                    child: Text(
                      notes,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        height: 26 / 16,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isSigned) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigoFinal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            AppAssets.detailSigned,
                            width: 14.667,
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Signed Digitally',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              height: 18 / 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: AppColors.indigoFinal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
