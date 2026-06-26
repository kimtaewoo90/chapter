import 'package:cloud_firestore/cloud_firestore.dart';

/// 일기 ↔ Story Arc 연결
class StoryArcMapping {
  const StoryArcMapping({
    required this.entryId,
    required this.storyArcId,
    required this.confidence,
  });

  final String entryId;
  final String storyArcId;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'storyArcId': storyArcId,
        'confidence': confidence,
      };

  Map<String, dynamic> toMap() => {
        'entryId': entryId,
        'storyArcId': storyArcId,
        'confidence': confidence,
      };

  factory StoryArcMapping.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return StoryArcMapping(
      entryId: doc.id,
      storyArcId: d['storyArcId'] as String? ?? '',
      confidence: (d['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  factory StoryArcMapping.fromJson(Map<String, dynamic> json) {
    return StoryArcMapping(
      entryId: json['entryId'] as String? ?? '',
      storyArcId: json['storyArcId'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
