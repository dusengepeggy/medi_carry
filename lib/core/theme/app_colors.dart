import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ---- Shared primitives --------------------------------------------------

  /// Brightest lime in the palette — distinct from [lime] and [limeFinal].
  static const Color _limeBright = Color(0xFFC1FF00);

  /// Pale blue-gray used both as a border and as a label colour.
  static const Color _paleBlueGray = Color(0xFFDFE2EA);

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

  // ---- "Final" screen palette --------------------------------------------
  // The Dashboard/Records/Details/Share "(Final)" frames in Figma use a
  // refined palette that differs slightly from the older Log In / Sign Up
  // frames the tokens above came from. These are the values used by the
  // dashboard.

  /// Neon accent used by the medication card (Final). Brighter than [lime].
  static const Color limeFinal = Color(0xFFC1F100);

  /// Ink used on top of [limeFinal].
  static const Color limeOnSurface = Color(0xFF161E00);

  /// Violet-indigo for the Emergency button and links (Final).
  static const Color indigoFinal = Color(0xFF5B65DC);

  /// Pale indigo surface: activity icon chips, Add-New-Record card (Final).
  static const Color indigoSurface = Color(0xFFEEEFFD);

  /// App canvas behind the dashboard (Final).
  static const Color canvas = Color(0xFFFAFAFD);

  /// Inactive bottom-navigation item (Final).
  static const Color navInactive = Color(0xFF767680);

  // ---- Share Records (Final) ---------------------------------------------
  /// Slate blue — the Export History card and decorative glows.
  static const Color slate = Color(0xFF4F5B94);

  /// Periwinkle — supporting copy on the navy Quick Share card.
  static const Color periwinkle = Color(0xFFB8C3FF);

  /// Hairline border on cards, list items and the bottom bar.
  static const Color borderGray = Color(0xFFE4E1E7);

  /// Body/secondary text on light surfaces.
  static const Color textGray = Color(0xFF45464F);

  /// Pale lavender surface — Access Settings card, list icon chips.
  static const Color lavenderSurface = Color(0xFFF5F2F8);

  /// Light gray surface — inset panels and icon buttons.
  static const Color graySurface = Color(0xFFEFEDF2);

  /// Near-black used for values and list titles.
  static const Color ink900 = Color(0xFF1B1B1F);

  // ---- Record Details (Final) --------------------------------------------
  /// Warm terracotta surface for the "review required" status badge.
  static const Color warningSurface = Color(0xFFFFDAD6);

  /// Deep red text/icon on [warningSurface].
  static const Color onWarningSurface = Color(0xFF93000A);

  /// Hairline border on outlined buttons and dividers.
  static const Color hairline = Color(0xFFEAE7ED);

  // ---- User Profile ------------------------------------------------------
  // This frame comes from the earlier design group, so it leans on the older
  // palette above (olive/#F8F9FF) rather than the "(Final)" tokens.

  /// Periwinkle used by the patient-ID pill and the active nav tab.
  static const Color periwinkleAccent = Color(0xFF7991FF);

  /// Ring around the top-bar avatar.
  static const Color avatarRing = _limeBright;

  /// Fill behind the top-bar avatar.
  static const Color avatarBackground = Color(0xFFE5E8F0);

  /// Border around the large profile avatar.
  static const Color avatarBorder = _paleBlueGray;

  /// Slate used (at 10%) behind the notification-settings icon.
  static const Color slateGray = Color(0xFF585D77);

  /// Red used (at 10%) behind the security icon.
  static const Color danger = Color(0xFFBA1A1A);

  // ---- Edit Profile ------------------------------------------------------
  /// Fill behind form inputs on light cards.
  static const Color inputFill = Color(0xFFEBEEF6);

  /// Lime SAVE button, and its text.
  static const Color saveButton = _limeBright;
  static const Color saveButtonText = Color(0xFF567300);

  /// Label colour on the dark Emergency Contact card.
  static const Color labelOnDark = _paleBlueGray;

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


  /// Dark app canvas — deeper than [navy], which sits on top of it.
  static const Color backgroundDark = Color(0xFF000A39);

  /// Card surface on dark backgrounds — the brand [navy].
  static const Color surfaceDark = navy;

  /// Elevated surface on dark backgrounds — the brand [slate].
  static const Color surfaceElevatedDark = slate;

  /// Input / subtle fill and hairlines on dark backgrounds.
  static const Color fillDark = Color(0xFF1E2C63);

  /// Primary text on dark backgrounds.
  static const Color textOnDark = Color(0xFFEDEFF7);

  /// Muted text on dark backgrounds.
  static const Color textMutedDark = Color(0xFF9AA2C4);
}
