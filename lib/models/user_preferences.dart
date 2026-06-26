class UserPreferences {
  const UserPreferences({
    this.weather = '',
    this.recordStyle = '',
    this.chronotype = '',
    this.colorTone = '',
    this.keywords = const [],
  });

  final String weather;
  /// 기록 방식 (한 줄 / 사진 우선 / 긴 문장)
  final String recordStyle;
  final String chronotype;
  final String colorTone;
  final List<String> keywords;

  Map<String, dynamic> toMap() => {
        'weather': weather,
        'recordStyle': recordStyle,
        'chronotype': chronotype,
        'colorTone': colorTone,
        'keywords': keywords,
      };

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    return UserPreferences(
      weather: map['weather'] as String? ?? '',
      recordStyle: (map['recordStyle'] ?? map['musicVibe']) as String? ?? '',
      chronotype: map['chronotype'] as String? ?? '',
      colorTone: map['colorTone'] as String? ?? '',
      keywords: List<String>.from(map['keywords'] as List? ?? []),
    );
  }
}
