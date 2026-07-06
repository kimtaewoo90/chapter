import 'package:chapter/core/utils/monthly_review_digest_builder.dart';
import 'package:chapter/models/daily_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyReviewDigestBuilder', () {
    test('aggregates moods, places, people, words from entries', () {
      final entries = [
        DailyEntry(
          id: '1',
          userId: 'u',
          date: DateTime(2026, 6, 3),
          moodEmoji: '😴',
          moodLabel: '육아텅',
          note: '엄마랑 카페에서 커피 마셨어',
          location: '서울특별시 강남구 역삼동',
        ),
        DailyEntry(
          id: '2',
          userId: 'u',
          date: DateTime(2026, 6, 8),
          moodEmoji: '😴',
          moodLabel: '육아텅',
          note: '엄마 도와줘서 고마웠어',
          location: '서울특별시 강남구 역삼동',
          emotion: 'positive',
        ),
        DailyEntry(
          id: '3',
          userId: 'u',
          date: DateTime(2026, 6, 12),
          moodEmoji: '☕',
          moodLabel: '카페집중',
          note: '카페에서 공부',
          location: '서울특별시 마포구 연남동',
        ),
      ];

      final digest = MonthlyReviewDigestBuilder.build(
        entries,
        periodLabel: '2026년 6월',
      );

      expect(digest.recordedDays, 3);
      expect(digest.moods.first.label, contains('육아텅'));
      expect(digest.moods.first.count, 2);
      expect(digest.people.any((p) => p.label == '엄마'), isTrue);
      expect(digest.places, isNotEmpty);
      expect(digest.factSummary, contains('2026년 6월'));
    });

    test('builds summary from top facts', () {
      final entries = List.generate(
        3,
        (i) => DailyEntry(
          id: '$i',
          userId: 'u',
          date: DateTime(2026, 5, i + 1),
          moodEmoji: '🌿',
          moodLabel: '평온',
          note: '친구랑 산책',
        ),
      );

      final digest = MonthlyReviewDigestBuilder.build(
        entries,
        periodLabel: '2026년 5월',
      );

      expect(digest.factSummary, isNotEmpty);
      expect(digest.moods.first.count, 3);
    });
  });
}
