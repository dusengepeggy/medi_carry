import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

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

  static CloudinaryResourceType _resourceType(String kind) =>
      kind == 'image' ? CloudinaryResourceType.Image : CloudinaryResourceType.Auto;

  @override
  Future<StoredFile> upload(
    String path, {
    required String folder,
    required String kind,
  }) async {
    // Configuration is checked before touching the filesystem, so an
    // unconfigured app reports the real problem rather than an I/O error.
    _assertConfigured();
    // Size is checked before the request so an oversized file fails instantly
    // instead of after a long upload on a slow connection.
    if (!kIsWeb) {
      _assertWithinLimit(await File(path).length());
    }
    return _send(
      CloudinaryFile.fromFile(
        path,
        folder: folder,
        resourceType: _resourceType(kind),
      ),
      kind: kind,
    );
  }

  @override
  Future<StoredFile> uploadBytes(
    Uint8List data, {
    required String fileName,
    required String folder,
    required String kind,
  }) {
    _assertConfigured();
    _assertWithinLimit(data.length);
    return _send(
      CloudinaryFile.fromBytesData(
        data,
        identifier: fileName,
        folder: folder,
        resourceType: _resourceType(kind),
      ),
      kind: kind,
    );
  }

  Future<StoredFile> _send(CloudinaryFile file, {required String kind}) async {
    final client = _client;
    if (client == null) _assertConfigured();
    try {
      final response = await client!.uploadFile(file);
      return StoredFile(
        url: response.secureUrl,
        publicId: response.publicId,
        kind: kind,
        bytes: file.fileSize,
      );
    } on CloudinaryException catch (e) {
      throw FileStorageException(e.message ?? 'Upload failed. Please try again.');
    } on SocketException {
      throw const FileStorageException(
        'No connection. The upload will need to be retried once you are back '
        'online.',
      );
    } catch (_) {
      throw const FileStorageException('Upload failed. Please try again.');
    }
  }

  void _assertConfigured() {
    if (_client != null) return;
    throw const FileStorageException(
      'File storage is not configured. Add CLOUDINARY_CLOUD_NAME and '
      'CLOUDINARY_UPLOAD_PRESET to .env.',
    );
  }

  static void _assertWithinLimit(int bytes) {
    if (bytes > FileStorage.maxBytes) {
      throw const FileStorageException(
        'That file is larger than ${FileStorage.maxBytesLabel}. Try a photo '
        'or a smaller PDF.',
      );
    }
  }
}
