import '../../models/daily_entry.dart';
import '../../models/journal_analysis.dart';

/// Gemini 없을 때 규칙 기반 일기 분류
class JournalAnalysisFallback {
  JournalAnalysisFallback._();

  static const _categoryKeywords = <String, List<String>>{
    'career_change': ['이직', '퇴사', '면접', '이력서', '커리어', '직장', '회사', '팀장', '승진', 'job', 'career'],
    'health_recovery': ['운동', '병원', '건강', '다이어트', '수면', '회복', '헬스', '요가'],
    'relationship': ['연애', '헤어', '친구', '가족', '엄마', '아빠', '남친', '여친', '결혼'],
    'startup': ['창업', '사업', '스타트업', '투자', '피치', '사업계획'],
    'travel': ['여행', '비행', '호텔', '관광', '출장'],
    'study': ['공부', '시험', '학교', '수업', '자격증', '책'],
    'daily_life': ['카페', '맛집', '산책', '집', '요리', '쇼핑'],
  };

  static JournalAnalysis analyze(DailyEntry entry) {
    final text = _journalText(entry).toLowerCase();
    final topics = <String>[];

    for (final cat in _categoryKeywords.entries) {
      if (cat.value.any((k) => text.contains(k.toLowerCase()))) {
        topics.add(cat.key);
      }
    }
    if (topics.isEmpty) topics.add('daily_life');

    final emotion = _emotionFrom(entry, text);
    final importance = _importanceFrom(entry, text, topics);

    return JournalAnalysis(
      topics: topics.take(3).toList(),
      emotion: emotion,
      importanceScore: importance,
    );
  }

  static String _journalText(DailyEntry entry) {
    final parts = <String>[
      if (entry.note != null) entry.note!,
      if (entry.moodLabel != null) entry.moodLabel!,
      if (entry.aiLine != null) entry.aiLine!,
    ];
    return parts.join(' ');
  }

  static String _emotionFrom(DailyEntry entry, String text) {
    const negative = ['슬', '우울', '화', '짜', '답', '힘들', '스트레스', '불안', '혼났', '실망'];
    const positive = ['좋', '행복', '기쁨', '설레', '감사', '뿌듯', '즐', '신나', '편안'];
    if (negative.any(text.contains)) return 'negative';
    if (positive.any(text.contains)) return 'positive';
    final mood = entry.moodEmoji;
    if (mood == '😢' || mood == '😤' || mood == '😵' || mood == '😴') return 'negative';
    if (mood == '🎉' || mood == '🙂' || mood == '🤍' || mood == '😌') return 'positive';
    return 'neutral';
  }

  static double _importanceFrom(DailyEntry entry, String text, List<String> topics) {
    var score = 0.45;
    if (entry.note != null && entry.note!.trim().length >= 20) score += 0.15;
    if (topics.any((t) => t != 'daily_life')) score += 0.12;
    if (text.contains('처음') || text.contains('결정') || text.contains('시작')) score += 0.1;
    return score.clamp(0.2, 0.85);
  }

  static String categoryLabel(String category) => switch (category) {
        'career_change' => '커리어 변화',
        'health_recovery' => '건강 회복',
        'relationship' => '관계',
        'startup' => '창업·사업',
        'travel' => '여행',
        'study' => '공부·성장',
        _ => '일상',
      };

  static String suggestDisplayTitle(String category, List<DailyEntry> entries) {
    final label = categoryLabel(category);
    if (entries.length >= 5) return '$label 이야기';
    return '새로운 $label';
  }
}
