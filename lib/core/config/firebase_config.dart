import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'env.dart';

/// Builds [FirebaseOptions] for the current platform from the values in `.env`
/// (see [Env]) — the env-driven replacement for the `firebase_options.dart`
/// that `flutterfire configure` generates.
///
/// If you run `flutterfire configure` to obtain values, copy them into `.env`
/// and delete the generated `lib/firebase_options.dart` (it is git-ignored);
/// this class stays the single source of truth.
abstract final class FirebaseConfig {
  FirebaseConfig._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseConfig is not configured for $defaultTargetPlatform. '
          'MediCarry targets Android and iOS (web for development).',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: Env.androidApiKey,
        appId: Env.androidAppId,
        messagingSenderId: Env.messagingSenderId,
        projectId: Env.projectId,
        storageBucket: Env.storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: Env.iosApiKey,
        appId: Env.iosAppId,
        messagingSenderId: Env.messagingSenderId,
        projectId: Env.projectId,
        storageBucket: Env.storageBucket,
        iosBundleId: Env.iosBundleId,
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: Env.webApiKey,
        appId: Env.webAppId,
        messagingSenderId: Env.messagingSenderId,
        projectId: Env.projectId,
        storageBucket: Env.storageBucket,
        authDomain: Env.webAuthDomain,
        measurementId: Env.webMeasurementId,
      );
}
