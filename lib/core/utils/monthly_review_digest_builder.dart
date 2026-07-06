import '../../models/daily_entry.dart';
import '../../models/monthly_review_digest.dart';

/// 일기 텍스트·무드·장소에서 월간 팩트를 추출 (로컬, 항상 동작)
class MonthlyReviewDigestBuilder {
  MonthlyReviewDigestBuilder._();

  static const _stopwords = {
    '그리고', '하지만', '그래서', '오늘', '어제', '내일', '이번', '저번', '정말', '너무',
    '조금', '많이', '있는', '없는', '했다', '했어', '했던', '하는', '하면', '해서',
    '이런', '저런', '그런', '이거', '저거', '그거', '여기', '거기', '우리', '나는',
    '내가', '너는', '그냥', '약간', '다시', '또한', '역시', '이제', '벌써', '아직',
    '매일', '하루', '시간', '사진', '기록', '일기', '오늘은', '요즘', '이날', '날씨',
    'the', 'and', 'with', 'for', 'from',
  };

  static const _peopleLexicon = {
    '엄마': '엄마',
    '아빠': '아빠',
    '어머니': '엄마',
    '아버지': '아빠',
    '남편': '남편',
    '아내': '아내',
    '와이프': '아내',
    '아이': '아이',
    '애기': '아이',
    '아가': '아이',
    '딸': '딸',
    '아들': '아들',
    '첫째': '첫째',
    '둘째': '둘째',
    '셋째': '셋째',
    '친구': '친구',
    '언니': '언니',
    '오빠': '오빠',
    '동생': '동생',
    '할머니': '할머니',
    '할아버지': '할아버지',
    '선생님': '선생님',
    '동료': '동료',
    '남친': '남친',
    '여친': '여친',
    '연인': '연인',
    '부모님': '부모님',
    '조카': '조카',
    '카페': null,
    '집': null,
  };

  static const _emotionLabels = {
    'positive': '긍정',
    'negative': '부정',
    'neutral': '평온',
    'mixed': '복합',
  };

  static MonthlyReviewDigest build(
    List<DailyEntry> entries, {
    required String periodLabel,
  }) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    var photoDays = 0;
    var noteDays = 0;
    var totalPhotos = 0;
    final moodCounts = <String, _RankAccumulator>{};
    final placeCounts = <String, _RankAccumulator>{};
    final wordCounts = <String, _RankAccumulator>{};
    final peopleCounts = <String, _RankAccumulator>{};
    final emotionCounts = <String, _RankAccumulator>{};

    for (final entry in sorted) {
      if (entry.hasPhotos) {
        photoDays++;
        totalPhotos += entry.photoCount;
      }
      if (entry.note != null && entry.note!.trim().length >= 2) {
        noteDays++;
      }

      _accumulateMood(entry, moodCounts);
      _accumulatePlace(entry, placeCounts);
      _accumulateEmotion(entry, emotionCounts);

      final text = _entryText(entry);
      if (text.isNotEmpty) {
        _accumulatePeople(text, peopleCounts);
        _accumulateWords(text, wordCounts);
      }
    }

    final moods = _toRankedList(moodCounts, limit: 5);
    final places = _toRankedList(placeCounts, limit: 5);
    final words = _toRankedList(wordCounts, limit: 8);
    final people = _toRankedList(peopleCounts, limit: 5);
    final emotions = _toRankedList(emotionCounts, limit: 4);

    final digest = MonthlyReviewDigest(
      recordedDays: sorted.length,
      photoDays: photoDays,
      noteDays: noteDays,
      totalPhotos: totalPhotos,
      moods: moods,
      places: places,
      words: words,
      people: people,
      emotions: emotions,
      factSummary: '',
    );

    return digest.copyWithFactSummary(
      _buildFactSummary(digest, periodLabel),
    );
  }

  static String _entryText(DailyEntry entry) {
    final parts = <String>[];
    final note = entry.note?.trim();
    final aiLine = entry.aiLine?.trim();
    if (note != null && note.isNotEmpty) parts.add(note);
    if (aiLine != null && aiLine.isNotEmpty) parts.add(aiLine);
    return parts.join(' ');
  }

  static void _accumulateMood(DailyEntry entry, Map<String, _RankAccumulator> counts) {
    final emoji = entry.moodEmoji?.trim();
    final label = entry.moodLabel?.trim();
    if ((emoji == null || emoji.isEmpty) && (label == null || label.isEmpty)) return;

    final key = '${emoji ?? ''}|${label ?? ''}';
    final display = [
      if (emoji != null && emoji.isNotEmpty) emoji,
      if (label != null && label.isNotEmpty) label,
    ].join(' ');

    counts.putIfAbsent(key, () => _RankAccumulator(label: display)).increment();
  }

  static void _accumulatePlace(DailyEntry entry, Map<String, _RankAccumulator> counts) {
    final raw = entry.location?.trim();
    if (raw == null || raw.isEmpty) return;
    final normalized = _normalizePlace(raw);
    if (normalized.isEmpty) return;
    counts.putIfAbsent(normalized, () => _RankAccumulator(label: normalized)).increment();
  }

  static String _normalizePlace(String raw) {
    var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';

    final parts = text.split(RegExp(r'[·,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final candidate = parts[1];
      if (candidate.length <= 12) return candidate;
    }

    final tokens = text.split(' ').where((e) => e.isNotEmpty).toList();
    for (final token in tokens.reversed) {
      if (token.length >= 2 && token.length <= 10) {
        if (token.endsWith('구') ||
            token.endsWith('동') ||
            token.endsWith('역') ||
            token.endsWith('시') ||
            token.endsWith('군') ||
            token.endsWith('면') ||
            token.endsWith('리')) {
          return token;
        }
      }
    }

    if (tokens.length >= 2) return tokens[1];
    return text.length > 14 ? '${text.substring(0, 14)}…' : text;
  }

  static void _accumulateEmotion(DailyEntry entry, Map<String, _RankAccumulator> counts) {
    final raw = entry.emotion?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return;
    final label = _emotionLabels[raw] ?? raw;
    counts.putIfAbsent(raw, () => _RankAccumulator(label: label)).increment();
  }

  static void _accumulatePeople(String text, Map<String, _RankAccumulator> counts) {
    for (final entry in _peopleLexicon.entries) {
      final mapped = entry.value;
      if (mapped == null) continue;
      final matches = entry.key.allMatches(text).length;
      if (matches > 0) {
        counts.putIfAbsent(mapped, () => _RankAccumulator(label: mapped)).add(matches);
      }
    }
  }

  static void _accumulateWords(String text, Map<String, _RankAccumulator> counts) {
    final cleaned = text
        .replaceAll(RegExp(r'[^\w가-힣\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    for (final token in cleaned.split(' ')) {
      if (token.length < 2) continue;
      if (_stopwords.contains(token)) continue;
      if (RegExp(r'^\d+$').hasMatch(token)) continue;
      if (_peopleLexicon.containsKey(token)) continue;
      counts.putIfAbsent(token, () => _RankAccumulator(label: token)).increment();
    }
  }

  static List<MonthlyFactItem> _toRankedList(
    Map<String, _RankAccumulator> counts, {
    required int limit,
  }) {
    final list = counts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list
        .take(limit)
        .map((e) => MonthlyFactItem(label: e.label, count: e.count, hint: e.hint))
        .toList();
  }

  static String _buildFactSummary(MonthlyReviewDigest digest, String periodLabel) {
    final parts = <String>[];

    if (digest.moods.isNotEmpty) {
      parts.add('${digest.moods.first.label} ${digest.moods.first.count}번');
    }
    if (digest.places.isNotEmpty) {
      parts.add('${digest.places.first.label} ${digest.places.first.count}번');
    }
    if (digest.people.isNotEmpty) {
      parts.add('${digest.people.first.label} ${digest.people.first.count}번');
    }
    if (digest.words.isNotEmpty && parts.length < 3) {
      parts.add('「${digest.words.first.label}」 ${digest.words.first.count}번');
    }

    if (parts.isEmpty) {
      return '$periodLabel, ${digest.recordedDays}일의 기록이 남았어요.';
    }
    return '$periodLabel — ${parts.take(3).join(' · ')}.';
  }
}

class _RankAccumulator {
  _RankAccumulator({required this.label});

  final String label;
  int count = 0;
  String? hint;

  void increment() => count++;
  void add(int n) => count += n;
}

extension _MonthlyReviewDigestCopy on MonthlyReviewDigest {
  MonthlyReviewDigest copyWithFactSummary(String factSummary) => MonthlyReviewDigest(
        recordedDays: recordedDays,
        photoDays: photoDays,
        noteDays: noteDays,
        totalPhotos: totalPhotos,
        moods: moods,
        places: places,
        words: words,
        people: people,
        emotions: emotions,
        factSummary: factSummary,
      );
}
