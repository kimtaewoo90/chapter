import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_insight.dart';
import '../models/monthly_review.dart';
import '../models/story_arc.dart';
import '../models/story_arc_mapping.dart';

/// Firestore Story Arc 저장소
/// - users/{uid}/story_arcs/{arcId}
/// - users/{uid}/story_arc_mappings/{entryId}
/// - users/{uid}/story_arc_meta/state
class StoryArcBundle {
  const StoryArcBundle({
    this.arcs = const [],
    this.mappings = const [],
    this.lastDiscoveryAt,
    this.whisperShownArcIds = const {},
    this.dailyInsight,
    this.monthlyReview,
    this.monthlyReviews = const [],
  });

  final List<StoryArc> arcs;
  final List<StoryArcMapping> mappings;
  final DateTime? lastDiscoveryAt;
  final Set<String> whisperShownArcIds;
  final DailyInsight? dailyInsight;
  /// @deprecated — [monthlyReviews] 사용
  final MonthlyReview? monthlyReview;
  final List<MonthlyReview> monthlyReviews;

  bool get isEmpty => arcs.isEmpty && mappings.isEmpty;
}

class StoryArcService {
  StoryArcService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _arcs(String uid) =>
      _db.collection('users').doc(uid).collection('story_arcs');

  CollectionReference<Map<String, dynamic>> _mappings(String uid) =>
      _db.collection('users').doc(uid).collection('story_arc_mappings');

  DocumentReference<Map<String, dynamic>> _meta(String uid) =>
      _db.collection('users').doc(uid).collection('story_arc_meta').doc('state');

  Future<StoryArcBundle> fetchAll(String uid) async {
    final results = await Future.wait([
      _arcs(uid).get(),
      _mappings(uid).get(),
      _meta(uid).get(),
    ]);

    final arcSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final mapSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final metaSnap = results[2] as DocumentSnapshot<Map<String, dynamic>>;

    final arcs = arcSnap.docs.map(StoryArc.fromDoc).toList();
    final mappings = mapSnap.docs.map(StoryArcMapping.fromDoc).toList();

    DateTime? lastDiscoveryAt;
    Set<String> whisperShownArcIds = {};
    DailyInsight? dailyInsight;
    MonthlyReview? monthlyReview;
    var monthlyReviews = <MonthlyReview>[];

    if (metaSnap.exists) {
      final d = metaSnap.data()!;
      final discoveryRaw = d['lastDiscoveryAt'];
      if (discoveryRaw is Timestamp) {
        lastDiscoveryAt = discoveryRaw.toDate();
      }
      whisperShownArcIds = (d['whisperShownArcIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toSet() ??
          {};
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
      if (reviewRaw is Map) {
        monthlyReview = MonthlyReview.fromJson(Map<String, dynamic>.from(reviewRaw));
        if (monthlyReviews.isEmpty && monthlyReview != null) {
          monthlyReviews = [monthlyReview!];
        }
      }
    }

    return StoryArcBundle(
      arcs: arcs,
      mappings: mappings,
      lastDiscoveryAt: lastDiscoveryAt,
      whisperShownArcIds: whisperShownArcIds,
      dailyInsight: dailyInsight,
      monthlyReview: monthlyReview,
      monthlyReviews: monthlyReviews,
    );
  }

  Future<void> upsertArc(String uid, StoryArc arc) async {
    await _arcs(uid).doc(arc.id).set(
          {
            ...arc.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  Future<void> upsertMapping(String uid, StoryArcMapping mapping) async {
    await _mappings(uid).doc(mapping.entryId).set(
          {
            ...mapping.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  Future<void> saveMeta({
    required String uid,
    DateTime? lastDiscoveryAt,
    Set<String>? whisperShownArcIds,
    DailyInsight? dailyInsight,
    MonthlyReview? monthlyReview,
    List<MonthlyReview>? monthlyReviews,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lastDiscoveryAt != null) {
      data['lastDiscoveryAt'] = Timestamp.fromDate(lastDiscoveryAt);
    }
    if (whisperShownArcIds != null) {
      data['whisperShownArcIds'] = whisperShownArcIds.toList();
    }
    if (dailyInsight != null) {
      data['dailyInsight'] = dailyInsight.toJson();
    }
    if (monthlyReviews != null) {
      data['monthlyReviews'] = monthlyReviews.map((r) => r.toJson()).toList();
    } else if (monthlyReview != null) {
      data['monthlyReview'] = monthlyReview.toJson();
    }
    await _meta(uid).set(data, SetOptions(merge: true));
  }

  /// 로컬 → 클라우드 최초 업로드
  Future<void> uploadAll(String uid, StoryArcBundle bundle) async {
    final batch = _db.batch();
    for (final arc in bundle.arcs) {
      batch.set(
        _arcs(uid).doc(arc.id),
        {...arc.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    for (final mapping in bundle.mappings) {
      batch.set(
        _mappings(uid).doc(mapping.entryId),
        {...mapping.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    await saveMeta(
      uid: uid,
      lastDiscoveryAt: bundle.lastDiscoveryAt,
      whisperShownArcIds: bundle.whisperShownArcIds,
      dailyInsight: bundle.dailyInsight,
    );
  }
}
