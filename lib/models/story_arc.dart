import 'package:cloud_firestore/cloud_firestore.dart';

import 'story_arc_status.dart';

/// 사용자 삶의 이야기 단위 — UI에서는 「챕터」로 표시
class StoryArc {
  const StoryArc({
    required this.id,
    required this.userId,
    required this.category,
    required this.displayTitle,
    this.description,
    this.confidenceScore = 0.5,
    this.status = StoryArcStatus.seeding,
    this.firstEntryDate,
    this.lastEntryDate,
    this.entryCount = 0,
  });

  final String id;
  final String userId;
  /// 안정 식별자 (예: career_change) — AI 표현이 달라도 동일 주제 유지
  final String category;
  /// 사용자에게 보이는 제목
  final String displayTitle;
  final String? description;
  final double confidenceScore;
  final StoryArcStatus status;
  final DateTime? firstEntryDate;
  final DateTime? lastEntryDate;
  final int entryCount;

  bool get isActive => status.isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'category': category,
        'displayTitle': displayTitle,
        'description': description,
        'confidenceScore': confidenceScore,
        'status': status.name,
        'firstEntryDate': firstEntryDate?.toIso8601String(),
        'lastEntryDate': lastEntryDate?.toIso8601String(),
        'entryCount': entryCount,
      };

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'category': category,
        'displayTitle': displayTitle,
        'description': description,
        'confidenceScore': confidenceScore,
        'status': status.name,
        'firstEntryDate': firstEntryDate != null ? Timestamp.fromDate(firstEntryDate!) : null,
        'lastEntryDate': lastEntryDate != null ? Timestamp.fromDate(lastEntryDate!) : null,
        'entryCount': entryCount,
      };

  factory StoryArc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return StoryArc(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      category: d['category'] as String? ?? 'general',
      displayTitle: d['displayTitle'] as String? ?? '새 이야기',
      description: d['description'] as String?,
      confidenceScore: (d['confidenceScore'] as num?)?.toDouble() ?? 0.5,
      status: StoryArcStatus.fromString(d['status'] as String?),
      firstEntryDate: (d['firstEntryDate'] as Timestamp?)?.toDate(),
      lastEntryDate: (d['lastEntryDate'] as Timestamp?)?.toDate(),
      entryCount: d['entryCount'] as int? ?? 0,
    );
  }

  factory StoryArc.fromJson(Map<String, dynamic> json) {
    return StoryArc(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      displayTitle: json['displayTitle'] as String? ?? '새 이야기',
      description: json['description'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.5,
      status: StoryArcStatus.fromString(json['status'] as String?),
      firstEntryDate: json['firstEntryDate'] != null
          ? DateTime.tryParse(json['firstEntryDate'] as String)
          : null,
      lastEntryDate: json['lastEntryDate'] != null
          ? DateTime.tryParse(json['lastEntryDate'] as String)
          : null,
      entryCount: json['entryCount'] as int? ?? 0,
    );
  }

  StoryArc copyWith({
    String? category,
    String? displayTitle,
    String? description,
    double? confidenceScore,
    StoryArcStatus? status,
    DateTime? firstEntryDate,
    DateTime? lastEntryDate,
    int? entryCount,
  }) =>
      StoryArc(
        id: id,
        userId: userId,
        category: category ?? this.category,
        displayTitle: displayTitle ?? this.displayTitle,
        description: description ?? this.description,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        status: status ?? this.status,
        firstEntryDate: firstEntryDate ?? this.firstEntryDate,
        lastEntryDate: lastEntryDate ?? this.lastEntryDate,
        entryCount: entryCount ?? this.entryCount,
      );
}
