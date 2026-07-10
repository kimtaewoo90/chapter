import '../utils/entry_diary_ai.dart';
import '../utils/entry_photos.dart';
import '../../models/book_entry_snapshot.dart';
import '../../models/daily_entry.dart';
import 'book_layout_types.dart';

/// PDF 생성기와 동일한 DiaryEntry 형태로 변환 (미리보기·레이아웃용)
class BookPreviewEntryMapper {
  BookPreviewEntryMapper._();

  static BookDiaryEntry fromDailyEntry(DailyEntry entry) {
    final body = EntryDiaryAi.primaryDiaryText(entry)?.trim() ?? '';
    final photoUris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );

    return BookDiaryEntry(
      date: entry.dateKey,
      title: '',
      body: body,
      photoUris: photoUris,
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );
  }

  /// 기록 화면 초안 — 저장 전 실시간 책 페이지 미리보기용
  static BookDiaryEntry fromDraft({
    required DateTime date,
    String? note,
    List<String> photoUris = const [],
    String? moodEmoji,
    String? moodLabel,
  }) {
    return BookDiaryEntry(
      date: DailyEntry.dateKeyFrom(date),
      title: '',
      body: note?.trim() ?? '',
      photoUris: photoUris,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
    );
  }

  /// PDF 헤더용 — `☕ 여유` / 이모지만 / 라벨만
  static String? formatMoodDisplay({
    String? moodEmoji,
    String? moodLabel,
  }) {
    final emoji = moodEmoji?.trim();
    final label = moodLabel?.trim();
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    final hasLabel = label != null && label.isNotEmpty;
    if (hasEmoji && hasLabel) return '$emoji $label';
    if (hasEmoji) return emoji;
    if (hasLabel) return label;
    return null;
  }

  /// `2026-03-15` → `3월 15일` (PDF 헤더용)
  static String formatDateLabel(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length == 3) {
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (month != null && day != null) {
        return '$month월 $day일';
      }
    }
    return dateKey;
  }

  static List<BookDiaryEntry> fromDailyEntries(List<DailyEntry> entries) {
    return entries.map(fromDailyEntry).toList();
  }

  static BookDiaryEntry fromSnapshot(BookEntrySnapshot snapshot) {
    return BookDiaryEntry(
      date: snapshot.date,
      title: '',
      body: snapshot.body,
      photoUris: snapshot.photoUrls,
      moodEmoji: snapshot.moodEmoji,
      moodLabel: snapshot.moodLabel,
    );
  }

  static List<BookDiaryEntry> fromSnapshots(List<BookEntrySnapshot> snapshots) {
    final sorted = List<BookEntrySnapshot>.from(snapshots)..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map(fromSnapshot).toList();
  }
}
