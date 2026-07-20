import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_cubit.dart';

/// Appearance preference: System / Light / Dark.
///
/// No Figma frame specifies this control, so it follows the Profile screen's
/// card treatment. It is written theme-aware (colours come from the active
/// [ThemeData]) so the control itself repaints correctly the instant the
/// preference changes.
class AppearanceToggle extends StatelessWidget {
  const AppearanceToggle({super.key});

  static const _options = [
    (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = context.watch<ThemeCubit>().state;

    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final titleColor = isDark ? AppColors.textOnDark : AppColors.ink;
    final subtitleColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textSecondary;
    final trackColor = isDark ? AppColors.backgroundDark : AppColors.inputFill;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1A1F36).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          Text(
            'Choose how MediCarry looks on this device',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                for (final (mode, label, icon) in _options)
                  Expanded(
                    child: _Segment(
                      label: label,
                      icon: icon,
                      isSelected: mode == selected,
                      isDark: isDark,
                      onTap: () => context.read<ThemeCubit>().setMode(mode),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? AppColors.limeFinal : AppColors.navy;
    final selectedFg = isDark ? AppColors.limeOnSurface : Colors.white;
    final idleFg = isDark ? AppColors.textMutedDark : AppColors.textGray;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? selectedFg : idleFg),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? selectedFg : idleFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
