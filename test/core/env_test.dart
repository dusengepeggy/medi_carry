import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/config/env.dart';
import 'package:medi_carry/core/config/firebase_config.dart';

void main() {
  group('Env', () {
    test('throws a descriptive EnvException when a key is missing', () {
      Env.loadFromMap({});
      expect(
        () => Env.projectId,
        throwsA(
          isA<EnvException>().having(
            (e) => e.message,
            'message',
            allOf(contains('FIREBASE_PROJECT_ID'), contains('.env')),
          ),
        ),
      );
    });

    test('throws when a key is present but blank', () {
      Env.loadFromMap({'FIREBASE_PROJECT_ID': '   '});
      expect(() => Env.projectId, throwsA(isA<EnvException>()));
    });

    test('reads and trims present values; optional keys fall back to null', () {
      Env.loadFromMap({
        'FIREBASE_PROJECT_ID': ' medicarry-dev ',
        'FIREBASE_STORAGE_BUCKET': '',
      });
      expect(Env.projectId, 'medicarry-dev');
      expect(Env.storageBucket, isNull);
    });
  });

  group('FirebaseConfig', () {
    test('channels .env values into FirebaseOptions', () {
      Env.loadFromMap({
        'FIREBASE_PROJECT_ID': 'medicarry-dev',
        'FIREBASE_MESSAGING_SENDER_ID': '1234567890',
        'FIREBASE_STORAGE_BUCKET': 'medicarry-dev.appspot.com',
        'FIREBASE_ANDROID_API_KEY': 'android-key',
        'FIREBASE_ANDROID_APP_ID': '1:1234567890:android:abc',
      });

      final options = FirebaseConfig.android;

      expect(options.apiKey, 'android-key');
      expect(options.appId, '1:1234567890:android:abc');
      expect(options.projectId, 'medicarry-dev');
      expect(options.messagingSenderId, '1234567890');
      expect(options.storageBucket, 'medicarry-dev.appspot.com');
    });
  });
}
