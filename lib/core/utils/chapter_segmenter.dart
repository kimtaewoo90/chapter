import '../../models/daily_entry.dart';

/// 기록을 분위기·무드·주제 변화로 나누고, **완성된** 구간만 챕터로 본다.
class ChapterSegmenter {
  ChapterSegmenter._();

  /// 챕터로 묶기 전 최소 기록 수
  static const int minEntriesToSeal = 3;

  /// 기록이 끊기면 챕터 경계 후보 (고정 주기 아님 — 긴 공백 신호)
  static const int gapDaysToBreak = 21;

  static List<ChapterSegment> segment(List<DailyEntry> entries) {
    if (entries.isEmpty) return [];

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final sealed = <ChapterSegment>[];
    var buffer = <DailyEntry>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final entry = sorted[i];
      if (_shouldSealBefore(buffer, entry)) {
        sealed.add(ChapterSegment(entries: List.unmodifiable(buffer), isComplete: true));
        buffer = [entry];
      } else {
        buffer.add(entry);
      }
    }

    return [
      ...sealed,
      ChapterSegment(entries: List.unmodifiable(buffer), isComplete: false),
    ];
  }

  static List<ChapterSegment> completedOnly(List<DailyEntry> entries) {
    return segment(entries).where((s) => s.isComplete).toList();
  }

  static ChapterSegment? openSegment(List<DailyEntry> entries) {
    final all = segment(entries);
    if (all.isEmpty) return null;
    final last = all.last;
    return last.isComplete ? null : last;
  }

  /// 열린 풀에서 맨 끝 기록이 분위기 전환인지 — 봉인 후보 [sealed] | [remaining]
  static OpenPoolSplit? splitOpenPoolOnBoundary(List<DailyEntry> open) {
    if (open.length < minEntriesToSeal) return null;

    final sorted = [...open]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < minEntriesToSeal) return null;

    final last = sorted.last;
    final before = sorted.sublist(0, sorted.length - 1);
    if (before.length >= minEntriesToSeal && _shouldSealBefore(before, last)) {
      return OpenPoolSplit(sealed: before, remaining: [last]);
    }
    return null;
  }

  static bool shouldSealBefore(List<DailyEntry> buffer, DailyEntry next) =>
      _shouldSealBefore(buffer, next);

  static bool _shouldSealBefore(List<DailyEntry> buffer, DailyEntry next) {
    if (buffer.length < minEntriesToSeal) return false;

    final last = buffer.last;
    final gap = next.date.difference(last.date).inDays;
    if (gap >= gapDaysToBreak) return true;

    final profile = _profile(buffer);
    final nextProfile = _entryProfile(next);

    if (_moodBreak(profile, nextProfile)) return true;
    if (_labelBreak(profile, nextProfile)) return true;
    if (_topicBreak(profile, nextProfile)) return true;

    return false;
  }

  static bool _moodBreak(_SegmentProfile chapter, _EntryProfile next) {
    final dominant = chapter.dominantMood;
    final mood = next.moodEmoji;
    if (dominant == null || mood == null) return false;
    if (dominant == mood) return false;
  return chapter.moodShare(dominant) >= 0.45;
  }

  static bool _labelBreak(_SegmentProfile chapter, _EntryProfile next) {
    final dominant = chapter.dominantLabel;
    final label = next.moodLabel;
    if (dominant == null || label == null || label.isEmpty) return false;
    if (dominant == label) return false;
    return chapter.labelShare(dominant) >= 0.34;
  }

  static bool _topicBreak(_SegmentProfile chapter, _EntryProfile next) {
    if (chapter.keywords.isEmpty || next.keywords.isEmpty) return false;
    final overlap = chapter.keywords.intersection(next.keywords).length;
    final union = chapter.keywords.union(next.keywords).length;
    if (union == 0) return false;
    return overlap / union < 0.15;
  }

  static _SegmentProfile _profile(List<DailyEntry> entries) {
    final moodCounts = <String, int>{};
    final labelCounts = <String, int>{};
    final keywords = <String>{};

    for (final e in entries) {
      final m = e.moodEmoji;
      if (m != null) moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      final l = e.moodLabel?.trim();
      if (l != null && l.isNotEmpty) labelCounts[l] = (labelCounts[l] ?? 0) + 1;
      keywords.addAll(_keywordsFromNote(e.note));
    }

    return _SegmentProfile(
      entryCount: entries.length,
      moodCounts: moodCounts,
      labelCounts: labelCounts,
      keywords: keywords,
    );
  }

  static _EntryProfile _entryProfile(DailyEntry e) {
    return _EntryProfile(
      moodEmoji: e.moodEmoji,
      moodLabel: e.moodLabel?.trim(),
      keywords: _keywordsFromNote(e.note),
    );
  }

  static Set<String> _keywordsFromNote(String? note) {
    final text = note?.trim();
    if (text == null || text.length < 2) return {};

    final out = <String>{};
    for (final m in RegExp(r'[A-Za-z][A-Za-z0-9]{1,12}').allMatches(text)) {
      out.add(m.group(0)!.toLowerCase());
    }
    const stop = {'오늘', '그냥', '진짜', '너무', '이번', '내일', '어제', '근데', '그래서'};
    for (final m in RegExp(r'[가-힣]{2,6}').allMatches(text)) {
      final w = m.group(0)!;
      if (!stop.contains(w)) out.add(w);
    }
    return out;
  }
}

class ChapterSegment {
  const ChapterSegment({
    required this.entries,
    required this.isComplete,
  });

  final List<DailyEntry> entries;
  final bool isComplete;

  DateTime get startDate => entries.first.date;
  DateTime get endDate => entries.last.date;

  String get dateRangeKey =>
      '${DailyEntry.dateKeyFrom(startDate)}_${DailyEntry.dateKeyFrom(endDate)}';
}

class OpenPoolSplit {
  const OpenPoolSplit({required this.sealed, required this.remaining});

  final List<DailyEntry> sealed;
  final List<DailyEntry> remaining;
}

class _SegmentProfile {
  const _SegmentProfile({
    required this.entryCount,
    required this.moodCounts,
    required this.labelCounts,
    required this.keywords,
  });

  final int entryCount;
  final Map<String, int> moodCounts;
  final Map<String, int> labelCounts;
  final Set<String> keywords;

  String? get dominantMood {
    if (moodCounts.isEmpty) return null;
    return moodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String? get dominantLabel {
    if (labelCounts.isEmpty) return null;
    return labelCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double moodShare(String mood) => (moodCounts[mood] ?? 0) / entryCount;
  double labelShare(String label) => (labelCounts[label] ?? 0) / entryCount;
}

class _EntryProfile {
  const _EntryProfile({
    this.moodEmoji,
    this.moodLabel,
    required this.keywords,
  });

  final String? moodEmoji;
  final String? moodLabel;
  final Set<String> keywords;
}
