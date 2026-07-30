import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colour roles that resolve differently per brightness, so screens
/// can render correctly in both light and dark without branching on
/// `Theme.of(context).brightness` themselves.
///
/// Read via `context.colors` (see the extension at the bottom of this file).
///
/// These roles cover the *chrome* that must flip between modes — page
/// backgrounds, plain cards, text, inputs, borders. Brand surfaces that look
/// the same in both modes (the navy hero cards, the lime accent cards, the
/// navy/lime buttons) intentionally keep their literal [AppColors] values at
/// the call site rather than going through a role.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.cardShadow,
  });

  /// Scaffold / page background.
  final Color canvas;

  /// Primary card background (was white in light).
  final Color surface;

  /// Subtle fills: inputs, chips, inset panels.
  final Color surfaceMuted;

  /// Headings and primary body text (was navy/ink in light).
  final Color textPrimary;

  /// Secondary text.
  final Color textSecondary;

  /// Placeholders and tertiary text.
  final Color textMuted;

  /// Hairline borders and dividers.
  final Color border;

  /// Shadow colour for elevated cards (softened to nothing in dark).
  final Color cardShadow;

  static const light = AppSemanticColors(
    canvas: AppColors.canvas,
    surface: AppColors.white,
    surfaceMuted: AppColors.indigoSurface,
    textPrimary: AppColors.navy,
    textSecondary: AppColors.textGray,
    textMuted: AppColors.textMuted,
    border: AppColors.borderGray,
    cardShadow: Color(0x0D1A1F36),
  );

  static const dark = AppSemanticColors(
    canvas: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceMuted: AppColors.fillDark,
    textPrimary: AppColors.textOnDark,
    textSecondary: AppColors.textMutedDark,
    textMuted: AppColors.textMutedDark,
    border: Color(0xFF2A3568),
    cardShadow: Color(0x00000000),
  );

  @override
  AppSemanticColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? cardShadow,
  }) =>
      AppSemanticColors(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// `context.colors.surface`, `context.colors.textPrimary`, …
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
