import 'dart:typed_data';

/// A file uploaded to remote storage.
class StoredFile {
  const StoredFile({
    required this.url,
    required this.publicId,
    required this.kind,
    this.bytes = 0,
  });

  /// The delivery URL to open/display.
  final String url;

  /// The provider's identifier (Cloudinary public_id), kept so the file can be
  /// deleted or transformed later.
  final String publicId;

  /// 'image', 'pdf', or 'raw'.
  final String kind;

  /// Size of the stored file in bytes (0 when the provider doesn't report it).
  final int bytes;
}

/// Raised for upload failures, with a message safe to show to the user.
class FileStorageException implements Exception {
  const FileStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class FileStorage {
  /// The largest file the app accepts. Insurance cards and lab scans are
  /// photos or short PDFs; anything larger is almost always a mistake, and
  /// uploading it over a mobile connection in East Africa would be punishing.
  static const maxBytes = 10 * 1024 * 1024;

  /// Human label for [maxBytes], used in error messages.
  static const maxBytesLabel = '10 MB';

  bool get isConfigured;

  /// Uploads the file at [path] and returns its stored location.
  /// [folder] groups files (e.g. "records", "cards", "avatars"); [kind] is
  /// 'image', 'pdf' or 'raw'.
  Future<StoredFile> upload(
    String path, {
    required String folder,
    required String kind,
  });

  /// Uploads in-memory [data]. Used on the web, where picked files have no
  /// filesystem path, and for documents the app generates itself (PDF export).
  Future<StoredFile> uploadBytes(
    Uint8List data, {
    required String fileName,
    required String folder,
    required String kind,
  });

  /// Classifies a file extension into the `kind` the rest of the app stores.
  static String kindForExtension(String? extension) {
    final ext = (extension ?? '').toLowerCase().replaceFirst('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'].contains(ext)) {
      return 'image';
    }
    if (ext == 'pdf') return 'pdf';
    return 'raw';
  }
}
