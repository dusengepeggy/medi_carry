import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Thrown when a required configuration key is missing or blank, so the app
/// fails fast at startup with an actionable message instead of handing an
/// empty string to Firebase.
class EnvException implements Exception {
  const EnvException(this.message);
  final String message;
  @override
  String toString() => 'EnvException: $message';
}

/// Typed access to the values in `.env`.
///
/// Call [load] once, before anything reads a value. Keys live in `.env`
/// (untracked); `.env.example` documents the full set.
abstract final class Env {
  Env._();

  /// Loads `.env` into memory. Safe to call once at startup.
  static Future<void> load({String fileName = '.env'}) =>
      dotenv.load(fileName: fileName);

  /// Test seam — inject values without touching the filesystem.
  static void loadFromMap(Map<String, String> values) =>
      dotenv.testLoad(mergeWith: values);

  // ---- Shared ----
  static String get projectId => _required('FIREBASE_PROJECT_ID');
  static String get messagingSenderId => _required('FIREBASE_MESSAGING_SENDER_ID');
  static String? get storageBucket => _optional('FIREBASE_STORAGE_BUCKET');

  // ---- Android ----
  static String get androidApiKey => _required('FIREBASE_ANDROID_API_KEY');
  static String get androidAppId => _required('FIREBASE_ANDROID_APP_ID');

  // ---- iOS ----
  static String get iosApiKey => _required('FIREBASE_IOS_API_KEY');
  static String get iosAppId => _required('FIREBASE_IOS_APP_ID');
  static String? get iosBundleId => _optional('FIREBASE_IOS_BUNDLE_ID');

  // ---- Web ----
  static String get webApiKey => _required('FIREBASE_WEB_API_KEY');
  static String get webAppId => _required('FIREBASE_WEB_APP_ID');
  static String? get webAuthDomain => _optional('FIREBASE_WEB_AUTH_DOMAIN');
  static String? get webMeasurementId => _optional('FIREBASE_WEB_MEASUREMENT_ID');

  // ---- Google Sign-In ----
  // Optional so a missing value never blocks app startup or sign-out; the
  // Google sign-in path validates what it needs and reports it clearly.

  /// The "Web application" OAuth client ID. Used on Web as the client ID, and
  /// on Android as the `serverClientId` that mints the idToken Firebase needs.
  static String? get googleWebClientId => _optional('GOOGLE_WEB_CLIENT_ID');

  /// The "iOS" OAuth client ID (iOS/macOS only).
  static String? get googleIosClientId => _optional('GOOGLE_IOS_CLIENT_ID');

  // ---- Cloudinary (file storage) ----
  // Optional so a missing value never blocks startup; the storage service
  // reports clearly when it's asked to upload without being configured.
  static String? get cloudinaryCloudName => _optional('CLOUDINARY_CLOUD_NAME');
  static String? get cloudinaryUploadPreset =>
      _optional('CLOUDINARY_UPLOAD_PRESET');

  static String _required(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.trim().isEmpty) {
      throw EnvException(
        'Missing "$key" in .env. Copy .env.example to .env and fill in the '
        'values from your Firebase project (Project settings → Your apps).',
      );
    }
    return value.trim();
  }

  static String? _optional(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
