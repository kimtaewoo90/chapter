import '../../models/chapter_model.dart';
import '../../models/daily_entry.dart';
import 'chapter_cover.dart';
import 'chapter_segmenter.dart';

/// 완성된 챕터 구간 → [ChapterModel] 변환
class ChapterBuilder {
  ChapterBuilder._();

  static String stableId(String uid, ChapterSegment segment) {
    return 'ch_${uid}_${segment.dateRangeKey}';
  }

  static ChapterModel fromSegment({
    required String uid,
    required ChapterSegment segment,
    required String title,
    required String narrative,
    String? preserveId,
    String? storyArcId,
    String? category,
  }) {
    final entries = segment.entries;
    final mood = entries.map((e) => e.moodEmoji).whereType<String>().fold<Map<String, int>>({}, (m, e) {
      m[e] = (m[e] ?? 0) + 1;
      return m;
    });
    final topMood = mood.entries.isEmpty ? null : mood.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return ChapterModel(
      id: preserveId ?? stableId(uid, segment),
      userId: uid,
      title: title,
      narrative: narrative,
      startDate: segment.startDate,
      endDate: segment.endDate,
      coverPhotoUrl: ChapterCover.pickCoverForSync(entries),
      representativeMood: topMood,
      entryCount: entries.length,
      photoCount: entries.fold<int>(0, (sum, e) => sum + e.photoCount),
      storyArcId: storyArcId,
      category: category,
    );
  }

  static ChapterModel? findByRange({
    required List<ChapterModel> chapters,
    required ChapterSegment segment,
  }) {
    final key = segment.dateRangeKey;
    for (final c in chapters) {
      final cKey = '${DailyEntry.dateKeyFrom(c.startDate)}_${DailyEntry.dateKeyFrom(c.endDate)}';
      if (cKey == key) return c;
    }
    return null;
  }
}
