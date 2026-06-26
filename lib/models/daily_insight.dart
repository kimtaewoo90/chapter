/// 저장 직후 또는 피드에 표시하는 하루 인사이트
class DailyInsight {
  const DailyInsight({
    required this.entryId,
    required this.message,
    this.storyArcTitle,
    this.topics = const [],
  });

  final String entryId;
  final String message;
  final String? storyArcTitle;
  final List<String> topics;

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'message': message,
        'storyArcTitle': storyArcTitle,
        'topics': topics,
      };

  factory DailyInsight.fromJson(Map<String, dynamic> json) {
    return DailyInsight(
      entryId: json['entryId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      storyArcTitle: json['storyArcTitle'] as String?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}
