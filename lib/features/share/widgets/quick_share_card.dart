import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "In-Person Quick Share" navy card from the Share Records (Final) design —
/// the offline QR hand-off that is MediCarry's core differentiator.
class QuickShareCard extends StatelessWidget {
  const QuickShareCard({super.key, this.onShowQr});

  final VoidCallback? onShowQr;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative blurred glows bleeding off the card's corners.
            Positioned(
              top: -80,
              right: -80,
              child: _Glow(size: 256, blur: 32),
            ),
            const Positioned(
              bottom: -40,
              left: -40,
              child: _Glow(size: 160, blur: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _Badge(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  Text(
                    'Generate QR Code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      height: 24 / 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 384),
                    child: Text(
                      'Immediate, temporary access during a consultation. '
                      'Works perfectly offline.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        height: 24 / 16,
                        color: AppColors.periwinkle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShowQrButton(onTap: onShowQr),
                  const SizedBox(height: 32),
                  const _QrPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.blur});

  final double size;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.slate.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.quickShareBadge,
            width: 11.667,
            height: 11.667,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'In-Person Quick Share',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowQrButton extends StatelessWidget {
  const _ShowQrButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.showQr, width: 18, height: 18),
            const SizedBox(width: 8),
            Text(
              'Show QR',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                height: 24 / 16,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White panel holding the QR artwork.
///
/// TODO: the QR here is the design's static sample. The real screen must
/// render a QR encoding the patient's share payload, generated on-device so it
/// works with no connectivity.
class _QrPanel extends StatelessWidget {
  const _QrPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      height: 192,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.qrPlaceholder,
          width: 90,
          height: 90,
        ),
      ),
    );
  }
}
