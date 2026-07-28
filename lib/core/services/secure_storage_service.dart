import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the offline app-lock PIN as a salted SHA-256 hash in the platform
/// secure store (Keychain / EncryptedSharedPreferences). The raw PIN is never
/// persisted. Also records whether the user opted into biometric unlock.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';
  static const _biometricKey = 'app_lock_biometric_enabled';

  /// Whether a PIN has been set on this device.
  Future<bool> hasPin() async =>
      await _storage.read(key: _pinHashKey) != null;

  /// Persist a new PIN (stored salted + hashed).
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: _hash(pin, salt));
  }

  /// Verify [pin] against the stored hash. Returns false if no PIN is set.
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final expected = await _storage.read(key: _pinHashKey);
    if (salt == null || expected == null) return false;
    return _constantTimeEquals(_hash(pin, salt), expected);
  }

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricKey) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: enabled.toString());

  /// Clear all lock data (e.g. on sign-out).
  Future<void> clear() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _biometricKey);
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
