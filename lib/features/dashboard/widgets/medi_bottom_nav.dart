import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// The tabs of [MediBottomNav].
enum MediTab { home, history, cards, profile }

/// Bottom navigation bar from the Dashboard (Final) design: four tabs with a
/// raised navy scan/add action overhanging the centre.
///
/// Shared across screens so the bar stays identical app-wide (the individual
/// Figma frames drift on label size/colour). Pass [active] to highlight the
/// current tab; omit it for the Dashboard's all-inactive treatment.
class MediBottomNav extends StatelessWidget {
  const MediBottomNav({
    super.key,
    this.active,
    this.onHome,
    this.onHistory,
    this.onScan,
    this.onCards,
    this.onProfile,
  });

  /// The highlighted tab, or null for none.
  final MediTab? active;

  final VoidCallback? onHome;
  final VoidCallback? onHistory;
  final VoidCallback? onScan;
  final VoidCallback? onCards;
  final VoidCallback? onProfile;

  /// Roughly how tall the bar is at the default text scale, excluding the
  /// system's bottom inset.
  ///
  /// Only a starting estimate: the bar grows with the text scale, so anything
  /// that needs to sit clear of it should use the measured height that
  /// [AppShell] publishes rather than this. It exists so the first frame — and
  /// screens rendered outside the shell — have a sane value.
  static const estimatedHeight = 108.0;

  /// [estimatedHeight] plus the system's bottom inset.
  ///
  /// Reads `viewPadding` rather than `padding` because Scaffold consumes the
  /// latter for its body, which would zero the gesture inset here.
  static double estimatedClearance(BuildContext context) =>
      estimatedHeight + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _Tab(
                icon: AppAssets.navHome,
                label: 'Home',
                width: 18.667,
                height: 21,
                isActive: active == MediTab.home,
                onTap: onHome,
              ),
              _Tab(
                icon: AppAssets.navHistory,
                label: 'Records',
                width: 21,
                height: 21,
                isActive: active == MediTab.history,
                onTap: onHistory,
              ),
              _CenterAction(onTap: onScan),
              _Tab(
                icon: AppAssets.navCards,
                label: 'My Cards',
                width: 23.333,
                height: 18.667,
                isActive: active == MediTab.cards,
                onTap: onCards,
              ),
              _Tab(
                icon: AppAssets.navProfile,
                label: 'Profile',
                width: 18.667,
                height: 18.667,
                isActive: active == MediTab.profile,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.width,
    required this.height,
    this.isActive = false,
    this.onTap,
  });

  final String icon;
  final String label;
  final double width;
  final double height;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Navy would vanish on the dark navy bar, so the active tab uses the lime
    // accent in dark (matching the dark design reference).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.limeFinal : AppColors.navy;
    final color = isActive ? activeColor : context.colors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: SvgPicture.asset(
                  icon,
                  width: width,
                  height: height,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  height: 16.5 / 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised centre scan/add action. It sits 32px above the bar, so the
/// parent Stack must not clip.
class _CenterAction extends StatelessWidget {
  const _CenterAction({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The centre action mirrors the active-tab treatment: navy in light, lime
    // in dark. Its ring cuts the button out of the bar, so it matches the bar.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 60,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -32,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.limeFinal : AppColors.navy,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.navScan,
                    width: 23.333,
                    height: 23.333,
                    // The button itself turns lime in dark mode, so the
                    // glyph's own light fill would disappear into it. Tinted
                    // to the deep green that reads against lime.
                    colorFilter: isDark
                        ? const ColorFilter.mode(
                            AppColors.olive,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
