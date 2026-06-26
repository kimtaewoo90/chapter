import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/weather_placeholder.dart';

class DailyEntry {
  const DailyEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.localPhotoPaths = const [],
    this.remotePhotoUrls = const [],
    this.moodEmoji,
    this.moodLabel,
    this.note,
    this.weather,
    this.temperature,
    this.location,
    this.aiLine,
    this.topics = const [],
    this.emotion,
    this.importanceScore,
    this.storyArcId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  /// 기기 로컬 경로 — UI는 항상 이 경로 우선 사용
  final List<String> localPhotoPaths;
  /// Firebase Storage URL (testUser/{userId}/{date}/...)
  final List<String> remotePhotoUrls;
  final String? moodEmoji;
  /// 사용자 라벨 (예: 육아텅, 카페집중) — 같은 이모지도 구분
  final String? moodLabel;
  final String? note;
  final String? weather;
  final String? temperature;
  final String? location;
  final String? aiLine;
  /// AI 분류 — 주제 (예: career, job_change)
  final List<String> topics;
  /// AI 분류 — 감정 (positive, negative, neutral, mixed)
  final String? emotion;
  final double? importanceScore;
  /// 연결된 Story Arc id
  final String? storyArcId;
  final DateTime? createdAt;

  String? get coverPhotoPath =>
      localPhotoPaths.isNotEmpty ? localPhotoPaths.first : (remotePhotoUrls.isNotEmpty ? remotePhotoUrls.first : null);

  int get photoCount =>
      localPhotoPaths.isNotEmpty ? localPhotoPaths.length : remotePhotoUrls.length;

  bool get hasPhotos => localPhotoPaths.isNotEmpty || remotePhotoUrls.isNotEmpty;

  /// 실제 날씨 API 값일 때만 true (예전 placeholder 「맑음 · 23°C」 제외)
  bool get hasMeaningfulWeather => !isPlaceholderWeather(weather, temperature);

  String? get weatherDisplayLine {
    if (!hasMeaningfulWeather || weather == null) return null;
    final t = temperature?.trim();
    if (t != null && t.isNotEmpty) return '$weather · $t';
    return weather;
  }

  String get dateKey => dateKeyFrom(date);

  static String dateKeyFrom(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'localPhotoPaths': localPhotoPaths,
        'remotePhotoUrls': remotePhotoUrls,
        'moodEmoji': moodEmoji,
        'moodLabel': moodLabel,
        'note': note,
        'weather': weather,
        'temperature': temperature,
        'location': location,
        'aiLine': aiLine,
        'topics': topics,
        'emotion': emotion,
        'importanceScore': importanceScore,
        'storyArcId': storyArcId,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory DailyEntry.fromJson(Map<String, dynamic> json) {
    var localPaths = _parseStringList(json['localPhotoPaths']);
    final remoteUrls = _parseStringList(json['remotePhotoUrls']);

    // 이전 단일 photoUrl 데이터 호환
    if (localPaths.isEmpty) {
      final legacy = json['photoUrl'] as String?;
      if (legacy != null && legacy.isNotEmpty) {
        localPaths = [legacy];
      }
    }

    return DailyEntry(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      localPhotoPaths: localPaths,
      remotePhotoUrls: remoteUrls,
      moodEmoji: json['moodEmoji'] as String?,
      moodLabel: json['moodLabel'] as String?,
      note: json['note'] as String?,
      weather: json['weather'] as String?,
      temperature: json['temperature'] as String?,
      location: json['location'] as String?,
      aiLine: json['aiLine'] as String?,
      topics: _parseStringList(json['topics']),
      emotion: json['emotion'] as String?,
      importanceScore: (json['importanceScore'] as num?)?.toDouble(),
      storyArcId: json['storyArcId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  /// Firestore 저장용 (로컬 경로 제외)
  Map<String, dynamic> toFirestoreMap() => {
        'userId': userId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'remotePhotoUrls': remotePhotoUrls,
        'moodEmoji': moodEmoji,
        'moodLabel': moodLabel,
        'note': note,
        'weather': weather,
        'temperature': temperature,
        'location': location,
        'aiLine': aiLine,
        'topics': topics,
        'emotion': emotion,
        'importanceScore': importanceScore,
        'storyArcId': storyArcId,
      };

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'localPhotoPaths': localPhotoPaths,
        'remotePhotoUrls': remotePhotoUrls,
        'moodEmoji': moodEmoji,
        'moodLabel': moodLabel,
        'note': note,
        'weather': weather,
        'temperature': temperature,
        'location': location,
        'aiLine': aiLine,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory DailyEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['date'] as Timestamp?;
    final date = ts?.toDate() ?? DateTime.now();
    var remoteUrls = _parseStringList(d['remotePhotoUrls']);
    if (remoteUrls.isEmpty) {
      final legacy = d['photoUrl'] as String?;
      if (legacy != null && legacy.isNotEmpty) {
        remoteUrls = [legacy];
      }
    }
    return DailyEntry(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      date: date,
      localPhotoPaths: const [],
      remotePhotoUrls: remoteUrls,
      moodEmoji: d['moodEmoji'] as String?,
      moodLabel: d['moodLabel'] as String?,
      note: d['note'] as String?,
      weather: d['weather'] as String?,
      temperature: d['temperature'] as String?,
      location: d['location'] as String?,
      aiLine: d['aiLine'] as String?,
      topics: _parseStringList(d['topics']),
      emotion: d['emotion'] as String?,
      importanceScore: (d['importanceScore'] as num?)?.toDouble(),
      storyArcId: d['storyArcId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  DailyEntry copyWith({
    String? id,
    List<String>? localPhotoPaths,
    List<String>? remotePhotoUrls,
    String? moodEmoji,
    String? moodLabel,
    String? note,
    String? weather,
    String? temperature,
    String? location,
    String? aiLine,
    List<String>? topics,
    String? emotion,
    double? importanceScore,
    String? storyArcId,
  }) =>
      DailyEntry(
        id: id ?? this.id,
        userId: userId,
        date: date,
        localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
        remotePhotoUrls: remotePhotoUrls ?? this.remotePhotoUrls,
        moodEmoji: moodEmoji ?? this.moodEmoji,
        moodLabel: moodLabel ?? this.moodLabel,
        note: note ?? this.note,
        weather: weather ?? this.weather,
        temperature: temperature ?? this.temperature,
        location: location ?? this.location,
        aiLine: aiLine ?? this.aiLine,
        topics: topics ?? this.topics,
        emotion: emotion ?? this.emotion,
        importanceScore: importanceScore ?? this.importanceScore,
        storyArcId: storyArcId ?? this.storyArcId,
        createdAt: createdAt,
      );
}
