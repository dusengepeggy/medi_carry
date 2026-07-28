import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/theme_mode_store.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/core/theme/theme_cubit.dart';
import 'package:medi_carry/features/profile/widgets/appearance_toggle.dart';
import 'package:mocktail/mocktail.dart';

class MockThemeModeStore extends Mock implements ThemeModeStore {}

void main() {
  late MockThemeModeStore store;
  late ThemeCubit cubit;

  setUpAll(() => registerFallbackValue(ThemeMode.system));

  setUp(() {
    store = MockThemeModeStore();
    when(() => store.read()).thenAnswer((_) async => ThemeMode.system);
    when(() => store.write(any())).thenAnswer((_) async {});
    cubit = ThemeCubit(store: store);
  });

  tearDown(() => cubit.close());

  /// Pumps the toggle inside a MaterialApp whose themeMode follows the cubit,
  /// mirroring how `app.dart` wires it.
  Future<void> pumpToggle(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20),
                child: AppearanceToggle(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers System, Light and Dark', (tester) async {
    await pumpToggle(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('selecting Dark switches the app to the dark theme',
      (tester) async {
    await pumpToggle(tester);
    expect(cubit.state, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(cubit.state, ThemeMode.dark);
    // The MaterialApp really rebuilt in dark, not just the cubit.
    final ctx = tester.element(find.byType(AppearanceToggle));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('selecting Light switches back', (tester) async {
    await pumpToggle(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(cubit.state, ThemeMode.light);
    final ctx = tester.element(find.byType(AppearanceToggle));
    expect(Theme.of(ctx).brightness, Brightness.light);
  });

  testWidgets('the choice is persisted so it survives a restart',
      (tester) async {
    await pumpToggle(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    verify(() => store.write(ThemeMode.dark)).called(1);
  });

  group('ThemeCubit', () {
    test('loads the stored preference at startup', () async {
      when(() => store.read()).thenAnswer((_) async => ThemeMode.dark);
      final c = ThemeCubit(store: store);
      await c.load();
      expect(c.state, ThemeMode.dark);
      await c.close();
    });

    test('falls back to system when the store throws', () async {
      when(() => store.read()).thenThrow(Exception('unavailable'));
      final c = ThemeCubit(store: store);
      await c.load();
      expect(c.state, ThemeMode.system);
      await c.close();
    });

    test('re-selecting the current mode does not write again', () async {
      final c = ThemeCubit(store: store);
      await c.setMode(ThemeMode.system); // already the initial state
      verifyNever(() => store.write(any()));
      await c.close();
    });
  });
}
