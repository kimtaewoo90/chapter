import '../../models/daily_entry.dart';
import 'entry_diary_ai.dart';

/// 일기 문장 — Gemini 실패 시 규칙 폴백
class AiNarrative {
  /// API 미설정·오류 시 사용하는 규칙 기반 문장
  static String? fallbackDailyLine(DailyEntry entry, {List<DailyEntry> pastEntries = const []}) {
    if (!EntryDiaryAi.shouldGenerateAiDiaryForEntry(entry)) {
      return null;
    }

    final tone = _ToneProfile.fromPastEntries(pastEntries, excludeDate: entry.date);
    return _lineFromPhotos(entry, tone);
  }

  static String _lineFromPhotos(DailyEntry entry, _ToneProfile tone) {
    final count = entry.photoCount;
    final hour = entry.date.hour;
    final mood = entry.moodEmoji;
    final timeHint = _timeHint(hour);

    if (mood != null) {
      return tone.apply(_photoLineWithMood(count: count, mood: mood, timeHint: timeHint));
    }

    if (count == 1) {
      return tone.apply(_singlePhotoLine(timeHint));
    }
    return tone.apply(_multiPhotoLine(count, timeHint));
  }

  static String _singlePhotoLine(String timeHint) {
    return switch (timeHint) {
      'morning' => '아침에 남긴 사진 한 장이 오늘의 장면이에요.',
      'afternoon' => '오늘 낮, 찍어 둔 사진 한 장으로 하루를 남겼어요.',
      'evening' => '저녁에 담아 둔 사진 한 장이 오늘 페이지예요.',
      _ => '오늘 남긴 사진 한 장이 이 하루를 대신 말해 줄 것 같아요.',
    };
  }

  static String _multiPhotoLine(int count, String timeHint) {
    final n = count.clamp(2, 99);
    return switch (timeHint) {
      'morning' => '아침부터 $n장의 장면을 붙여 두었어요.',
      'evening' => '오늘 저녁까지 $n장의 순간을 남겼어요.',
      _ => '오늘은 $n장의 사진으로 하루가 채워졌어요.',
    };
  }

  static String _photoLineWithMood({
    required int count,
    required String mood,
    required String timeHint,
  }) {
    final scene = count == 1 ? '사진 한 장' : '사진 ${count.clamp(2, 99)}장';
    return '$scene — 오늘의 무드가 사진에 남아 있어요.';
  }

  static String _timeHint(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}

class _ToneProfile {
  const _ToneProfile({
    required this.hasHistory,
    required this.prefersShort,
    required this.casual,
    required this.soft,
  });

  final bool hasHistory;
  final bool prefersShort;
  final bool casual;
  final bool soft;

  factory _ToneProfile.fromPastEntries(
    List<DailyEntry> entries, {
    DateTime? excludeDate,
  }) {
    final notes = <String>[];
    for (final e in entries) {
      if (excludeDate != null &&
          e.date.year == excludeDate.year &&
          e.date.month == excludeDate.month &&
          e.date.day == excludeDate.day) {
        continue;
      }
      final n = e.note?.trim();
      if (n != null && n.isNotEmpty) notes.add(n);
    }

    if (notes.isEmpty) {
      return const _ToneProfile(
        hasHistory: false,
        prefersShort: false,
        casual: false,
        soft: true,
      );
    }

    final avgLen = notes.fold<int>(0, (s, n) => s + n.length) / notes.length;
    var casualHits = 0;
    var softHits = 0;
    for (final n in notes) {
      if (RegExp(r'(ㅋ|ㅎ|~|!|진짜|그냥|음 )').hasMatch(n)) casualHits++;
      if (RegExp(r'(조용|따뜻|그리|스며|잔잔|편안|좋았)').hasMatch(n)) softHits++;
      if (n.endsWith('다') || n.endsWith('다.') || n.contains('했다')) casualHits++;
      if (n.endsWith('요') || n.endsWith('요.') || n.endsWith('네요')) softHits++;
    }

    final isCasual = casualHits >= notes.length / 2;

    return _ToneProfile(
      hasHistory: true,
      prefersShort: avgLen < 36,
      casual: isCasual,
      soft: softHits >= notes.length / 3 || !isCasual,
    );
  }

  String apply(String base) {
    if (!hasHistory) return base;
    if (prefersShort) return _shorten(base);
    if (casual) return _casualize(base);
    if (soft) return base;
    return base;
  }

  String _shorten(String s) {
    if (s.length <= 42) return s;
    return '${s.substring(0, 40)}…';
  }

  String _casualize(String s) {
    return s
        .replaceFirst('했어요', '했어')
        .replaceFirst('이에요', '이야')
        .replaceFirst('예요', '야')
        .replaceFirst('있어요', '있어');
  }
}
