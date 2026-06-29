import 'package:intl/intl.dart';

import '../../models/daily_entry.dart';

/// 캘린더 월 기준 월간 리포트 기간
class MonthlyReviewPeriod {
  MonthlyReviewPeriod._();

  static const minEntriesToGenerate = 3;

  static String periodKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  static String periodKeyFromDate(DateTime date) =>
      periodKey(date.year, date.month);

  static String periodLabel(int year, int month) =>
      DateFormat('yyyy년 M월', 'ko_KR').format(DateTime(year, month, 1));

  static String periodLabelFromDate(DateTime date) =>
      periodLabel(date.year, date.month);

  static DateTime monthStart(int year, int month) =>
      DateTime(year, month, 1);

  static DateTime lastDayOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0);

  static bool isLastDayOfMonth(DateTime date) {
    final last = lastDayOfMonth(date.year, date.month);
    return date.year == last.year &&
        date.month == last.month &&
        date.day == last.day;
  }

  /// 말일 당일 또는 그 이후에만 해당 월 리포트 생성 가능
  static bool isEligibleForGeneration({
    required int year,
    required int month,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final last = lastDayOfMonth(year, month);
    return !day.isBefore(last);
  }

  static List<DailyEntry> entriesInMonth(
    List<DailyEntry> all, {
    required int year,
    required int month,
  }) {
    return all
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 첫 기록 월 ~ 오늘 달까지 (월 시작일 목록)
  static List<DateTime> monthsSpanningEntries(
    List<DailyEntry> entries,
    DateTime today,
  ) {
    if (entries.isEmpty) return [];

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    var cursor = monthStart(sorted.first.date.year, sorted.first.date.month);
    final end = monthStart(today.year, today.month);
    final months = <DateTime>[];

    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  static int daysUntilMonthEnd(DateTime today) {
    final last = lastDayOfMonth(today.year, today.month);
    final day = DateTime(today.year, today.month, today.day);
    return last.difference(day).inDays;
  }
}
