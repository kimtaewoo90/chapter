import '../core/utils/entry_diary_ai.dart';
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
    final body = EntryDiaryAi.primaryDiaryText(entry)?.trim() ?? '';

    return BookEntrySnapshot(
      date: entry.dateKey,
      title: '',
      body: body,
      photoUrls: snapshotPhotoUrls(entry),
      entryId: entry.id,
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );
  }

  /// PDF·주문용 — Firebase Storage URL만 (로컬 파일 경로는 admin PDF에서 사용 불가)
  static List<String> snapshotPhotoUrls(DailyEntry entry) {
    final locals = entry.localPhotoPaths;
    final remotes = entry.remotePhotoUrls;

    if (locals.isEmpty) {
      return remotes.where(_isPrintableUrl).toList();
    }

    final urls = <String>[];
    for (var i = 0; i < locals.length; i++) {
      if (i < remotes.length && _isPrintableUrl(remotes[i])) {
        urls.add(remotes[i]);
      }
    }
    return urls;
  }

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
