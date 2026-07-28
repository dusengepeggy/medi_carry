import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// A tappable settings row from the User Profile design: tinted icon chip,
/// title + description, and a chevron.
class ProfileOptionCard extends StatelessWidget {
  const ProfileOptionCard({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.accent,
    required this.title,
    required this.description,
    this.onTap,
  });

  final String icon;
  final Size iconSize;

  /// Colour the icon chip is tinted with (at 10%).
  final Color accent;

  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1F36).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      icon,
                      width: iconSize.width,
                      height: iconSize.height,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SvgPicture.asset(
                  AppAssets.profileChevron,
                  width: 7.4,
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
