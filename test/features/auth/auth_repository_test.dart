import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medi_carry/core/config/env.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late MockGoogleSignIn googleSignIn;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    googleSignIn = MockGoogleSignIn();
  });

  AuthRepository build() => AuthRepository(
        firebaseAuth: firebaseAuth,
        googleSignIn: googleSignIn,
      );

  group('signInWithGoogle configuration gate', () {
    // Tests run with defaultTargetPlatform == android, where the web client ID
    // is required as the serverClientId.
    test('throws an actionable error when GOOGLE_WEB_CLIENT_ID is absent', () async {
      Env.loadFromMap({});

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('GOOGLE_WEB_CLIENT_ID'),
          ),
        ),
      );
      verifyNever(() => googleSignIn.signIn());
    });

    test('proceeds to Google sign-in once the client ID is configured', () async {
      Env.loadFromMap({'GOOGLE_WEB_CLIENT_ID': 'web-client-id.apps.googleusercontent.com'});
      when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

      // Passing the config gate means the cancellation path is reached.
      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Google sign-in was cancelled.',
          ),
        ),
      );
      verify(() => googleSignIn.signIn()).called(1);
    });
  });

  group('REGRESSION: Play Services failures are translated, not swallowed', () {
    // These never reach Firebase, so they arrive as PlatformException rather
    // than FirebaseAuthException. Untranslated they escaped every caller and
    // left the sign-in button spinning with nothing shown.
    setUp(() {
      Env.loadFromMap({
        'GOOGLE_WEB_CLIENT_ID': 'web-client-id.apps.googleusercontent.com',
      });
    });

    Future<void> expectMessage(
      PlatformException thrown,
      Matcher messageMatcher,
    ) async {
      when(() => googleSignIn.signIn()).thenThrow(thrown);
      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', messageMatcher),
        ),
      );
    }

    test('DEVELOPER_ERROR names the package-name / SHA-1 pairing', () async {
      // What a package-name or fingerprint mismatch actually throws.
      await expectMessage(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10: ',
        ),
        allOf(contains('package name'), contains('SHA-1')),
      );
    });

    test('a cancelled sign-in is reported as cancelled', () async {
      await expectMessage(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 12501: ',
        ),
        equals('Google sign-in was cancelled.'),
      );
    });

    test('a network failure is reported as a network failure', () async {
      await expectMessage(
        PlatformException(
          code: 'network_error',
          message: 'com.google.android.gms.common.api.ApiException: 7: ',
        ),
        contains('Network error'),
      );
    });

    test('an unrecognised failure still surfaces its message', () async {
      await expectMessage(
        PlatformException(code: 'sign_in_failed', message: 'something odd'),
        contains('something odd'),
      );
    });
  });
}
