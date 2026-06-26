/// Gemini Story Arc 매칭 결과
class StoryArcMatchResult {
  const StoryArcMatchResult({
    this.storyArcId,
    required this.confidence,
    this.newCategory,
    this.newDisplayTitle,
    this.newDescription,
  });

  final String? storyArcId;
  final double confidence;
  final String? newCategory;
  final String? newDisplayTitle;
  final String? newDescription;
}

/// Gemini 신규 Story Arc 발견 결과
class NewStoryArcCandidate {
  const NewStoryArcCandidate({
    required this.newStoryDetected,
    required this.category,
    required this.title,
    required this.confidence,
  });

  final bool newStoryDetected;
  final String category;
  final String title;
  final double confidence;
}
