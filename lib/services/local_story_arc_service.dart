import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/daily_insight.dart';
import '../models/monthly_review.dart';
import '../models/story_arc.dart';
import '../models/story_arc_mapping.dart';
import '../models/story_arc_status.dart';
import 'story_arc_service.dart';
import 'monthly_review_service.dart';

/// Story Arc + Mapping — Firestore가 source of truth, SharedPreferences는 오프라인 캐시
class LocalStoryArcService {
  LocalStoryArcService({
    StoryArcService? cloud,
    MonthlyReviewService? monthlyReviews,
  })  : _cloud = cloud ?? StoryArcService(),
        _monthlyReviews = monthlyReviews ?? MonthlyReviewService() {
    _arcsController = StreamController<List<StoryArc>>.broadcast(
      onListen: () {
        if (_cachedArcs != null && _currentUid != null) {
          _arcsController.add(arcsForUser(_currentUid!));
        }
      },
    );
  }

  final StoryArcService _cloud;
  final MonthlyReviewService _monthlyReviews;

  late final StreamController<List<StoryArc>> _arcsController;
  List<StoryArc>? _cachedArcs;
  List<StoryArcMapping>? _cachedMappings;
  List<MonthlyReview> _cachedReviews = [];
  DailyInsight? _cachedInsight;
  DateTime? _lastDiscoveryAt;
  Set<String> _whisperShownArcIds = {};

  bool _cloudSyncEnabled = false;
  String? _currentUid;

  static const _arcsKey = 'story_arcs';
  static const _mappingsKey = 'story_arc_mappings';
  static const _reviewsArchiveKey = 'monthly_reviews_archive';
  static const _reviewKey = 'monthly_review';
  static const _insightKey = 'daily_insight';
  static const _discoveryKey = 'story_arc_last_discovery';
  static const _whisperKey = 'chapter_whisper_shown';

  void configureCloudSync({required bool enabled, required String uid}) {
    _cloudSyncEnabled = enabled;
    _currentUid = uid;
  }

  Stream<List<StoryArc>> watchArcs(String uid) {
    return _arcsController.stream.map(
      (list) => list.where((a) => a.userId == uid).toList()
        ..sort((a, b) => (b.lastEntryDate ?? DateTime(2000)).compareTo(a.lastEntryDate ?? DateTime(2000))),
    );
  }

  /// Firestore → 캐시 (분석 전 호출)
  Future<void> refreshFromCloud(String uid) async {
    if (!_cloudSyncEnabled) return;
    _currentUid = uid;
    try {
      final remote = await _cloud.fetchAll(uid);
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
        final remote = await _cloud.fetchAll(uid);
        final reviewSnapshots = await _monthlyReviews.fetchAll(uid);
        final bundle = _bundleWithReviews(remote, reviewSnapshots);

        if (bundle.isEmpty && (_cachedArcs?.isNotEmpty ?? false)) {
          await _cloud.uploadAll(uid, _localBundle(uid));
          await _monthlyReviews.uploadAll(uid, _cachedReviews);
        } else {
          await _applyBundle(uid, bundle);
          await _migrateLegacyReviewsToCollection(uid, remote);
        }
      } catch (e, st) {
        debugPrint('LocalStoryArcService: cloud load failed, using cache — $e\n$st');
        _emit(uid);
      }
      return;
    }

    _emit(uid);
  }

  List<StoryArc> arcsForUser(String uid) {
    return (_cachedArcs ?? [])
        .where((a) => a.userId == uid)
        .toList()
      ..sort((a, b) => (b.lastEntryDate ?? DateTime(2000)).compareTo(a.lastEntryDate ?? DateTime(2000)));
  }

  List<StoryArc> activeArcs(String uid) =>
      arcsForUser(uid).where((a) => a.isActive).toList();

  StoryArc? arcById(String id) {
    for (final a in _cachedArcs ?? []) {
      if (a.id == id) return a;
    }
    return null;
  }

  StoryArcMapping? mappingForEntry(String entryId) {
    for (final m in _cachedMappings ?? []) {
      if (m.entryId == entryId) return m;
    }
    return null;
  }

  List<String> entryIdsForArc(String arcId) {
    return (_cachedMappings ?? [])
        .where((m) => m.storyArcId == arcId)
        .map((m) => m.entryId)
        .toList();
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

  /// @deprecated — [monthlyReviewArchive] 사용
  MonthlyReview? get monthlyReview =>
      _cachedReviews.isEmpty ? null : monthlyReviewArchive.first;

  DailyInsight? get dailyInsight => _cachedInsight;
  DateTime? get lastDiscoveryAt => _lastDiscoveryAt;

  Future<StoryArc> upsertArc(StoryArc arc) async {
    await _ensureLoaded();
    final idx = _cachedArcs!.indexWhere((a) => a.id == arc.id);
    if (idx >= 0) {
      _cachedArcs![idx] = arc;
    } else {
      _cachedArcs!.add(arc);
    }
    await _persistArcs();
    _emit(arc.userId);
    await _syncArcToCloud(arc);
    return arc;
  }

  Future<void> upsertMapping(StoryArcMapping mapping) async {
    await _ensureLoaded();
    _cachedMappings!.removeWhere((m) => m.entryId == mapping.entryId);
    _cachedMappings!.add(mapping);
    await _persistMappings();
    await _syncMappingToCloud(mapping);
  }

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

  /// @deprecated — [upsertMonthlyReview] 사용
  Future<void> saveMonthlyReview(MonthlyReview review) =>
      upsertMonthlyReview(review);

  Future<void> saveDailyInsight(DailyInsight insight) async {
    _cachedInsight = insight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insightKey, jsonEncode(insight.toJson()));
    await _syncMetaToCloud(dailyInsight: insight);
  }

  Future<void> markDiscoveryRun() async {
    _lastDiscoveryAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_discoveryKey, _lastDiscoveryAt!.toIso8601String());
    await _syncMetaToCloud(lastDiscoveryAt: _lastDiscoveryAt);
  }

  Future<void> markWhisperShown(String arcId) async {
    await _ensureLoaded();
    _whisperShownArcIds.add(arcId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_whisperKey, _whisperShownArcIds.toList());
    await _syncMetaToCloud(whisperShownArcIds: _whisperShownArcIds);
  }

  bool whisperWasShown(String arcId) => _whisperShownArcIds.contains(arcId);

  Future<void> remapEntryToArc({
    required String entryId,
    required String storyArcId,
    double confidence = 0.5,
  }) async {
    await upsertMapping(
      StoryArcMapping(entryId: entryId, storyArcId: storyArcId, confidence: confidence),
    );
  }

  StoryArc createArc({
    required String userId,
    required String category,
    required String displayTitle,
    String? description,
    double confidence = 0.5,
    StoryArcStatus status = StoryArcStatus.seeding,
  }) {
    return StoryArc(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      displayTitle: displayTitle,
      description: description,
      confidenceScore: confidence,
      status: status,
    );
  }

  StoryArcBundle _localBundle(String uid) => StoryArcBundle(
        arcs: arcsForUser(uid),
        mappings: (_cachedMappings ?? []).where((m) {
          final arcIds = arcsForUser(uid).map((a) => a.id).toSet();
          return arcIds.contains(m.storyArcId);
        }).toList(),
        lastDiscoveryAt: _lastDiscoveryAt,
        whisperShownArcIds: _whisperShownArcIds,
        dailyInsight: _cachedInsight,
        monthlyReviews: _cachedReviews,
      );

  Future<void> _applyBundle(String uid, StoryArcBundle bundle) async {
    await _ensureLoaded();
    _cachedArcs = bundle.arcs;
    _cachedMappings = bundle.mappings;
    _lastDiscoveryAt = bundle.lastDiscoveryAt;
    _whisperShownArcIds = bundle.whisperShownArcIds;
    _cachedInsight = bundle.dailyInsight;
    if (bundle.monthlyReviews.isNotEmpty) {
      _cachedReviews = _mergeReviewArchives(_cachedReviews, bundle.monthlyReviews);
    } else if (bundle.monthlyReview != null) {
      _cachedReviews = _mergeReviewArchives(_cachedReviews, [bundle.monthlyReview!]);
    }
    await _persistArcs();
    await _persistMappings();
    await _persistReviews();
    final prefs = await SharedPreferences.getInstance();
    if (bundle.lastDiscoveryAt != null) {
      await prefs.setString(_discoveryKey, bundle.lastDiscoveryAt!.toIso8601String());
    }
    await prefs.setStringList(_whisperKey, _whisperShownArcIds.toList());
    if (bundle.dailyInsight != null) {
      await prefs.setString(_insightKey, jsonEncode(bundle.dailyInsight!.toJson()));
    }
    _emit(uid);
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

  Future<void> _syncArcToCloud(StoryArc arc) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.upsertArc(_currentUid!, arc);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: upsertArc cloud failed — $e\n$st');
    }
  }

  StoryArcBundle _bundleWithReviews(
    StoryArcBundle bundle,
    List<MonthlyReview> reviewSnapshots,
  ) {
    var reviews = reviewSnapshots;
    if (reviews.isEmpty) {
      if (bundle.monthlyReviews.isNotEmpty) {
        reviews = bundle.monthlyReviews;
      } else if (bundle.monthlyReview != null) {
        reviews = [bundle.monthlyReview!];
      }
    } else if (bundle.monthlyReviews.isNotEmpty) {
      reviews = _mergeReviewArchives(reviews, bundle.monthlyReviews);
    }
    return StoryArcBundle(
      arcs: bundle.arcs,
      mappings: bundle.mappings,
      lastDiscoveryAt: bundle.lastDiscoveryAt,
      whisperShownArcIds: bundle.whisperShownArcIds,
      dailyInsight: bundle.dailyInsight,
      monthlyReviews: reviews,
    );
  }

  Future<void> _migrateLegacyReviewsToCollection(String uid, StoryArcBundle remote) async {
    final cloudSnapshots = await _monthlyReviews.fetchAll(uid);
    final cloudKeys = cloudSnapshots.map((r) => r.periodKey).toSet();

    final legacy = remote.monthlyReviews.isNotEmpty
        ? remote.monthlyReviews
        : (remote.monthlyReview != null ? [remote.monthlyReview!] : <MonthlyReview>[]);

    final candidates = <MonthlyReview>[...legacy, ..._cachedReviews];
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

  Future<void> _syncMappingToCloud(StoryArcMapping mapping) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.upsertMapping(_currentUid!, mapping);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: upsertMapping cloud failed — $e\n$st');
    }
  }

  Future<void> _syncMetaToCloud({
    DateTime? lastDiscoveryAt,
    Set<String>? whisperShownArcIds,
    DailyInsight? dailyInsight,
  }) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.saveMeta(
        uid: _currentUid!,
        lastDiscoveryAt: lastDiscoveryAt,
        whisperShownArcIds: whisperShownArcIds,
        dailyInsight: dailyInsight,
      );
    } catch (e, st) {
      debugPrint('LocalStoryArcService: saveMeta cloud failed — $e\n$st');
    }
  }

  Future<void> _ensureLoaded() async {
    if (_cachedArcs != null) return;
    final prefs = await SharedPreferences.getInstance();

    final arcsRaw = prefs.getString(_arcsKey);
    _cachedArcs = arcsRaw == null
        ? []
        : (jsonDecode(arcsRaw) as List)
            .map((e) => StoryArc.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

    final mapRaw = prefs.getString(_mappingsKey);
    _cachedMappings = mapRaw == null
        ? []
        : (jsonDecode(mapRaw) as List)
            .map((e) => StoryArcMapping.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

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

    final discoveryRaw = prefs.getString(_discoveryKey);
    _lastDiscoveryAt = discoveryRaw != null ? DateTime.tryParse(discoveryRaw) : null;

    _whisperShownArcIds = (prefs.getStringList(_whisperKey) ?? []).toSet();
  }

  Future<void> _persistArcs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_arcsKey, jsonEncode(_cachedArcs!.map((a) => a.toJson()).toList()));
  }

  Future<void> _persistMappings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mappingsKey, jsonEncode(_cachedMappings!.map((m) => m.toJson()).toList()));
  }

  Future<void> _persistReviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reviewsArchiveKey,
      jsonEncode(_cachedReviews.map((r) => r.toJson()).toList()),
    );
  }

  void _emit(String uid) {
    if (!_arcsController.isClosed) {
      _arcsController.add(arcsForUser(uid));
    }
  }

  Future<void> ensureUploadedToCloud(String uid) async {
    if (!_cloudSyncEnabled) return;
    await _ensureLoaded();
    try {
      await _cloud.uploadAll(uid, _localBundle(uid));
      await _monthlyReviews.uploadAll(uid, _cachedReviews);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: ensureUploadedToCloud failed — $e\n$st');
    }
  }

  void dispose() {
    _arcsController.close();
  }
}
