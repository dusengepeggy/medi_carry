/// A file uploaded to remote storage.
class StoredFile {
  const StoredFile({
    required this.url,
    required this.publicId,
    required this.kind,
  });

  /// The delivery URL to open/display.
  final String url;

  /// The provider's identifier (Cloudinary public_id), kept so the file can be
  /// deleted or transformed later.
  final String publicId;

  /// 'image', 'pdf', or 'raw'.
  final String kind;
}

/// Raised for upload failures, with a message safe to show to the user.
class FileStorageException implements Exception {
  const FileStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class FileStorage {

  bool get isConfigured;

  /// Uploads the file at [path] and returns its stored location.
  /// [folder] groups files (e.g. "records", "avatars"); [kind] is 'image',
  /// 'pdf' or 'raw'.
  Future<StoredFile> upload(
    String path, {
    required String folder,
    required String kind,
  });
}
