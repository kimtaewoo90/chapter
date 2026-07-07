import 'package:chapter/core/utils/entry_photos.dart';
import 'package:chapter/models/daily_entry.dart';
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

    test('empty entry returns mutable empty slots', () {
      final slots = EntryPhotos.editSlots(
        localPaths: const [],
        remoteUrls: const [],
      );

      expect(slots.localPaths, isEmpty);
      expect(slots.remoteUrls, isEmpty);
      expect(() => slots.localPaths.add('x'), returnsNormally);
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

  group('EntryPhotos.compactPhotoSlots', () {
    test('빈 로컬 슬롯 제거 시 remote 인덱스 유지', () {
      final compacted = EntryPhotos.compactPhotoSlots(
        localPaths: const ['https://a.jpg', '', '/local/new.jpg'],
        remoteUrls: const ['https://a.jpg', 'https://stale.jpg', ''],
      );

      expect(compacted.locals, ['https://a.jpg', '/local/new.jpg']);
      expect(compacted.remotes, ['https://a.jpg', '']);
    });

    test('remote-only entry survives editSlots then compact', () {
      final slots = EntryPhotos.editSlots(
        localPaths: const [],
        remoteUrls: const ['https://a.jpg', 'https://b.jpg'],
      );
      final compacted = EntryPhotos.compactPhotoSlots(
        localPaths: slots.localPaths,
        remoteUrls: slots.remoteUrls,
      );

      expect(compacted.locals, ['https://a.jpg', 'https://b.jpg']);
      expect(compacted.remotes, ['https://a.jpg', 'https://b.jpg']);
    });
  });

  group('DailyEntry remote photo parsing', () {
    test('빈 remote 슬롯을 유지해 local 인덱스와 맞춘다', () {
      final entry = DailyEntry.fromJson({
        'id': '1',
        'userId': 'u',
        'date': '2026-03-15T00:00:00.000',
        'localPhotoPaths': ['/a.jpg', '/b.jpg'],
        'remotePhotoUrls': ['https://a.jpg', ''],
      });

      expect(entry.remotePhotoUrls, ['https://a.jpg', '']);
    });
  });
}
