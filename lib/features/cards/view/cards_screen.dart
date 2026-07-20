import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// "My Cards" — the insurance / patient-ID wallet.
///
/// Placeholder: this tab has no Figma frame yet. It exists so the nav tab is
/// not a dead end, and states plainly what it will hold rather than pretending
/// to be finished.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.indigoSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.navy,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'My Cards',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your insurance and patient ID cards will live here, '
                  'available offline.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    height: 24 / 16,
                    color: AppColors.navy.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming soon',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.indigoFinal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
