import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// Top app bar from the Dashboard (Final) design: avatar, wordmark, search.
class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({super.key, this.onAvatarTap, this.onSearch});

  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      // Stand-in until patient profile photos are wired up.
                      child: Image.asset(
                        AppAssets.avatarPlaceholder,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'MediCarry',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  height: 30 / 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: onSearch,
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset(
                    AppAssets.search,
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
