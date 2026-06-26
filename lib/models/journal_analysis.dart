/// Gemini 일기 분류 결과 — 생성이 아닌 분류(Classification)
class JournalAnalysis {
  const JournalAnalysis({
    required this.topics,
    required this.emotion,
    required this.importanceScore,
  });

  final List<String> topics;
  final String emotion;
  final double importanceScore;

  Map<String, dynamic> toJson() => {
        'topics': topics,
        'emotion': emotion,
        'importanceScore': importanceScore,
      };

  factory JournalAnalysis.fromJson(Map<String, dynamic> json) {
    return JournalAnalysis(
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      emotion: json['emotion'] as String? ?? 'neutral',
      importanceScore: (json['importanceScore'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
