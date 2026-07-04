import 'package:intl/intl.dart';

import '../../models/book_entry_snapshot.dart';
import '../../models/daily_entry.dart';

/// 표지 하단 날짜 — yyyy.MM - yyyy.MM
String bookCoverDateRangeLabel(List<DailyEntry> entries) {
  if (entries.isEmpty) return '';
  final sorted = List<DailyEntry>.from(entries)
    ..sort((a, b) => a.date.compareTo(b.date));
  return _formatMonthRange(sorted.first.date, sorted.last.date);
}

/// 주문 스냅샷 기준 표지 기간
String bookCoverDateRangeFromSnapshots(List<BookEntrySnapshot> snapshots) {
  if (snapshots.isEmpty) return '';
  final dates = snapshots
      .map((s) => DateTime.tryParse(s.date))
      .whereType<DateTime>()
      .toList()
    ..sort();
  if (dates.isEmpty) return '';
  return _formatMonthRange(dates.first, dates.last);
}

String _formatMonthRange(DateTime first, DateTime last) {
  final fmt = DateFormat('yyyy.MM');
  final a = fmt.format(first);
  final b = fmt.format(last);
  if (a == b) return a;
  return '$a - $b';
}
