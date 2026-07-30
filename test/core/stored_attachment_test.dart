import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/models/stored_attachment.dart';
import 'package:medi_carry/core/services/file_storage.dart';

void main() {
  group('kindForExtension', () {
    test('classifies the formats the pickers accept', () {
      expect(FileStorage.kindForExtension('jpg'), 'image');
      expect(FileStorage.kindForExtension('JPEG'), 'image');
      expect(FileStorage.kindForExtension('.png'), 'image');
      expect(FileStorage.kindForExtension('heic'), 'image');
      expect(FileStorage.kindForExtension('pdf'), 'pdf');
      expect(FileStorage.kindForExtension('docx'), 'raw');
      expect(FileStorage.kindForExtension(null), 'raw');
    });
  });

  group('sizeLabel', () {
    test('scales the unit to the size', () {
      expect(const StoredAttachment(url: '', name: '', kind: 'raw', bytes: 512)
          .sizeLabel, '512 B');
      expect(const StoredAttachment(url: '', name: '', kind: 'raw', bytes: 2048)
          .sizeLabel, '2 KB');
      expect(
        const StoredAttachment(url: '', name: '', kind: 'raw', bytes: 1572864)
            .sizeLabel,
        '1.5 MB',
      );
    });

    test('is null when the size was never recorded', () {
      expect(
        const StoredAttachment(url: '', name: '', kind: 'raw').sizeLabel,
        isNull,
      );
    });
  });

  test('omits a zero size from the stored map', () {
    const attachment =
        StoredAttachment(url: 'https://cdn/x.pdf', name: 'x.pdf', kind: 'pdf');
    expect(attachment.toMap().containsKey('bytes'), isFalse);
  });

  test('round-trips through toMap/fromMap', () {
    const attachment = StoredAttachment(
      url: 'https://cdn/x.jpg',
      name: 'x.jpg',
      kind: 'image',
      bytes: 1024,
    );
    final restored = StoredAttachment.fromMap(attachment.toMap());
    expect(restored, attachment);
    expect(restored.isImage, isTrue);
    expect(restored.isPdf, isFalse);
  });

  test('builds from a StoredFile returned by the upload service', () {
    const file = StoredFile(
      url: 'https://cdn/scan.pdf',
      publicId: 'cards/scan',
      kind: 'pdf',
      bytes: 4096,
    );
    final attachment = StoredAttachment.fromStoredFile(file, 'scan.pdf');
    expect(attachment.url, 'https://cdn/scan.pdf');
    expect(attachment.name, 'scan.pdf');
    expect(attachment.isPdf, isTrue);
    expect(attachment.bytes, 4096);
  });
}
