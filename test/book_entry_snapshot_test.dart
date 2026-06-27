import 'package:chapter/models/book_entry_snapshot.dart';
import 'package:chapter/core/book_layout/book_preview_entry_mapper.dart';
import 'package:chapter/models/daily_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshotPhotoUrls — 로컬 경로만 있으면 제외 (remote 없음)', () {
    final entry = DailyEntry(
      id: '1',
      userId: 'u',
      date: DateTime(2026, 3, 15),
      localPhotoPaths: const ['/tmp/photo.jpg'],
      remotePhotoUrls: const [],
    );

    expect(BookEntrySnapshot.snapshotPhotoUrls(entry), isEmpty);
  });

  test('snapshotPhotoUrls — 로컬+remote 동시 있으면 remote URL 사용', () {
    final entry = DailyEntry(
      id: '1',
      userId: 'u',
      date: DateTime(2026, 3, 15),
      localPhotoPaths: const ['/tmp/photo.jpg'],
      remotePhotoUrls: const ['https://storage.example/photo.jpg'],
    );

    expect(
      BookEntrySnapshot.snapshotPhotoUrls(entry),
      ['https://storage.example/photo.jpg'],
    );
  });

  test('snapshotPhotoUrls — remote만 있으면 그대로 (클라우드 복원)', () {
    final entry = DailyEntry(
      id: '1',
      userId: 'u',
      date: DateTime(2026, 3, 15),
      remotePhotoUrls: const [
        'https://storage.example/a.jpg',
        'https://storage.example/b.jpg',
      ],
    );

    expect(
      BookEntrySnapshot.snapshotPhotoUrls(entry),
      hasLength(2),
    );
  });

  test('fromEntry — 방금 저장한 일기도 photoUrls에 remote 포함', () {
    final snapshot = BookEntrySnapshot.fromEntry(
      DailyEntry(
        id: '1',
        userId: 'u',
        date: DateTime(2026, 3, 15),
        localPhotoPaths: const ['/var/mobile/photo.jpg'],
        remotePhotoUrls: const ['https://firebasestorage.googleapis.com/x.jpg'],
        moodEmoji: '☕',
      ),
    );

    expect(snapshot.photoUrls, ['https://firebasestorage.googleapis.com/x.jpg']);
    expect(snapshot.moodEmoji, '☕');
  });

  test('formatMoodDisplay — 이모지와 라벨', () {
    expect(
      BookPreviewEntryMapper.formatMoodDisplay(
        moodEmoji: '☕',
        moodLabel: '여유',
      ),
      '☕ 여유',
    );
    expect(
      BookPreviewEntryMapper.formatMoodDisplay(moodEmoji: '☕'),
      '☕',
    );
    expect(
      BookPreviewEntryMapper.formatMoodDisplay(moodLabel: '여유'),
      '여유',
    );
    expect(BookPreviewEntryMapper.formatMoodDisplay(), isNull);
  });
}
