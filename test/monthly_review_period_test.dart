import 'package:chapter/core/utils/monthly_review_period.dart';
import 'package:chapter/models/daily_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyReviewPeriod', () {
    test('periodKey formats yyyy-MM', () {
      expect(MonthlyReviewPeriod.periodKey(2026, 6), '2026-06');
      expect(MonthlyReviewPeriod.periodKey(2026, 12), '2026-12');
    });

    test('isEligibleForGeneration on last day', () {
      expect(
        MonthlyReviewPeriod.isEligibleForGeneration(
          year: 2026,
          month: 6,
          today: DateTime(2026, 6, 30),
        ),
        isTrue,
      );
      expect(
        MonthlyReviewPeriod.isEligibleForGeneration(
          year: 2026,
          month: 6,
          today: DateTime(2026, 6, 15),
        ),
        isFalse,
      );
    });

    test('entriesInMonth filters by calendar month', () {
      final entries = [
        DailyEntry(id: '1', userId: 'u', date: DateTime(2026, 6, 1)),
        DailyEntry(id: '2', userId: 'u', date: DateTime(2026, 6, 15)),
        DailyEntry(id: '3', userId: 'u', date: DateTime(2026, 7, 1)),
      ];
      final june = MonthlyReviewPeriod.entriesInMonth(
        entries,
        year: 2026,
        month: 6,
      );
      expect(june.length, 2);
    });

    test('daysUntilMonthEnd', () {
      expect(
        MonthlyReviewPeriod.daysUntilMonthEnd(DateTime(2026, 6, 30)),
        0,
      );
      expect(
        MonthlyReviewPeriod.daysUntilMonthEnd(DateTime(2026, 6, 28)),
        2,
      );
    });
  });
}
