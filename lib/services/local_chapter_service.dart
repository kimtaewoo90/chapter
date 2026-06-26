import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/chapter_builder.dart';
import '../core/utils/chapter_segmenter.dart';
import '../models/chapter_model.dart';
import '../models/daily_entry.dart';

class CompletedChapterDraft {
  const CompletedChapterDraft({
    required this.entries,
    required this.title,
    required this.narrative,
    required this.dateRangeKey,
    this.storyArcId,
    this.category,
  });

  final List<DailyEntry> entries;
  final String title;
  final String narrative;
  final String dateRangeKey;
  final String? storyArcId;
  final String? category;
}

class LocalChapterService {
  LocalChapterService() {
    _chaptersController = StreamController<List<ChapterModel>>.broadcast(
      onListen: () {
        if (_cachedChapters != null) {
          _chaptersController.add(_cachedChapters!);
        }
      },
    );
  }

  late final StreamController<List<ChapterModel>> _chaptersController;
  List<ChapterModel>? _cachedChapters;
  static const _storageKey = 'local_chapters';

  Stream<List<ChapterModel>> watchChapters(String uid) {
    return _chaptersController.stream.map(
      (list) => list.where((c) => c.userId == uid).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate)),
    );
  }

  Future<void> loadChapters(String uid) async {
    await _ensureLoaded();
    _emit(uid);
  }

  /// 완성된 챕터만 저장 (쓰는 중인 구간은 제외)
  Future<void> replaceCompletedChapters(
    String uid,
    List<CompletedChapterDraft> drafts,
  ) async {
    await _ensureLoaded();

    final others = _cachedChapters!.where((c) => c.userId != uid).toList();
    final previous = _cachedChapters!.where((c) => c.userId == uid).toList();
    final prevByKey = {
      for (final c in previous)
        '${DailyEntry.dateKeyFrom(c.startDate)}_${DailyEntry.dateKeyFrom(c.endDate)}': c,
    };

    final next = <ChapterModel>[];
    for (final draft in drafts) {
      final prev = prevByKey[draft.dateRangeKey];
      final segment = ChapterSegment(
        entries: draft.entries,
        isComplete: true,
      );
      next.add(
        ChapterBuilder.fromSegment(
          uid: uid,
          segment: segment,
          title: draft.title,
          narrative: draft.narrative,
          preserveId: prev?.id,
          storyArcId: draft.storyArcId,
          category: draft.category,
        ),
      );
    }

    _cachedChapters = [...others, ...next];
    await _persist();
    _emit(uid);
  }

  /// Firestore에서 불러온 챕터로 로컬 캐시 교체
  Future<void> replaceFromCloud(String uid, List<ChapterModel> cloud) async {
    await _ensureLoaded();
    final others = _cachedChapters!.where((c) => c.userId != uid).toList();
    _cachedChapters = [...others, ...cloud];
    await _persist();
    _emit(uid);
  }

  Future<void> _ensureLoaded() async {
    if (_cachedChapters != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _cachedChapters = [];
      return;
    }
    _cachedChapters = (jsonDecode(raw) as List)
        .map((e) => ChapterModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_cachedChapters!.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  void _emit(String uid) {
    if (!_chaptersController.isClosed) {
      final list = (_cachedChapters ?? [])
          .where((c) => c.userId == uid)
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      _chaptersController.add(list);
    }
  }

  void dispose() {
    _chaptersController.close();
  }
}
