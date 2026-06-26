/// 최근 30일 월간 리포트
class MonthlyReview {
  const MonthlyReview({
    required this.generatedAt,
    required this.topTopics,
    required this.summary,
    required this.growth,
    this.emotionTrend = '',
    this.chapterChanges = const [],
  });

  final DateTime generatedAt;
  final List<String> topTopics;
  final String summary;
  final String growth;
  final String emotionTrend;
  final List<String> chapterChanges;

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'topTopics': topTopics,
        'summary': summary,
        'growth': growth,
        'emotionTrend': emotionTrend,
        'chapterChanges': chapterChanges,
      };

  factory MonthlyReview.fromJson(Map<String, dynamic> json) {
    return MonthlyReview(
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      topTopics: (json['topTopics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      summary: json['summary'] as String? ?? '',
      growth: json['growth'] as String? ?? '',
      emotionTrend: json['emotionTrend'] as String? ?? '',
      chapterChanges: (json['chapterChanges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}
