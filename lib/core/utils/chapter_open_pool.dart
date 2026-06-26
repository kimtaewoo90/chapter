import '../../models/chapter_model.dart';
import '../../models/daily_entry.dart';

/// 아직 어떤 완성 챕터에도 속하지 않은 기록
class ChapterOpenPool {
  ChapterOpenPool._();

  static List<DailyEntry> unchaptered(List<DailyEntry> all, List<ChapterModel> completed) {
    final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
    if (completed.isEmpty) return sorted;

    var latestEnd = completed.first.endDate;
    for (final c in completed.skip(1)) {
      if (c.endDate.isAfter(latestEnd)) latestEnd = c.endDate;
    }
    final cutoff = DateTime(latestEnd.year, latestEnd.month, latestEnd.day);

    return sorted.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.isAfter(cutoff);
    }).toList();
  }
}

/// 챕터 봉인 판단 결과
class ChapterSealDecision {
  const ChapterSealDecision({
    required this.shouldSeal,
    required this.sealedEntries,
    required this.remainingEntries,
    this.title,
    this.summary,
  });

  final bool shouldSeal;
  final List<DailyEntry> sealedEntries;
  final List<DailyEntry> remainingEntries;
  final String? title;
  final String? summary;

  static const continueWriting = ChapterSealDecision(
    shouldSeal: false,
    sealedEntries: [],
    remainingEntries: [],
  );
}
