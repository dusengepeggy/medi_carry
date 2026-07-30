import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the patient's appearance preference so it survives a restart.
///
/// Uses `flutter_secure_storage` because it is already a dependency — the
/// preference is not sensitive, so plain preferences would do just as well;
/// this simply avoids adding a package for one key.
class ThemeModeStore {
  ThemeModeStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _key = 'theme_mode';

  Future<ThemeMode> read() async {
    final raw = await _storage.read(key: _key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // Anything else — including no stored value — follows the device.
      _ => ThemeMode.system,
    };
  }

  Future<void> write(ThemeMode mode) => _storage.write(
        key: _key,
        value: switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
}
