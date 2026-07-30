import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/config/env.dart';
import 'package:medi_carry/core/services/cloudinary_storage.dart';
import 'package:medi_carry/core/services/file_storage.dart';

void main() {
  group('CloudinaryStorage when unconfigured', () {
    setUp(() => Env.loadFromMap({})); // no Cloudinary creds

    test('reports it is not configured', () {
      expect(CloudinaryStorage().isConfigured, isFalse);
    });

    test('upload throws an actionable FileStorageException', () async {
      await expectLater(
        CloudinaryStorage().upload('/tmp/x.jpg', folder: 'records', kind: 'image'),
        throwsA(
          isA<FileStorageException>().having(
            (e) => e.message,
            'message',
            contains('CLOUDINARY_CLOUD_NAME'),
          ),
        ),
      );
    });
  });

  test('is configured once creds are present', () {
    Env.loadFromMap({
      'CLOUDINARY_CLOUD_NAME': 'demo',
      'CLOUDINARY_UPLOAD_PRESET': 'unsigned_preset',
    });
    expect(CloudinaryStorage().isConfigured, isTrue);
  });
}
