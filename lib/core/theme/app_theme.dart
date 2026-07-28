import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';

/// MediCarry application theme.
///
/// Exposes a [light] and [dark] [ThemeData], both Material 3, built from the
/// brand tokens in [AppColors]. Typography is Hanken Grotesk throughout —
/// the family used by the MediCarry designs — loaded at runtime via
/// `google_fonts`.
abstract final class AppTheme {
  AppTheme._();

  static const double _radius = 24;

  static ThemeData get light => _build(_lightScheme, Brightness.light);
  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  // ---- Color schemes ------------------------------------------------------
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.navy,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.indigo,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.lime,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.indigo,
    onTertiary: AppColors.white,
    error: Color(0xFFB3261E),
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.fill,
    surfaceContainerHigh: AppColors.fill,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.divider,
    outlineVariant: AppColors.fill,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.lime,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.navy,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.olive,
    onSecondaryContainer: AppColors.white,
    tertiary: Color(0xFF9AABFF),
    onTertiary: AppColors.ink,
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textOnDark,
    surfaceContainerLowest: AppColors.backgroundDark,
    surfaceContainerLow: AppColors.backgroundDark,
    surfaceContainer: AppColors.fillDark,
    surfaceContainerHigh: AppColors.fillDark,
    onSurfaceVariant: AppColors.textMutedDark,
    outline: Color(0xFF3A4270),
    outlineVariant: AppColors.fillDark,
  );

  // ---- Builder ------------------------------------------------------------
  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final AppSemanticColors semantic =
        isDark ? AppSemanticColors.dark : AppSemanticColors.light;
    final Color scaffoldBg = semantic.canvas;

    // Hanken Grotesk throughout — the typeface used by the MediCarry
    // "(Final)" designs. Weight carries the hierarchy rather than a second
    // family.
    final TextTheme base = GoogleFonts.hankenGroteskTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    final TextTheme textTheme = base.copyWith(
      displayLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: scheme.onSurface,
      ),
      displayMedium: GoogleFonts.hankenGrotesk(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: scheme.onSurface,
      ),
      displaySmall: GoogleFonts.hankenGrotesk(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineSmall: GoogleFonts.hankenGrotesk(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.hankenGrotesk(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      labelMedium: GoogleFonts.hankenGrotesk(
        textStyle: base.labelMedium,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [semantic],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.tertiary,
          textStyle: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.fillDark : AppColors.fill,
        hintStyle: GoogleFonts.hankenGrotesk(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.hankenGrotesk(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.4),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondary,
        labelStyle: GoogleFonts.hankenGrotesk(
          color: scheme.onSecondary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
