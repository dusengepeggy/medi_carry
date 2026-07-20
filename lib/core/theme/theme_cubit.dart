import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../services/theme_mode_store.dart';

/// Holds the app's appearance preference (system / light / dark) and persists
/// every change, so `MaterialApp.themeMode` can react to it.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required ThemeModeStore store})
      : _store = store,
        super(ThemeMode.system);

  final ThemeModeStore _store;

  /// Load the stored preference. Called once at startup; failures fall back to
  /// following the device rather than blocking the app.
  Future<void> load() async {
    try {
      emit(await _store.read());
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    try {
      await _store.write(mode);
    } catch (_) {
      // The in-memory choice still applies for this session.
    }
  }
}
