import 'package:chapter/core/utils/monthly_review_source_hash.dart';
import 'package:chapter/models/daily_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyReviewSourceHash', () {
    test('same entries produce same hash', () {
      final entries = [
        DailyEntry(
          id: '1',
          userId: 'u',
          date: DateTime(2026, 6, 1),
          note: '카페',
          moodLabel: '평온',
        ),
      ];
      expect(
        MonthlyReviewSourceHash.compute(entries),
        MonthlyReviewSourceHash.compute(entries),
      );
    });

    test('note change produces different hash', () {
      final a = [
        DailyEntry(id: '1', userId: 'u', date: DateTime(2026, 6, 1), note: '카페'),
      ];
      final b = [
        DailyEntry(id: '1', userId: 'u', date: DateTime(2026, 6, 1), note: '집'),
      ];
      expect(
        MonthlyReviewSourceHash.compute(a),
        isNot(MonthlyReviewSourceHash.compute(b)),
      );
    });
  });
}
