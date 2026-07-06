/// 월간 리포트 — 일기에서 추출한 팩트 항목
class MonthlyFactItem {
  const MonthlyFactItem({
    required this.label,
    required this.count,
    this.hint,
  });

  final String label;
  final int count;
  /// 보조 설명 (예: 등장 날짜, 이모지)
  final String? hint;

  Map<String, dynamic> toJson() => {
        'label': label,
        'count': count,
        if (hint != null && hint!.isNotEmpty) 'hint': hint,
      };

  factory MonthlyFactItem.fromJson(Map<String, dynamic> json) => MonthlyFactItem(
        label: json['label'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        hint: json['hint'] as String?,
      );
}

/// 캘린더 월 일기에서 집계한 팩트 요약
class MonthlyReviewDigest {
  const MonthlyReviewDigest({
    required this.recordedDays,
    required this.photoDays,
    required this.noteDays,
    required this.totalPhotos,
    required this.moods,
    required this.places,
    required this.words,
    required this.people,
    required this.emotions,
    required this.factSummary,
  });

  final int recordedDays;
  final int photoDays;
  final int noteDays;
  final int totalPhotos;
  final List<MonthlyFactItem> moods;
  final List<MonthlyFactItem> places;
  final List<MonthlyFactItem> words;
  final List<MonthlyFactItem> people;
  final List<MonthlyFactItem> emotions;
  /// 팩트만으로 만든 한 줄 (AI 없이도 동작)
  final String factSummary;

  bool get hasFacts =>
      moods.isNotEmpty ||
      places.isNotEmpty ||
      words.isNotEmpty ||
      people.isNotEmpty ||
      emotions.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'recordedDays': recordedDays,
        'photoDays': photoDays,
        'noteDays': noteDays,
        'totalPhotos': totalPhotos,
        'moods': moods.map((e) => e.toJson()).toList(),
        'places': places.map((e) => e.toJson()).toList(),
        'words': words.map((e) => e.toJson()).toList(),
        'people': people.map((e) => e.toJson()).toList(),
        'emotions': emotions.map((e) => e.toJson()).toList(),
        'factSummary': factSummary,
      };

  factory MonthlyReviewDigest.fromJson(Map<String, dynamic> json) {
    List<MonthlyFactItem> parseList(dynamic value) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => MonthlyFactItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.label.isNotEmpty && e.count > 0)
          .toList();
    }

    return MonthlyReviewDigest(
      recordedDays: (json['recordedDays'] as num?)?.toInt() ?? 0,
      photoDays: (json['photoDays'] as num?)?.toInt() ?? 0,
      noteDays: (json['noteDays'] as num?)?.toInt() ?? 0,
      totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
      moods: parseList(json['moods']),
      places: parseList(json['places']),
      words: parseList(json['words']),
      people: parseList(json['people']),
      emotions: parseList(json['emotions']),
      factSummary: json['factSummary'] as String? ?? '',
    );
  }
}
