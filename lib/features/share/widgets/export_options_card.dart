import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "Export History" slate card from the Share Records (Final) design.
class ExportOptionsCard extends StatelessWidget {
  const ExportOptionsCard({super.key, this.onDownloadPdf, this.busy = false});

  final VoidCallback? onDownloadPdf;

  /// True while the PDF is being generated.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.slate,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle bleeding off the top-right corner.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        AppAssets.exportHistory,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export History',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 24 / 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Download your records as a standardized, encrypted PDF '
                    'document.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 20 / 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: busy ? null : onDownloadPdf,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.slate),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppAssets.download,
                                  width: 9.333,
                                  height: 9.333,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Download PDF',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 16,
                                    height: 24 / 16,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
