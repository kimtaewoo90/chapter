import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_insight.dart';
import '../models/monthly_review.dart';

/// Firestore 사용자 메타 — users/{uid}/story_arc_meta/state
/// (일일 인사이트 캐시 · 레거시 월간 리포트 마이그레이션용)
class UserMetaBundle {
  const UserMetaBundle({
    this.dailyInsight,
    this.monthlyReviews = const [],
  });

  final DailyInsight? dailyInsight;
  final List<MonthlyReview> monthlyReviews;

  bool get isEmpty => dailyInsight == null && monthlyReviews.isEmpty;
}

class StoryArcService {
  StoryArcService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _meta(String uid) =>
      _db.collection('users').doc(uid).collection('story_arc_meta').doc('state');

  Future<UserMetaBundle> fetchMeta(String uid) async {
    final metaSnap = await _meta(uid).get();

    DailyInsight? dailyInsight;
    var monthlyReviews = <MonthlyReview>[];

    if (metaSnap.exists) {
      final d = metaSnap.data()!;
      final insightRaw = d['dailyInsight'];
      if (insightRaw is Map) {
        dailyInsight = DailyInsight.fromJson(Map<String, dynamic>.from(insightRaw));
      }
      final reviewsRaw = d['monthlyReviews'];
      if (reviewsRaw is List) {
        monthlyReviews = reviewsRaw
            .map((e) => MonthlyReview.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final reviewRaw = d['monthlyReview'];
      if (reviewRaw is Map && monthlyReviews.isEmpty) {
        monthlyReviews = [
          MonthlyReview.fromJson(Map<String, dynamic>.from(reviewRaw)),
        ];
      }
    }

    return UserMetaBundle(
      dailyInsight: dailyInsight,
      monthlyReviews: monthlyReviews,
    );
  }

  Future<void> saveMeta({
    required String uid,
    DailyInsight? dailyInsight,
    List<MonthlyReview>? monthlyReviews,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (dailyInsight != null) {
      data['dailyInsight'] = dailyInsight.toJson();
    }
    if (monthlyReviews != null) {
      data['monthlyReviews'] = monthlyReviews.map((r) => r.toJson()).toList();
    }
    await _meta(uid).set(data, SetOptions(merge: true));
  }

  Future<void> uploadMeta(String uid, UserMetaBundle bundle) async {
    await saveMeta(
      uid: uid,
      dailyInsight: bundle.dailyInsight,
      monthlyReviews: bundle.monthlyReviews.isEmpty ? null : bundle.monthlyReviews,
    );
  }
}
