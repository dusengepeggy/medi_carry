import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../profile/widgets/patient_avatar.dart';

/// Translucent top app bar from the Share Records (Final) design: avatar,
/// greeting, and a notifications action.
class ShareAppBar extends StatelessWidget {
  const ShareAppBar({
    super.key,
    required this.greeting,
    this.name,
    this.onAvatarTap,
    this.onNotifications,
  });

  /// e.g. "Good Morning!".
  final String greeting;

  /// The patient's first name, shown as "Hi, {name}".
  final String? name;

  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          // Hardcoded white left the greeting as light text on a white bar in
          // dark mode. The translucency that the blur needs comes from the
          // theme's own surface now.
          color: context.colors.surface.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: onAvatarTap,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: context.colors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: const LivePatientAvatar(size: 40),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name == null || name!.isEmpty
                                        ? 'Hi there'
                                        : 'Hi, $name',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 14,
                                      height: 17.5 / 14,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    greeting,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 18,
                                      height: 22.5 / 18,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: onNotifications,
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            AppAssets.notifications,
                            width: 18,
                            height: 18,
                            // Exported as dark ink, which is invisible on the
                            // dark bar.
                            colorFilter: ColorFilter.mode(
                              context.colors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
