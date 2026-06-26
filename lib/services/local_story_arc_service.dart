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

/// Story Arc + Mapping — Firestore가 source of truth, SharedPreferences는 오프라인 캐시
class LocalStoryArcService {
  LocalStoryArcService({StoryArcService? cloud}) : _cloud = cloud ?? StoryArcService() {
    _arcsController = StreamController<List<StoryArc>>.broadcast(
      onListen: () {
        if (_cachedArcs != null && _currentUid != null) {
          _arcsController.add(arcsForUser(_currentUid!));
        }
      },
    );
  }

  final StoryArcService _cloud;

  late final StreamController<List<StoryArc>> _arcsController;
  List<StoryArc>? _cachedArcs;
  List<StoryArcMapping>? _cachedMappings;
  MonthlyReview? _cachedReview;
  DailyInsight? _cachedInsight;
  DateTime? _lastDiscoveryAt;
  Set<String> _whisperShownArcIds = {};

  bool _cloudSyncEnabled = false;
  String? _currentUid;

  static const _arcsKey = 'story_arcs';
  static const _mappingsKey = 'story_arc_mappings';
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
      await _applyBundle(uid, remote);
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
        if (remote.isEmpty && (_cachedArcs?.isNotEmpty ?? false)) {
          await _cloud.uploadAll(uid, _localBundle(uid));
        } else {
          await _applyBundle(uid, remote);
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

  MonthlyReview? get monthlyReview => _cachedReview;
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

  Future<void> saveMonthlyReview(MonthlyReview review) async {
    _cachedReview = review;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reviewKey, jsonEncode(review.toJson()));
    await _syncMetaToCloud(monthlyReview: review);
  }

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
        monthlyReview: _cachedReview,
      );

  Future<void> _applyBundle(String uid, StoryArcBundle bundle) async {
    _cachedArcs = bundle.arcs;
    _cachedMappings = bundle.mappings;
    _lastDiscoveryAt = bundle.lastDiscoveryAt;
    _whisperShownArcIds = bundle.whisperShownArcIds;
    _cachedInsight = bundle.dailyInsight;
    _cachedReview = bundle.monthlyReview;
    await _persistArcs();
    await _persistMappings();
    final prefs = await SharedPreferences.getInstance();
    if (bundle.lastDiscoveryAt != null) {
      await prefs.setString(_discoveryKey, bundle.lastDiscoveryAt!.toIso8601String());
    }
    await prefs.setStringList(_whisperKey, _whisperShownArcIds.toList());
    if (bundle.dailyInsight != null) {
      await prefs.setString(_insightKey, jsonEncode(bundle.dailyInsight!.toJson()));
    }
    if (bundle.monthlyReview != null) {
      await prefs.setString(_reviewKey, jsonEncode(bundle.monthlyReview!.toJson()));
    }
    _emit(uid);
  }

  Future<void> _syncArcToCloud(StoryArc arc) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.upsertArc(_currentUid!, arc);
    } catch (e, st) {
      debugPrint('LocalStoryArcService: upsertArc cloud failed — $e\n$st');
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
    MonthlyReview? monthlyReview,
  }) async {
    if (!_cloudSyncEnabled || _currentUid == null) return;
    try {
      await _cloud.saveMeta(
        uid: _currentUid!,
        lastDiscoveryAt: lastDiscoveryAt,
        whisperShownArcIds: whisperShownArcIds,
        dailyInsight: dailyInsight,
        monthlyReview: monthlyReview,
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

    final reviewRaw = prefs.getString(_reviewKey);
    _cachedReview = reviewRaw == null
        ? null
        : MonthlyReview.fromJson(Map<String, dynamic>.from(jsonDecode(reviewRaw) as Map));

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
    } catch (e, st) {
      debugPrint('LocalStoryArcService: ensureUploadedToCloud failed — $e\n$st');
    }
  }

  void dispose() {
    _arcsController.close();
  }
}
