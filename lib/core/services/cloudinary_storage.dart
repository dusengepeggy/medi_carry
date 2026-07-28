import 'package:cloudinary_public/cloudinary_public.dart';

import '../config/env.dart';
import 'file_storage.dart';


class CloudinaryStorage implements FileStorage {
  CloudinaryStorage({CloudinaryPublic? client}) : _override = client;

  final CloudinaryPublic? _override;

  /// Built lazily so a missing config never crashes app startup — only an
  /// actual upload attempt surfaces the problem.
  CloudinaryPublic? get _client {
    if (_override != null) return _override;
    final cloud = Env.cloudinaryCloudName;
    final preset = Env.cloudinaryUploadPreset;
    if (cloud == null || preset == null) return null;
    return CloudinaryPublic(cloud, preset, cache: false);
  }

  @override
  bool get isConfigured => _client != null;

  @override
  Future<StoredFile> upload(
    String path, {
    required String folder,
    required String kind,
  }) async {
    final client = _client;
    if (client == null) {
      throw const FileStorageException(
        'File storage is not configured. Add CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET to .env.',
      );
    }
    try {
      final response = await client.uploadFile(
        CloudinaryFile.fromFile(
          path,
          folder: folder,
          // Images upload as Image; PDFs/others as Auto so Cloudinary picks
          // the right resource type.
          resourceType: kind == 'image'
              ? CloudinaryResourceType.Image
              : CloudinaryResourceType.Auto,
        ),
      );
      return StoredFile(
        url: response.secureUrl,
        publicId: response.publicId,
        kind: kind,
      );
    } on CloudinaryException catch (e) {
      throw FileStorageException(e.message ?? 'Upload failed. Please try again.');
    } catch (_) {
      throw const FileStorageException('Upload failed. Please try again.');
    }
  }
}
