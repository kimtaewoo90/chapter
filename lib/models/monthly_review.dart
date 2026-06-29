import '../core/utils/monthly_review_period.dart';

/// 캘린더 월 단위 월간 리포트
class MonthlyReview {
  const MonthlyReview({
    required this.periodKey,
    required this.periodLabel,
    required this.generatedAt,
    required this.topTopics,
    required this.summary,
    required this.growth,
    this.revealedAt,
    this.emotionTrend = '',
    this.chapterChanges = const [],
  });

  final String periodKey;
  final String periodLabel;
  final DateTime generatedAt;
  final DateTime? revealedAt;
  final List<String> topTopics;
  final String summary;
  final String growth;
  final String emotionTrend;
  final List<String> chapterChanges;

  bool get wasRevealed => revealedAt != null;

  MonthlyReview copyWith({
    String? periodKey,
    String? periodLabel,
    DateTime? generatedAt,
    DateTime? revealedAt,
    List<String>? topTopics,
    String? summary,
    String? growth,
    String? emotionTrend,
    List<String>? chapterChanges,
  }) =>
      MonthlyReview(
        periodKey: periodKey ?? this.periodKey,
        periodLabel: periodLabel ?? this.periodLabel,
        generatedAt: generatedAt ?? this.generatedAt,
        revealedAt: revealedAt ?? this.revealedAt,
        topTopics: topTopics ?? this.topTopics,
        summary: summary ?? this.summary,
        growth: growth ?? this.growth,
        emotionTrend: emotionTrend ?? this.emotionTrend,
        chapterChanges: chapterChanges ?? this.chapterChanges,
      );

  Map<String, dynamic> toJson() => {
        'periodKey': periodKey,
        'periodLabel': periodLabel,
        'generatedAt': generatedAt.toIso8601String(),
        'revealedAt': revealedAt?.toIso8601String(),
        'topTopics': topTopics,
        'summary': summary,
        'growth': growth,
        'emotionTrend': emotionTrend,
        'chapterChanges': chapterChanges,
      };

  factory MonthlyReview.fromJson(Map<String, dynamic> json) {
    final generatedAt =
        DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now();
    var periodKey = json['periodKey'] as String? ?? '';
    var periodLabel = json['periodLabel'] as String? ?? '';

    if (periodKey.isEmpty) {
      periodKey = MonthlyReviewPeriod.periodKeyFromDate(generatedAt);
    }
    if (periodLabel.isEmpty) {
      periodLabel = MonthlyReviewPeriod.periodLabelFromDate(generatedAt);
    }

    return MonthlyReview(
      periodKey: periodKey,
      periodLabel: periodLabel,
      generatedAt: generatedAt,
      revealedAt: json['revealedAt'] != null
          ? DateTime.tryParse(json['revealedAt'] as String)
          : null,
      topTopics: _parseStringList(json['topTopics']),
      summary: json['summary'] as String? ?? '',
      growth: json['growth'] as String? ?? '',
      emotionTrend: json['emotionTrend'] as String? ?? '',
      chapterChanges: _parseStringList(json['chapterChanges']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
