import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'file_storage.dart';

/// Where a document came from. Offered as a choice because in a clinic the
/// patient usually photographs the paper in front of them, while an insurance
/// card or discharge summary more often already exists as a PDF on the phone.
enum AttachmentSource { camera, gallery, files }

/// A file chosen by the patient, before it is uploaded.
///
/// Carries either a filesystem [path] (mobile/desktop) or in-memory [bytes]
/// (web), because `file_picker` and `image_picker` return different things per
/// platform.
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.kind,
    this.path,
    this.bytes,
  });

  final String name;

  /// 'image', 'pdf' or 'raw'.
  final String kind;

  final String? path;
  final Uint8List? bytes;

  bool get isEmpty => path == null && bytes == null;
}

/// Picks documents and uploads them to [FileStorage].
///
/// Shared by Add Record and My Cards so both features behave identically:
/// same accepted formats, same size limit, same failure messages.
class AttachmentPicker {
  const AttachmentPicker({
    required FileStorage storage,
    ImagePicker? imagePicker,
  })  : _storage = storage,
        _imagePicker = imagePicker;

  final FileStorage _storage;
  final ImagePicker? _imagePicker;

  ImagePicker get _picker => _imagePicker ?? ImagePicker();

  static const allowedExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf', //
  ];

  /// Prompts for files from [source]. Returns an empty list if the patient
  /// backs out.
  Future<List<PickedDocument>> pick(
    AttachmentSource source, {
    bool allowMultiple = true,
  }) async {
    switch (source) {
      case AttachmentSource.camera:
      case AttachmentSource.gallery:
        final picked = await _picker.pickImage(
          source: source == AttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          // Downscaled on the device: a 12MP clinic photo is unreadable extra
          // megabytes over a mobile connection, and 2000px still resolves
          // printed lab values.
          maxWidth: 2000,
          imageQuality: 85,
        );
        if (picked == null) return const [];
        return [
          PickedDocument(
            name: picked.name,
            kind: 'image',
            path: kIsWeb ? null : picked.path,
            bytes: kIsWeb ? await picked.readAsBytes() : null,
          ),
        ];

      case AttachmentSource.files:
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: allowMultiple,
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
          // Needed on web, where `path` is always null.
          withData: kIsWeb,
        );
        if (result == null) return const [];
        return [
          for (final file in result.files)
            PickedDocument(
              name: file.name,
              kind: FileStorage.kindForExtension(file.extension),
              path: file.path,
              bytes: file.bytes,
            ),
        ].where((d) => !d.isEmpty).toList();
    }
  }

  /// Uploads [document] into [folder], throwing [FileStorageException] with a
  /// message meant for the patient.
  Future<StoredFile> upload(
    PickedDocument document, {
    required String folder,
  }) {
    if (!_storage.isConfigured) {
      throw const FileStorageException(
        'File uploads are unavailable — storage is not configured.',
      );
    }
    final path = document.path;
    if (path != null) {
      return _storage.upload(path, folder: folder, kind: document.kind);
    }
    final bytes = document.bytes;
    if (bytes != null) {
      return _storage.uploadBytes(
        bytes,
        fileName: document.name,
        folder: folder,
        kind: document.kind,
      );
    }
    throw const FileStorageException('That file could not be read.');
  }
}
