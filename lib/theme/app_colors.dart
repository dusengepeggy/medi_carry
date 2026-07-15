import 'package:flutter/material.dart';

/// MediCarry brand color tokens, extracted from the Figma design
/// (file cRk8IZi3MBSQCPj1pFenWA).
///
/// These are the raw brand values. Semantic mappings (what is a "surface",
/// what is "on primary", etc.) live in [MediCarryLightColors] /
/// [MediCarryDarkColors] and are consumed by `AppTheme`.
abstract final class AppColors {
  AppColors._();

  // ---- Brand palette ------------------------------------------------------
  /// Deep navy — primary actions, hero cards, active navigation.
  static const Color navy = Color(0xFF122056);

  /// Near-black ink — primary text and dark icon buttons.
  static const Color ink = Color(0xFF181C21);

  /// Dark logo surface.
  static const Color logoSurface = Color(0xFF2C3137);

  /// Lime / chartreuse accent — medication card, logo glow, highlights.
  static const Color lime = Color(0xFFBAF600);

  /// Deep olive companion to the lime accent.
  static const Color olive = Color(0xFF4C6700);

  /// Indigo — links and secondary emphasis.
  static const Color indigo = Color(0xFF3C55BF);

  // ---- Neutrals -----------------------------------------------------------
  /// Olive-gray secondary text / labels.
  static const Color textSecondary = Color(0xFF434933);

  /// Muted gray — placeholders and tertiary text.
  static const Color textMuted = Color(0xFF6B7280);

  /// Input / subtle card fill (light theme).
  static const Color fill = Color(0xFFF0F4FB);

  /// Olive divider.
  static const Color divider = Color(0xFFC3CAAC);

  /// App background (light theme).
  static const Color background = Color(0xFFF8F9FF);

  static const Color white = Color(0xFFFFFFFF);

  // ---- Dark-theme neutrals (inferred; Figma specifies light only) --------
  /// Dark app background — a near-black tuned toward the navy brand.
  static const Color backgroundDark = Color(0xFF0C1230);

  /// Elevated surface on dark backgrounds.
  static const Color surfaceDark = Color(0xFF161C3D);

  /// Input / subtle fill on dark backgrounds.
  static const Color fillDark = Color(0xFF1E2547);

  /// Primary text on dark backgrounds.
  static const Color textOnDark = Color(0xFFEDEFF7);

  /// Muted text on dark backgrounds.
  static const Color textMutedDark = Color(0xFF9AA2C4);
}
