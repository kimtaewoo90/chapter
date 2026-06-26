import '../../models/chapter_model.dart';
import '../../models/daily_entry.dart';
import 'entry_photos.dart';

/// 챕터 커버·대표 사진 — 저장된 경로가 깨졌을 때 일기 원본에서 다시 찾음
class ChapterCover {
  ChapterCover._();

  static List<DailyEntry> entriesInChapter(ChapterModel chapter, List<DailyEntry> all) {
    final start = DateTime(chapter.startDate.year, chapter.startDate.month, chapter.startDate.day);
    final end = DateTime(chapter.endDate.year, chapter.endDate.month, chapter.endDate.day);
    return all.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  /// 커버 1장 — 사진 많은 날 우선, 없으면 최근 사진
  static String? coverUri({
    required ChapterModel chapter,
    required List<DailyEntry> allEntries,
  }) {
    final inChapter = entriesInChapter(chapter, allEntries);
    final withPhotos = inChapter.where((e) => e.hasPhotos).toList()
      ..sort((a, b) => b.photoCount.compareTo(a.photoCount));

    for (final entry in withPhotos) {
      final uris = EntryPhotos.displayUris(
        localPaths: entry.localPhotoPaths,
        remoteUrls: entry.remotePhotoUrls,
      );
      if (uris.isNotEmpty) return uris.first;
    }

    return _resolveStored(chapter.coverPhotoUrl);
  }

  /// 대표 순간 썸네일 (최대 [limit]장)
  static List<String> momentUris({
    required ChapterModel chapter,
    required List<DailyEntry> allEntries,
    int limit = 8,
  }) {
    final uris = <String>[];
    for (final entry in entriesInChapter(chapter, allEntries)) {
      if (!entry.hasPhotos) continue;
      uris.addAll(
        EntryPhotos.displayUris(
          localPaths: entry.localPhotoPaths,
          remoteUrls: entry.remotePhotoUrls,
        ),
      );
      if (uris.length >= limit) break;
    }
    return uris.take(limit).toList();
  }

  /// 챕터 동기화 시 저장할 커버 URI
  static String? pickCoverForSync(List<DailyEntry> recent) {
    final withPhotos = recent.where((e) => e.hasPhotos).toList()
      ..sort((a, b) => b.photoCount.compareTo(a.photoCount));

    for (final entry in withPhotos) {
      final uris = EntryPhotos.displayUris(
        localPaths: entry.localPhotoPaths,
        remoteUrls: entry.remotePhotoUrls,
      );
      if (uris.isNotEmpty) return uris.first;
    }
    return null;
  }

  static String? _resolveStored(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith('http')) return stored;

    final uris = EntryPhotos.displayUris(
      localPaths: [stored],
      remoteUrls: const [],
    );
    return uris.isEmpty ? null : uris.first;
  }
}
