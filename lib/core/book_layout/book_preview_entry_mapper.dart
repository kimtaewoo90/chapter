import '../utils/entry_diary_ai.dart';
import '../utils/entry_photos.dart';
import '../../models/book_entry_snapshot.dart';
import '../../models/daily_entry.dart';
import 'book_layout_types.dart';

/// PDF 생성기와 동일한 DiaryEntry 형태로 변환 (미리보기·레이아웃용)
class BookPreviewEntryMapper {
  BookPreviewEntryMapper._();

  static BookDiaryEntry fromDailyEntry(DailyEntry entry) {
    final dateFmt = '${entry.date.month}월 ${entry.date.day}일';
    final moodPart = entry.moodLabel?.trim().isNotEmpty == true
        ? entry.moodLabel!.trim()
        : (entry.moodEmoji ?? '');
    final titleSuffix = moodPart.isNotEmpty ? ' - $moodPart' : '';
    final body = EntryDiaryAi.primaryDiaryText(entry)?.trim() ?? '';
    final photoUris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );

    return BookDiaryEntry(
      date: entry.dateKey,
      title: '$dateFmt$titleSuffix',
      body: body,
      photoUris: photoUris,
    );
  }

  static List<BookDiaryEntry> fromDailyEntries(List<DailyEntry> entries) {
    return entries.map(fromDailyEntry).toList();
  }

  static BookDiaryEntry fromSnapshot(BookEntrySnapshot snapshot) {
    return BookDiaryEntry(
      date: snapshot.date,
      title: snapshot.title,
      body: snapshot.body,
      photoUris: snapshot.photoUrls,
    );
  }

  static List<BookDiaryEntry> fromSnapshots(List<BookEntrySnapshot> snapshots) {
    final sorted = List<BookEntrySnapshot>.from(snapshots)..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map(fromSnapshot).toList();
  }
}
