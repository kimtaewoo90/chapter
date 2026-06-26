import '../core/utils/entry_diary_ai.dart';
import '../core/utils/entry_photos.dart';
import 'daily_entry.dart';

/// 주문 시점에 고정되는 일기 스냅샷 (PDF·인쇄용)
class BookEntrySnapshot {
  const BookEntrySnapshot({
    required this.date,
    required this.title,
    required this.body,
    this.photoUrls = const [],
    this.entryId,
    this.moodEmoji,
    this.moodLabel,
  });

  final String date;
  final String title;
  final String body;
  final List<String> photoUrls;
  final String? entryId;
  final String? moodEmoji;
  final String? moodLabel;

  factory BookEntrySnapshot.fromEntry(DailyEntry entry) {
    final dateFmt = _monthDayLabel(entry.date);
    final moodPart = entry.moodLabel?.trim().isNotEmpty == true
        ? entry.moodLabel!.trim()
        : (entry.moodEmoji ?? '');
    final titleSuffix = moodPart.isNotEmpty ? ' - $moodPart' : '';
    final body = EntryDiaryAi.primaryDiaryText(entry)?.trim() ?? '';

    final urls = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    ).where(_isPrintableUrl).toList();

    return BookEntrySnapshot(
      date: entry.dateKey,
      title: '$dateFmt$titleSuffix',
      body: body,
      photoUrls: urls,
      entryId: entry.id,
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );
  }

  static String _monthDayLabel(DateTime date) =>
      '${date.month}월 ${date.day}일';

  static bool _isPrintableUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  Map<String, dynamic> toFirestoreMap() => {
        'date': date,
        'title': title,
        'body': body,
        'photoUrls': photoUrls,
        if (entryId != null) 'entryId': entryId,
        if (moodEmoji != null) 'moodEmoji': moodEmoji,
        if (moodLabel != null) 'moodLabel': moodLabel,
      };

  factory BookEntrySnapshot.fromMap(Map<String, dynamic> map) {
    return BookEntrySnapshot(
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      photoUrls: (map['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      entryId: map['entryId'] as String?,
      moodEmoji: map['moodEmoji'] as String?,
      moodLabel: map['moodLabel'] as String?,
    );
  }
}
