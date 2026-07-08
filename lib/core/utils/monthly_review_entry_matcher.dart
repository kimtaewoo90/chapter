import '../../models/daily_entry.dart';
import '../../models/monthly_review_digest.dart';
import 'monthly_review_digest_builder.dart';

/// 월간 팩트 항목 ↔ 일기 매칭
class MonthlyReviewEntryMatcher {
  MonthlyReviewEntryMatcher._();

  static List<DailyEntry> entriesForMood(
    List<DailyEntry> monthEntries,
    MonthlyFactItem item,
  ) {
    final byId = _byStoredIds(monthEntries, item);
    if (byId.isNotEmpty) return byId;

    return monthEntries.where((e) => _moodLabel(e) == item.label).toList();
  }

  static List<DailyEntry> entriesForWord(
    List<DailyEntry> monthEntries,
    MonthlyFactItem item,
  ) {
    final byId = _byStoredIds(monthEntries, item);
    if (byId.isNotEmpty) return byId;

    final word = item.label.toLowerCase();
    return monthEntries.where((e) {
      final text = MonthlyReviewDigestBuilder.entryText(e).toLowerCase();
      if (text.isEmpty) return false;
      return text.split(RegExp(r'\s+')).contains(word);
    }).toList();
  }

  static List<DailyEntry> _byStoredIds(
    List<DailyEntry> monthEntries,
    MonthlyFactItem item,
  ) {
    if (item.entryIds.isEmpty) return [];
    final ids = item.entryIds.toSet();
    return monthEntries.where((e) => ids.contains(e.id)).toList();
  }

  static String _moodLabel(DailyEntry entry) {
    return [
      if (entry.moodEmoji != null && entry.moodEmoji!.isNotEmpty) entry.moodEmoji,
      if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty) entry.moodLabel,
    ].join(' ');
  }
}
