import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.narrative,
    required this.startDate,
    required this.endDate,
    this.coverPhotoUrl,
    this.representativeMood,
    this.entryCount = 0,
    this.photoCount = 0,
    this.musicCount = 0,
    this.dominantColor,
    this.storyArcId,
    this.category,
  });

  final String id;
  final String userId;
  final String title;
  final String narrative;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverPhotoUrl;
  final String? representativeMood;
  final int entryCount;
  final int photoCount;
  final int musicCount;
  final int? dominantColor;
  final String? storyArcId;
  final String? category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'narrative': narrative,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'coverPhotoUrl': coverPhotoUrl,
        'representativeMood': representativeMood,
        'entryCount': entryCount,
        'photoCount': photoCount,
        'musicCount': musicCount,
        'dominantColor': dominantColor,
        'storyArcId': storyArcId,
        'category': category,
      };

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '무제 챕터',
      narrative: json['narrative'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      representativeMood: json['representativeMood'] as String?,
      entryCount: json['entryCount'] as int? ?? 0,
      photoCount: json['photoCount'] as int? ?? 0,
      musicCount: json['musicCount'] as int? ?? 0,
      dominantColor: json['dominantColor'] as int?,
      storyArcId: json['storyArcId'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'narrative': narrative,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'coverPhotoUrl': coverPhotoUrl,
        'representativeMood': representativeMood,
        'entryCount': entryCount,
        'photoCount': photoCount,
        'musicCount': musicCount,
        'dominantColor': dominantColor,
        'storyArcId': storyArcId,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ChapterModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChapterModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '무제 챕터',
      narrative: d['narrative'] as String? ?? '',
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coverPhotoUrl: d['coverPhotoUrl'] as String?,
      representativeMood: d['representativeMood'] as String?,
      entryCount: d['entryCount'] as int? ?? 0,
      photoCount: d['photoCount'] as int? ?? 0,
      musicCount: d['musicCount'] as int? ?? 0,
      dominantColor: d['dominantColor'] as int?,
      storyArcId: d['storyArcId'] as String?,
      category: d['category'] as String?,
    );
  }
}
