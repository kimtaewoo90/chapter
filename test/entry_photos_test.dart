import 'package:chapter/core/utils/entry_photos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryPhotos.editSlots', () {
    test('remote-only entry uses URLs as local placeholders', () {
      const remotes = ['https://a.jpg', 'https://b.jpg'];
      final slots = EntryPhotos.editSlots(
        localPaths: const [],
        remoteUrls: remotes,
      );

      expect(slots.localPaths, remotes);
      expect(slots.remoteUrls, remotes);
    });

    test('dead local paths fall back to paired remote URL', () {
      final slots = EntryPhotos.editSlots(
        localPaths: const ['/dead/1.jpg', '/dead/2.jpg'],
        remoteUrls: const ['https://a.jpg', 'https://b.jpg'],
      );

      expect(slots.localPaths, ['https://a.jpg', 'https://b.jpg']);
      expect(slots.remoteUrls, ['https://a.jpg', 'https://b.jpg']);
    });

    test('empty entry returns empty slots', () {
      final slots = EntryPhotos.editSlots(
        localPaths: const [],
        remoteUrls: const [],
      );

      expect(slots.localPaths, isEmpty);
      expect(slots.remoteUrls, isEmpty);
    });
  });

  group('EntryPhotos.displayUris', () {
    test('falls back to remote when local is empty', () {
      final uris = EntryPhotos.displayUris(
        localPaths: const [],
        remoteUrls: const ['https://a.jpg'],
      );

      expect(uris, ['https://a.jpg']);
    });
  });
}
