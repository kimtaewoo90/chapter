import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/monthly_review.dart';

/// Firestore: users/{uid}/monthly_reviews/{yyyy-MM} — 월간 리포트 스냅샷
class MonthlyReviewService {
  MonthlyReviewService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _reviews(String uid) =>
      _db.collection('users').doc(uid).collection('monthly_reviews');

  Future<List<MonthlyReview>> fetchAll(String uid) async {
    final snap = await _reviews(uid).orderBy('periodKey', descending: true).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<void> upsert(String uid, MonthlyReview review) async {
    await _reviews(uid).doc(review.periodKey).set(
          _toFirestoreMap(review),
          SetOptions(merge: true),
        );
  }

  Future<void> uploadAll(String uid, List<MonthlyReview> reviews) async {
    if (reviews.isEmpty) return;
    final batch = _db.batch();
    for (final review in reviews) {
      batch.set(
        _reviews(uid).doc(review.periodKey),
        _toFirestoreMap(review),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  MonthlyReview _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final json = Map<String, dynamic>.from(doc.data());
    _normalizeTimestamps(json);
    if ((json['periodKey'] as String?)?.isEmpty ?? true) {
      json['periodKey'] = doc.id;
    }
    return MonthlyReview.fromJson(json);
  }

  void _normalizeTimestamps(Map<String, dynamic> json) {
    for (final key in ['generatedAt', 'revealedAt']) {
      final value = json[key];
      if (value is Timestamp) {
        json[key] = value.toDate().toIso8601String();
      }
    }
  }

  Map<String, dynamic> _toFirestoreMap(MonthlyReview review) {
    final map = review.toJson();
    map['generatedAt'] = Timestamp.fromDate(review.generatedAt);
    if (review.revealedAt != null) {
      map['revealedAt'] = Timestamp.fromDate(review.revealedAt!);
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
