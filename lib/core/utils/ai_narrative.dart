import '../../models/daily_entry.dart';
import 'entry_diary_ai.dart';

/// 일기·챕터 문장 — Gemini 실패 시 규칙 폴백 (챕터 제목은 메모·무드 라벨 우선)
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

  static String chapterNarrative({
    required List<DailyEntry> entries,
    required String title,
  }) {
    if (entries.isEmpty) {
      return '이 챕터는 아직 조용히 시작되고 있어요.';
    }

    final snippets = entries
        .map((e) => e.note?.trim())
        .whereType<String>()
        .where((n) => n.length >= 4)
        .take(2)
        .toList();

    if (snippets.isNotEmpty) {
      final joined = snippets.map((s) => '「$s」').join(' ');
      return '$joined\n${entries.length}일의 기록이 「$title」로 묶였어요.';
    }

    final tone = _ToneProfile.fromPastEntries(entries);
    return tone.apply('${entries.length}일의 순간이 「$title」라는 이름으로 모였어요.');
  }

  /// 챕터 제목 — Gemini 우선, 폴백은 무드·짧은 메모·기간
  static String suggestChapterTitle(List<DailyEntry> entries) {
    if (entries.isEmpty) return '새 페이지';

    final fromLabel = _titleFromMoodLabels(entries);
    if (fromLabel != null) return fromLabel;

    final fromNote = _titleFromNotes(entries);
    if (fromNote != null) return fromNote;

    final fromPlace = _titleFromLocations(entries);
    if (fromPlace != null) return fromPlace;

    return _titleFromPeriod(entries);
  }

  /// 메모 전체 문장을 제목으로 쓰지 않음 — 짧은 메모·고유명사만
  static String? _titleFromNotes(List<DailyEntry> entries) {
    for (final e in entries) {
      final note = e.note?.trim();
      if (note == null || note.isEmpty) continue;

      // 영문 고유명 (SBI, Tokyo …)
      for (final m in RegExp(r'[A-Za-z][A-Za-z0-9]{1,14}').allMatches(note)) {
        final w = m.group(0)!;
        if (w.length >= 2) return w;
      }

      // 한 줄이 짧고 문장형이 아닐 때만 (카페, 출장, 육아텅 등)
      final oneLine = note.split(RegExp(r'[\n\r]')).first.trim();
      if (_isShortTitleCandidate(oneLine)) return oneLine;
    }
    return null;
  }

  static bool _isShortTitleCandidate(String text) {
    if (text.length < 2 || text.length > 10) return false;
    if (text.contains('?') || text.contains('…') || text.endsWith('...')) return false;
    if (RegExp(r'(요|다|까|나|네|지)\??$').hasMatch(text)) return false;
    return true;
  }

  static String? _titleFromMoodLabels(List<DailyEntry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final label = e.moodLabel?.trim();
      if (label == null || label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value >= 2) return top.key;
    if (entries.length <= 5) return top.key;
    return null;
  }

  static String? _titleFromLocations(List<DailyEntry> entries) {
    final locs = entries
        .map((e) => e.location?.trim())
        .whereType<String>()
        .where((l) => l.isNotEmpty && l.length <= 20)
        .toList();
    if (locs.isEmpty) return null;
    return locs.first;
  }

  static String _titleFromPeriod(List<DailyEntry> entries) {
    final start = entries.last.date;
    final end = entries.first.date;
    final sy = start.year;
    final sm = start.month;
    final ey = end.year;
    final em = end.month;

    if (sy == ey && sm == em) {
      return '$sy.${sm.toString().padLeft(2, '0')}';
    }
    if (sy == ey) {
      return '$sy.${sm.toString().padLeft(2, '0')}–${em.toString().padLeft(2, '0')}';
    }
    return '${start.year}.${start.month.toString().padLeft(2, '0')} — ${end.year}.${end.month.toString().padLeft(2, '0')}';
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
