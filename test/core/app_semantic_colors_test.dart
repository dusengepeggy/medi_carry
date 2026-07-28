import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi_carry/core/theme/app_colors.dart';
import 'package:medi_carry/core/theme/app_semantic_colors.dart';
import 'package:medi_carry/core/theme/app_theme.dart';

void main() {
  // AppTheme builds its text theme with google_fonts; without this it tries to
  // fetch fonts over the network and throws in a plain `test()`.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppSemanticColors', () {
    test('light and dark resolve to different surfaces and text', () {
      expect(AppSemanticColors.light.canvas,
          isNot(equals(AppSemanticColors.dark.canvas)));
      expect(AppSemanticColors.light.surface,
          isNot(equals(AppSemanticColors.dark.surface)));
      expect(AppSemanticColors.light.textPrimary,
          isNot(equals(AppSemanticColors.dark.textPrimary)));
    });

    test('dark surface is the brand navy, dark canvas is deeper', () {
      expect(AppSemanticColors.dark.surface, AppColors.surfaceDark);
      expect(AppSemanticColors.dark.canvas, AppColors.backgroundDark);
    });

    testWidgets('both themes register the extension', (tester) async {
      expect(AppTheme.light.extension<AppSemanticColors>(), isNotNull);
      expect(AppTheme.dark.extension<AppSemanticColors>(), isNotNull);
    });
  });

  testWidgets('context.colors resolves from the active theme', (tester) async {
    late AppSemanticColors seen;

    // A fresh tree per theme (distinct key) avoids AnimatedTheme lerping
    // between brightnesses, which would leave the first frame un-settled.
    Widget probe(ThemeData theme, Key key) => MaterialApp(
          key: key,
          theme: theme,
          home: Builder(
            builder: (context) {
              seen = context.colors;
              return const SizedBox();
            },
          ),
        );

    await tester.pumpWidget(probe(AppTheme.light, const ValueKey('light')));
    expect(seen.surface, AppSemanticColors.light.surface);

    await tester.pumpWidget(probe(AppTheme.dark, const ValueKey('dark')));
    expect(seen.surface, AppSemanticColors.dark.surface);
    expect(seen.canvas, AppColors.backgroundDark);
  });
}
