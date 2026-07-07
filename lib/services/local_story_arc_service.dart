import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_insight.dart';
import '../models/monthly_review.dart';
import 'story_arc_service.dart';
import 'monthly_review_service.dart';

/// 월간 리포트·일일 인사이트 로컬 캐시 + Firestore 동기화
class LocalStoryArcService {
  LocalStoryArcService({
    StoryArcService? cloud,
    MonthlyReviewService? monthlyReviews,
  })  : _cloud = cloud ?? StoryArcService(),
        _monthlyReviews = monthlyReviews ?? MonthlyReviewService();

  final StoryArcService _cloud;
  final MonthlyReviewService _monthlyReviews;

  List<MonthlyReview> _cachedReviews = [];
  DailyInsight? _cachedInsight;

  bool _cloudSyncEnabled = false;
  String? _currentUid;
  bool _loaded = false;

  static const _reviewsArchiveKey = 'monthly_reviews_archive';
  static const _reviewKey = 'monthly_review';
  static const _insightKey = 'daily_insight';

  void configureCloudSync({required bool enabled, required String uid}) {
    _cloudSyncEnabled = enabled;
    _currentUid = uid;
  }

  Future<void> refreshFromCloud(String uid) async {
    if (!_cloudSyncEnabled) return;
    _currentUid = uid;
    try {
      final remote = await _cloud.fetchMeta(uid);
      final reviewSnapshots = await _monthlyReviews.fetchAll(uid);
      final bundle = _bundleWithReviews(remote, reviewSnapshots);
      await _applyBundle(uid, bundle);
      await _migrateLegacyReviewsToCollection(uid, remote);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: refreshFromCloud failed — $e\n$st');
    }
  }

  Future<void> load(String uid) async {
    _currentUid = uid;
    await _ensureLoaded();

    if (_cloudSyncEnabled) {
      try {
        final remote = await _cloud.fetchMeta(uid);
        final reviewSnapshots = await _monthlyReviews.fetchAll(uid);
        final bundle = _bundleWithReviews(remote, reviewSnapshots);

        if (bundle.isEmpty && _hasLocalData()) {
          await _cloud.uploadMeta(uid, _localBundle());
          await _monthlyReviews.uploadAll(uid, _cachedReviews);
        } else {
          await _applyBundle(uid, bundle);
          await _migrateLegacyReviewsToCollection(uid, remote);
        }
      } catch (e, st) {
        debugPrint('LocalStoryArcService: cloud load failed, using cache — $e\n$st');
      }
    }
  }

  List<MonthlyReview> get monthlyReviewArchive {
    final list = [..._cachedReviews]
      ..sort((a, b) => b.periodKey.compareTo(a.periodKey));
    return list;
  }

  MonthlyReview? monthlyReviewForPeriod(String periodKey) {
    for (final r in _cachedReviews) {
      if (r.periodKey == periodKey) return r;
    }
    return null;
  }

  DailyInsight? get dailyInsight => _cachedInsight;

  Future<void> upsertMonthlyReview(MonthlyReview review) async {
    await _ensureLoaded();
    final idx = _cachedReviews.indexWhere((r) => r.periodKey == review.periodKey);
    if (idx >= 0) {
      _cachedReviews[idx] = review;
    } else {
      _cachedReviews.add(review);
    }
    await _persistReviews();
    await _syncReviewToCloud(review);
  }

  Future<void> markMonthlyReviewRevealed(String periodKey) async {
    await _ensureLoaded();
    final idx = _cachedReviews.indexWhere((r) => r.periodKey == periodKey);
    if (idx < 0) return;
    _cachedReviews[idx] = _cachedReviews[idx].copyWith(revealedAt: DateTime.now());
    await _persistReviews();
    await _syncReviewToCloud(_cachedReviews[idx]);
  }

  Future<void> saveDailyInsight(DailyInsight insight) async {
    _cachedInsight = insight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insightKey, jsonEncode(insight.toJson()));
    await _syncMetaToCloud(dailyInsight: insight);
  }

  UserMetaBundle _localBundle() => UserMetaBundle(
        dailyInsight: _cachedInsight,
        monthlyReviews: _cachedReviews,
      );

  bool _hasLocalData() =>
      _cachedInsight != null || _cachedReviews.isNotEmpty;

  Future<void> _applyBundle(String uid, UserMetaBundle bundle) async {
    await _ensureLoaded();
    _cachedInsight = bundle.dailyInsight;
    if (bundle.monthlyReviews.isNotEmpty) {
      _cachedReviews = _mergeReviewArchives(_cachedReviews, bundle.monthlyReviews);
    }
    await _persistReviews();
    final prefs = await SharedPreferences.getInstance();
    if (bundle.dailyInsight != null) {
      await prefs.setString(_insightKey, jsonEncode(bundle.dailyInsight!.toJson()));
    }
  }

  List<MonthlyReview> _mergeReviewArchives(
    List<MonthlyReview> local,
    List<MonthlyReview> remote,
  ) {
    final byKey = {for (final r in local) r.periodKey: r};
    for (final r in remote) {
      final existing = byKey[r.periodKey];
      if (existing == null) {
        byKey[r.periodKey] = r;
      } else {
        final keepLocal = existing.generatedAt.isAfter(r.generatedAt);
        byKey[r.periodKey] = keepLocal ? existing : r;
        if (existing.wasRevealed && !r.wasRevealed) {
          byKey[r.periodKey] = existing;
        } else if (r.wasRevealed && !existing.wasRevealed) {
          byKey[r.periodKey] = r;
        }
      }
    }
    return byKey.values.toList();
  }

  UserMetaBundle _bundleWithReviews(
    UserMetaBundle bundle,
    List<MonthlyReview> reviewSnapshots,
  ) {
    var reviews = reviewSnapshots;
    if (reviews.isEmpty) {
      reviews = bundle.monthlyReviews;
    } else if (bundle.monthlyReviews.isNotEmpty) {
      reviews = _mergeReviewArchives(reviews, bundle.monthlyReviews);
    }
    return UserMetaBundle(
      dailyInsight: bundle.dailyInsight,
      monthlyReviews: reviews,
    );
  }

  Future<void> _migrateLegacyReviewsToCollection(String uid, UserMetaBundle remote) async {
    final cloudSnapshots = await _monthlyReviews.fetchAll(uid);
    final cloudKeys = cloudSnapshots.map((r) => r.periodKey).toSet();

    final candidates = <MonthlyReview>[...remote.monthlyReviews, ..._cachedReviews];
    final seen = <String>{};

    for (final review in candidates) {
      if (!seen.add(review.periodKey)) continue;
      if (cloudKeys.contains(review.periodKey)) continue;
      try {
        await _monthlyReviews.upsert(uid, review);
      } catch (e, st) {
        debugPrint('LocalStoryArcService: review migration failed — $e\n$st');
      }
    }
  }

  Future<void> _syncReviewToCloud(MonthlyReview review) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _monthlyReviews.upsert(_currentUid!, review);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: monthly review cloud sync failed — $e\n$st');
    }
  }

  Future<void> _syncMetaToCloud({DailyInsight? dailyInsight}) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.saveMeta(
        uid: _currentUid!,
        dailyInsight: dailyInsight,
      );
    } catch (e, st) {
      debugPrint('LocalStoryArcService: saveMeta cloud failed — $e\n$st');
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();

    final reviewArchiveRaw = prefs.getString(_reviewsArchiveKey);
    if (reviewArchiveRaw != null) {
      _cachedReviews = (jsonDecode(reviewArchiveRaw) as List)
          .map((e) => MonthlyReview.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      final legacyRaw = prefs.getString(_reviewKey);
      if (legacyRaw != null) {
        _cachedReviews = [
          MonthlyReview.fromJson(Map<String, dynamic>.from(jsonDecode(legacyRaw) as Map)),
        ];
        await _persistReviews();
        await prefs.remove(_reviewKey);
      }
    }

    final insightRaw = prefs.getString(_insightKey);
    _cachedInsight = insightRaw == null
        ? null
        : DailyInsight.fromJson(Map<String, dynamic>.from(jsonDecode(insightRaw) as Map));
  }

  Future<void> _persistReviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reviewsArchiveKey,
      jsonEncode(_cachedReviews.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> ensureUploadedToCloud(String uid) async {
    if (!_cloudSyncEnabled) return;
    await _ensureLoaded();
    try {
      await _cloud.uploadMeta(uid, _localBundle());
      await _monthlyReviews.uploadAll(uid, _cachedReviews);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: ensureUploadedToCloud failed — $e\n$st');
    }
  }
}
