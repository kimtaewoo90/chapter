/// Story Arc 진행 상태 — 진행률(%)은 사용하지 않음
enum StoryArcStatus {
  seeding,
  growing,
  focused,
  shifting,
  completed;

  String get label => switch (this) {
        StoryArcStatus.seeding => '씨앗',
        StoryArcStatus.growing => '자라는 중',
        StoryArcStatus.focused => '집중',
        StoryArcStatus.shifting => '전환',
        StoryArcStatus.completed => '완성',
      };

  bool get isActive => this != StoryArcStatus.completed;

  static StoryArcStatus fromString(String? raw) {
    return StoryArcStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => StoryArcStatus.seeding,
    );
  }
}
