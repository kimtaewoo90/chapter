/// 오늘의 무드 — 이모지 + 사용자 라벨(같은 이모지도 라벨로 구분)
class MoodOption {
  const MoodOption(this.emoji, this.label, {this.isCustom = false});

  final String emoji;
  final String label;
  final bool isCustom;

  String get key => '$emoji|$label';

  MoodOption copyWith({String? label, bool? isCustom}) => MoodOption(
        emoji,
        label ?? this.label,
        isCustom: isCustom ?? this.isCustom,
      );

  static MoodOption? fromKey(String? key) {
    if (key == null || !key.contains('|')) return null;
    final i = key.indexOf('|');
    return MoodOption(key.substring(0, i), key.substring(i + 1));
  }
}

/// 기본 무드 — 날씨·시적 표현 대신 일상 감정
const kDefaultMoods = [
  MoodOption('😌', '편안'),
  MoodOption('😴', '피곤'),
  MoodOption('🙂', '괜찮'),
  MoodOption('🔥', '몰입'),
  MoodOption('😵', '벅참'),
  MoodOption('🫥', '텅 빈'),
  MoodOption('🥲', '웃픈'),
  MoodOption('🎉', '신남'),
  MoodOption('🧘', '잔잔'),
  MoodOption('💭', '생각 많'),
  MoodOption('😤', '답답'),
  MoodOption('🤍', '소중'),
];

/// 무드 추가 시 고를 수 있는 이모지
const kMoodEmojiPicker = [
  '😌', '😴', '🙂', '🔥', '😵', '🫥', '🥲', '🎉',
  '🧘', '💭', '😤', '🤍', '😊', '😢', '😡', '🥳',
  '🫠', '😮‍💨', '🤔', '🫶', '✨', '☕', '📚', '🏃',
];

@Deprecated('Use kDefaultMoods')
const kMoods = kDefaultMoods;
