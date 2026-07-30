import 'package:equatable/equatable.dart';

import '../services/file_storage.dart';

/// A file the patient has uploaded — an image or PDF held in remote storage
/// and referenced from a Firestore document.
///
/// Shared by medical records and insurance cards so both persist the same
/// shape and render through the same widgets.
class StoredAttachment extends Equatable {
  const StoredAttachment({
    required this.url,
    required this.name,
    required this.kind,
    this.bytes = 0,
  });

  final String url;
  final String name;

  /// 'image', 'pdf', or 'raw'.
  final String kind;

  /// Size in bytes; 0 when unknown (documents saved before this was recorded).
  final int bytes;

  bool get isImage => kind == 'image';
  bool get isPdf => kind == 'pdf';

  /// e.g. "1.2 MB", or null when the size was not recorded.
  String? get sizeLabel {
    if (bytes <= 0) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory StoredAttachment.fromStoredFile(StoredFile file, String name) =>
      StoredAttachment(
        url: file.url,
        name: name,
        kind: file.kind,
        bytes: file.bytes,
      );

  Map<String, dynamic> toMap() => {
        'url': url,
        'name': name,
        'kind': kind,
        if (bytes > 0) 'bytes': bytes,
      };

  factory StoredAttachment.fromMap(Map<String, dynamic> map) =>
      StoredAttachment(
        url: map['url'] as String? ?? '',
        name: map['name'] as String? ?? 'Attachment',
        kind: map['kind'] as String? ?? 'raw',
        bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [url, name, kind, bytes];
}
