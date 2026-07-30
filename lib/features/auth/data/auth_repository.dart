import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/env.dart';
import '../models/app_user.dart';

/// Raised for auth failures with a message safe to show to the user.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps Firebase Auth + Google Sign-In behind a plain Dart API so the blocs
/// (and tests) never touch Firebase types directly.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignInOverride = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignInOverride;

  /// Built lazily so a missing Google client ID surfaces only when Google
  /// sign-in is actually used — never at app startup or on sign-out.
  late final GoogleSignIn _googleSignIn =
      _googleSignInOverride ?? _buildGoogleSignIn();

  /// Google Sign-In needs an OAuth client ID that Firebase's own options don't
  /// carry. They come from `.env` (see [Env]) rather than `google-services.json`
  /// / `GoogleService-Info.plist`, which are git-ignored.
  static GoogleSignIn _buildGoogleSignIn() {
    const scopes = <String>['email'];
    if (kIsWeb) {
      return GoogleSignIn(clientId: Env.googleWebClientId, scopes: scopes);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return GoogleSignIn(
          clientId: Env.googleIosClientId,
          serverClientId: Env.googleWebClientId,
          scopes: scopes,
        );
      default:
        // Android: `clientId` is not supported here — the web client ID is
        // passed as serverClientId so the plugin can request an idToken.
        return GoogleSignIn(
          serverClientId: Env.googleWebClientId,
          scopes: scopes,
        );
    }
  }

  /// Returns an actionable message if the OAuth client ID this platform needs
  /// is absent from `.env`, else null. Web is exempt — it goes through
  /// Firebase's own popup and needs no client ID from us.
  static String? _missingGoogleConfig() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Env.googleIosClientId == null
            ? 'Google Sign-In is not configured: add GOOGLE_IOS_CLIENT_ID to .env.'
            : null;
      default:
        return Env.googleWebClientId == null
            ? 'Google Sign-In is not configured: add GOOGLE_WEB_CLIENT_ID to .env '
                '(Android uses it as the serverClientId to obtain an idToken).'
            : null;
    }
  }

  /// Emits the current user (or [AppUser.empty]) on every auth state change.
  Stream<AppUser> get user =>
      _firebaseAuth.authStateChanges().map(_mapFirebaseUser);

  AppUser get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.sendEmailVerification();
      await cred.user?.reload();
      return _mapFirebaseUser(_firebaseAuth.currentUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _mapFirebaseUser(cred.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }


  Future<AppUser> signInWithGoogle() async {
    try {
      return kIsWeb ? await _signInWithGoogleWeb() : await _signInWithGoogleNative();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on PlatformException catch (e) {
      // Google Play Services rejects the sign-in *before* Firebase is ever
      // reached, so these never surface as a FirebaseAuthException. Left
      // untranslated they escaped as a raw PlatformException, which no caller
      // catches — leaving the button spinning with nothing said.
      throw AuthException(_messageForPlatform(e));
    }
  }

  /// Turns a google_sign_in [PlatformException] into something a person can
  /// act on. The codes arrive nested in the message as
  /// `ApiException: <n>`, so both the code and the text are inspected.
  static String _messageForPlatform(PlatformException e) {
    final detail = '${e.code} ${e.message ?? ''}';
    if (detail.contains('12501') || e.code == 'sign_in_canceled') {
      return 'Google sign-in was cancelled.';
    }
    if (detail.contains('ApiException: 7') || e.code == 'network_error') {
      return 'Network error during Google sign-in. Check your connection and '
          'try again.';
    }
    if (detail.contains('ApiException: 10')) {
      return 'Google rejected this app (DEVELOPER_ERROR). The Android package '
          'name and signing SHA-1 must both be registered on the same app in '
          'the Firebase console.';
    }
    return e.message?.trim().isNotEmpty ?? false
        ? 'Google sign-in failed: ${e.message}'
        : 'Google sign-in failed. Please try again.';
  }

  Future<AppUser> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider()..addScope('email');
    final cred = await _firebaseAuth.signInWithPopup(provider);
    return _mapFirebaseUser(cred.user);
  }


  Future<AppUser> _signInWithGoogleNative() async {
    final missingConfig = _missingGoogleConfig();
    if (missingConfig != null) throw AuthException(missingConfig);

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw const AuthException(
        'Google sign-in did not return an idToken. Check that '
        'GOOGLE_WEB_CLIENT_ID in .env matches your Firebase project and that '
        'your signing SHA-1 is registered (Android).',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _firebaseAuth.signInWithCredential(credential);
    return _mapFirebaseUser(cred.user);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // On web there is no google_sign_in session to end — signing out of
    // Firebase is enough, and touching the plugin would needlessly boot GIS.
    if (!kIsWeb) await _googleSignIn.signOut();
  }

  AppUser _mapFirebaseUser(User? user) {
    if (user == null) return AppUser.empty;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 8 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'popup-blocked':
        return 'Your browser blocked the sign-in popup. Allow popups for this '
            'site and try again.';
      case 'unauthorized-domain':
        return 'This domain is not authorized for sign-in. Add it in Firebase '
            'console → Authentication → Settings → Authorized domains.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists using a different '
            'sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in provider is disabled. Enable it in Firebase '
            'console → Authentication → Sign-in method.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
