import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

/// Thrown when a payload can't be decrypted — wrong PIN, tampering, or a
/// malformed code.
class ShareDecryptException implements Exception {
  const ShareDecryptException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Symmetric encryption for the offline share QR.
///
/// True asymmetric end-to-end encryption is impossible for an accountless
/// walk-up recipient (there's no recipient key), so the payload is protected
/// with a short **PIN the patient reads aloud**: PBKDF2 derives an AES key from
/// the PIN + a random salt, and AES-GCM provides confidentiality *and*
/// tamper-detection (a wrong PIN fails the GCM tag rather than yielding
/// garbage). Everything needed to decrypt except the PIN travels inside the
/// code, so it works entirely offline.
abstract final class ShareCrypto {
  ShareCrypto._();

  /// Prefix that marks a MediCarry share code (and its format version).
  static const prefix = 'MEDICARRY:1:';

  static const _saltLength = 16;
  static const _ivLength = 12; // GCM standard
  static const _iterations = 10000;
  static const _keyBits = 256;

  /// Encrypts [plaintext] under [pin], returning a QR-ready string
  /// `MEDICARRY:1:<base64url(salt|iv|ciphertext+tag)>`.
  static String encryptToCode(String plaintext, String pin) {
    final salt = _randomBytes(_saltLength);
    final iv = enc.IV(_randomBytes(_ivLength));
    final key = enc.Key(_deriveKey(pin, salt));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    final encrypted = encrypter.encryptBytes(utf8.encode(plaintext), iv: iv);
    final blob = Uint8List.fromList([...salt, ...iv.bytes, ...encrypted.bytes]);
    return '$prefix${base64Url.encode(blob)}';
  }

  /// Reverses [encryptToCode]. Throws [ShareDecryptException] on a wrong PIN or
  /// a malformed / non-MediCarry code.
  static String decryptFromCode(String code, String pin) {
    if (!code.startsWith(prefix)) {
      throw const ShareDecryptException('This is not a MediCarry code.');
    }
    late final Uint8List blob;
    try {
      blob = base64Url.decode(code.substring(prefix.length));
    } catch (_) {
      throw const ShareDecryptException('This code is damaged.');
    }
    if (blob.length <= _saltLength + _ivLength) {
      throw const ShareDecryptException('This code is incomplete.');
    }

    final salt = blob.sublist(0, _saltLength);
    final iv = enc.IV(blob.sublist(_saltLength, _saltLength + _ivLength));
    final cipher = blob.sublist(_saltLength + _ivLength);
    final key = enc.Key(_deriveKey(pin, salt));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    try {
      final bytes = encrypter.decryptBytes(enc.Encrypted(cipher), iv: iv);
      return utf8.decode(bytes);
    } catch (_) {
      // GCM tag mismatch — almost always the wrong PIN.
      throw const ShareDecryptException('Incorrect PIN, or the code is invalid.');
    }
  }

  /// PBKDF2(HMAC-SHA256) — derives a 256-bit key from the PIN and salt.
  static Uint8List _deriveKey(String pin, List<int> salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(
        Uint8List.fromList(salt),
        _iterations,
        _keyBits ~/ 8,
      ));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static Uint8List _randomBytes(int length) {
    final secure = SecureRandom('Fortuna')
      ..seed(KeyParameter(enc.IV.fromSecureRandom(32).bytes));
    return secure.nextBytes(length);
  }
}
