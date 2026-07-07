import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/entry_photos.dart';
import '../models/daily_entry.dart';

/// 기기 로컬 DB (SharedPreferences) — 표시는 항상 localPhotoPaths 기준
class LocalEntryService {
  LocalEntryService() {
    _entriesController = StreamController<List<DailyEntry>>.broadcast(
      onListen: () {
        if (_cachedEntries != null) {
          _entriesController.add(_cachedEntries!);
        }
      },
    );
  }

  late final StreamController<List<DailyEntry>> _entriesController;
  List<DailyEntry>? _cachedEntries;
  static const _storageKey = 'local_entries';

  Stream<List<DailyEntry>> watchEntries(String uid) {
    return _entriesController.stream.map(
      (list) => list.where((e) => e.userId == uid).toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  Future<void> loadEntries(String uid) async {
    await _ensureLoaded();
    _emit(uid);
  }

  Future<DailyEntry?> getEntryForDate(String uid, DateTime date) async {
    await _ensureLoaded();
    final day = DateTime(date.year, date.month, date.day);
    for (final e in _cachedEntries!) {
      if (e.userId == uid &&
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day) {
        return e;
      }
    }
    return null;
  }

  Future<String> savePhotoLocal(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${photosDir.path}/$name');
    await file.copy(dest.path);
    return dest.path;
  }

  Future<List<String>> savePhotosLocal(List<File> files) async {
    final paths = <String>[];
    for (final file in files) {
      paths.add(await savePhotoLocal(file));
    }
    return paths;
  }

  Future<DailyEntry> saveEntry({
    required String uid,
    required DateTime date,
    required List<String> localPhotoPaths,
    List<String> remotePhotoUrls = const [],
    String? moodEmoji,
    String? moodLabel,
    String? note,
    String? weather,
    String? temperature,
    String? location,
    String? aiLine,
    List<String>? topics,
    String? emotion,
    double? importanceScore,
    String? storyArcId,
    String? existingId,
  }) async {
    await _ensureLoaded();
    final day = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();

    DailyEntry? existing;
    if (existingId != null) {
      for (final e in _cachedEntries!) {
        if (e.id == existingId) {
          existing = e;
          break;
        }
      }
    }
    existing ??= await getEntryForDate(uid, day);

    if (existing != null) {
      final updated = DailyEntry(
        id: existing.id,
        userId: uid,
        date: day,
        localPhotoPaths: localPhotoPaths,
        remotePhotoUrls: remotePhotoUrls,
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        note: note,
        weather: weather,
        temperature: temperature,
        location: location,
        aiLine: aiLine,
        topics: topics ?? existing.topics,
        emotion: emotion ?? existing.emotion,
        importanceScore: importanceScore ?? existing.importanceScore,
        storyArcId: storyArcId ?? existing.storyArcId,
        createdAt: existing.createdAt ?? now,
      );
      _cachedEntries![_cachedEntries!.indexWhere((e) => e.id == existing!.id)] = updated;
      await _persist();
      _emit(uid);
      return updated;
    }

    final entry = DailyEntry(
      id: const Uuid().v4(),
      userId: uid,
      date: day,
      localPhotoPaths: localPhotoPaths,
      remotePhotoUrls: remotePhotoUrls,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      note: note,
      weather: weather,
      temperature: temperature,
      location: location,
      aiLine: aiLine,
      topics: topics ?? const [],
      emotion: emotion,
      importanceScore: importanceScore,
      storyArcId: storyArcId,
      createdAt: now,
    );
    _cachedEntries!.add(entry);
    await _persist();
    _emit(uid);
    return entry;
  }

  Future<DailyEntry?> getOneYearAgo(String uid, DateTime today) async {
    final past = DateTime(today.year - 1, today.month, today.day);
    return getEntryForDate(uid, past);
  }

  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
  }) async {
    await _ensureLoaded();
    final day = DateTime(date.year, date.month, date.day);
    _cachedEntries!.removeWhere(
      (e) =>
          e.userId == uid &&
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day,
    );
    await _persist();
    _emit(uid);
  }

  Future<DailyEntry> updateEntryAnalysis({
    required String entryId,
    required List<String> topics,
    required String emotion,
    required double importanceScore,
    String? storyArcId,
  }) async {
    await _ensureLoaded();
    final idx = _cachedEntries!.indexWhere((e) => e.id == entryId);
    if (idx < 0) throw StateError('entry not found');

    final existing = _cachedEntries![idx];
    final updated = existing.copyWith(
      topics: topics,
      emotion: emotion,
      importanceScore: importanceScore,
      storyArcId: storyArcId,
    );
    _cachedEntries![idx] = updated;
    await _persist();
    _emit(existing.userId);
    return updated;
  }

  /// Firestore ↔ 로컬 병합 — 로컬 사진 경로 유지, 분석 필드는 DB 우선
  Future<List<DailyEntry>> mergeFromCloud(String uid, List<DailyEntry> cloud) async {
    await _ensureLoaded();
    final localForUser = _cachedEntries!.where((e) => e.userId == uid).toList();
    final localByDateKey = {for (final e in localForUser) e.dateKey: e};

    final merged = <DailyEntry>[];
    final processedDates = <String>{};

    for (final remote in cloud) {
      final key = remote.dateKey;
      processedDates.add(key);
      final local = localByDateKey[key];
      if (local != null) {
        merged.add(
          local.copyWith(
            id: remote.id.isNotEmpty ? remote.id : local.id,
            localPhotoPaths: local.localPhotoPaths,
            remotePhotoUrls: _mergeRemotePhotoUrls(local, remote),
            moodEmoji: local.moodEmoji ?? remote.moodEmoji,
            moodLabel: local.moodLabel ?? remote.moodLabel,
            note: local.note?.trim().isNotEmpty == true ? local.note : remote.note,
            weather: local.weather ?? remote.weather,
            temperature: local.temperature ?? remote.temperature,
            location: local.location ?? remote.location,
            aiLine: local.aiLine?.trim().isNotEmpty == true ? local.aiLine : remote.aiLine,
            topics: local.topics.isNotEmpty ? local.topics : remote.topics,
            emotion: local.emotion ?? remote.emotion,
            importanceScore: local.importanceScore ?? remote.importanceScore,
            storyArcId: local.storyArcId ?? remote.storyArcId,
          ),
        );
      } else {
        merged.add(
          DailyEntry(
            id: remote.id.isNotEmpty ? remote.id : const Uuid().v4(),
            userId: uid,
            date: remote.date,
            localPhotoPaths: const [],
            remotePhotoUrls: remote.remotePhotoUrls,
            moodEmoji: remote.moodEmoji,
            moodLabel: remote.moodLabel,
            note: remote.note,
            weather: remote.weather,
            temperature: remote.temperature,
            location: remote.location,
            aiLine: remote.aiLine,
            topics: remote.topics,
            emotion: remote.emotion,
            importanceScore: remote.importanceScore,
            storyArcId: remote.storyArcId,
            createdAt: remote.createdAt,
          ),
        );
      }
    }

    for (final local in localForUser) {
      if (!processedDates.contains(local.dateKey)) {
        merged.add(local);
      }
    }

    merged.sort((a, b) => b.date.compareTo(a.date));
    _cachedEntries!.removeWhere((e) => e.userId == uid);
    _cachedEntries!.addAll(merged);
    await _persist();
    _emit(uid);
    return merged;
  }

  /// Google 등으로 로그인한 uid의 Firestore 기록을 로컬에 반영 (날짜별 덮어쓰기)
  Future<int> replaceFromCloud(String uid, List<DailyEntry> cloud) async {
    await _ensureLoaded();
    _cachedEntries!.removeWhere((e) => e.userId == uid);
    for (final remote in cloud) {
      _cachedEntries!.add(
        DailyEntry(
          id: remote.id.isNotEmpty ? remote.id : const Uuid().v4(),
          userId: uid,
          date: remote.date,
          localPhotoPaths: const [],
          remotePhotoUrls: remote.remotePhotoUrls,
          moodEmoji: remote.moodEmoji,
          moodLabel: remote.moodLabel,
          note: remote.note,
          weather: remote.weather,
          temperature: remote.temperature,
          location: remote.location,
          aiLine: remote.aiLine,
          topics: remote.topics,
          emotion: remote.emotion,
          importanceScore: remote.importanceScore,
          storyArcId: remote.storyArcId,
          createdAt: remote.createdAt,
        ),
      );
    }
    await _persist();
    _emit(uid);
    return cloud.length;
  }

  Future<void> _ensureLoaded() async {
    if (_cachedEntries != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _cachedEntries = [];
      return;
    }
    _cachedEntries = (jsonDecode(raw) as List)
        .map((e) => DailyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_cachedEntries!.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  void _emit(String uid) {
    if (!_entriesController.isClosed) {
      final list = (_cachedEntries ?? [])
          .where((e) => e.userId == uid)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _entriesController.add(list);
    }
  }

  void dispose() {
    _entriesController.close();
  }
}

List<String> _mergeRemotePhotoUrls(DailyEntry local, DailyEntry remote) {
  final localCount = EntryPhotos.displayUris(
    localPaths: local.localPhotoPaths,
    remoteUrls: local.remotePhotoUrls,
    verifyLocalFiles: false,
  ).length;
  final remoteCount =
      remote.remotePhotoUrls.where((url) => url.isNotEmpty).length;

  if (localCount > remoteCount) return local.remotePhotoUrls;
  if (remoteCount > localCount && remote.remotePhotoUrls.isNotEmpty) {
    return remote.remotePhotoUrls;
  }
  if (local.remotePhotoUrls.isNotEmpty) return local.remotePhotoUrls;
  return remote.remotePhotoUrls;
}
