import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/services/share_crypto.dart';

void main() {
  group('ShareCrypto', () {
    test('round-trips plaintext under the correct PIN', () {
      const plaintext = '{"n":"Sarah Johnson","bt":"O+"}';
      final code = ShareCrypto.encryptToCode(plaintext, '1234');

      expect(code.startsWith(ShareCrypto.prefix), isTrue);
      expect(ShareCrypto.decryptFromCode(code, '1234'), plaintext);
    });

    test('a wrong PIN throws rather than returning garbage', () {
      final code = ShareCrypto.encryptToCode('secret', '1234');
      expect(
        () => ShareCrypto.decryptFromCode(code, '9999'),
        throwsA(isA<ShareDecryptException>()),
      );
    });

    test('a non-MediCarry code is rejected', () {
      expect(
        () => ShareCrypto.decryptFromCode('https://example.com', '1234'),
        throwsA(isA<ShareDecryptException>()),
      );
    });

    test('two encryptions of the same data differ (random salt + IV)', () {
      final a = ShareCrypto.encryptToCode('x', '1234');
      final b = ShareCrypto.encryptToCode('x', '1234');
      expect(a, isNot(equals(b)));
    });

    test('a realistic summary stays within a QR byte budget', () {
      // A generous summary: identity + several allergies/conditions + records.
      final payload = jsonEncode({
        'v': 1,
        'n': 'Sarah Johnson',
        'pid': 'MC-8829-41',
        'exp': DateTime.now().millisecondsSinceEpoch,
        'bt': 'O+',
        'al': ['Penicillin', 'Peanuts', 'Latex'],
        'co': ['Asthma', 'Hypertension'],
        'ecn': 'James Johnson',
        'ecp': '+254 700 000 000',
        'rec': List.generate(
          6,
          (i) => {
            'c': 'MEDICATION',
            't': 'Medication number $i',
            'd': '1 tablet twice daily',
            'dt': 'Oct 24, 2023',
          },
        ),
      });
      final code = ShareCrypto.encryptToCode(payload, '1234');
      // QR (byte mode, ECC L) tops out ~2953 bytes; stay comfortably under.
      expect(code.length, lessThan(2000));
    });
  });
}
