import 'package:chapter/core/utils/entry_diary_ai.dart';
import 'package:chapter/models/daily_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryDiaryAi.shouldGenerateAiDiary', () {
    test('photos only', () {
      expect(
        EntryDiaryAi.shouldGenerateAiDiary(note: null, hasPhotos: true),
        isTrue,
      );
    });

    test('any note skips AI even with photos', () {
      expect(
        EntryDiaryAi.shouldGenerateAiDiary(note: '피곤', hasPhotos: true),
        isFalse,
      );
      expect(
        EntryDiaryAi.shouldGenerateAiDiary(
          note: '오늘은 카페에서 오래 앉아 책을 읽었다.',
          hasPhotos: true,
        ),
        isFalse,
      );
    });

    test('no photos skips AI', () {
      expect(
        EntryDiaryAi.shouldGenerateAiDiary(note: null, hasPhotos: false),
        isFalse,
      );
    });
  });

  group('EntryDiaryAi.display', () {
    test('user note only when text exists', () {
      final entry = DailyEntry(
        id: '1',
        userId: 'u',
        date: DateTime(2026, 3, 1),
        note: '비 오는 오후',
        aiLine: '창가 커피 향이 스며들던 오후.',
        localPhotoPaths: ['/tmp/a.jpg'],
      );
      expect(EntryDiaryAi.shouldShowAiLine(entry), isFalse);
      expect(EntryDiaryAi.primaryDiaryText(entry), '비 오는 오후');
    });

    test('photo only shows ai line', () {
      final entry = DailyEntry(
        id: '1',
        userId: 'u',
        date: DateTime(2026, 3, 1),
        aiLine: '창가 커피 향이 스며들던 오후.',
        localPhotoPaths: ['/tmp/a.jpg'],
      );
      expect(EntryDiaryAi.shouldShowAiLine(entry), isTrue);
      expect(EntryDiaryAi.primaryDiaryText(entry), entry.aiLine);
    });
  });
}
