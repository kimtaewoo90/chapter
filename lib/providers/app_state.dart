import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/config/ai_config.dart';
import '../core/constants/app_fonts.dart';
import '../core/constants/daily_reminder_defaults.dart';
import '../core/constants/dev_flags.dart';
import '../core/constants/moods.dart';
import '../core/config/weather_config.dart';
import '../models/app_version_gate.dart';
import '../core/constants/diary_limits.dart';
import '../core/utils/entry_photos.dart';
import '../models/daily_entry.dart';
import '../models/daily_insight.dart';
import '../models/monthly_review.dart';
import '../models/record_save_step.dart';
import '../models/today_weather.dart';
import '../models/user_preferences.dart';
import '../core/utils/monthly_review_digest_builder.dart';
import '../core/utils/monthly_review_period.dart';
import '../core/utils/monthly_review_source_hash.dart';
import '../core/utils/entry_diary_ai.dart';
import '../services/ai_journal_service.dart';
import '../services/local_story_arc_service.dart';
import '../services/entry_insights_engine.dart';
import '../services/mood_profile_service.dart';
import '../services/app_version_service.dart';
import '../services/auth_link_exception.dart';
import '../services/auth_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/entry_service.dart';
import '../services/local_entry_service.dart';
import '../services/photo_storage_service.dart';
import '../services/weather_service.dart';

/// 앱 첫 진입 흐름: 버전 게이트 → 스플래시 → 온보딩 → 홈
enum LaunchPhase {
  initializing,
  forceUpdate,
  maintenance,
  splash,
  onboarding,
  home,
}

class AppState extends ChangeNotifier {
  AppState({
    required LocalEntryService entries,
    required LocalStoryArcService storyArcs,
    required PhotoStorageService photos,
    required EntryService cloudEntries,
    AuthService? auth,
    AiJournalService? aiJournal,
    WeatherService? weather,
    DailyReminderService? dailyReminder,
    EntryInsightsEngine? insightsEngine,
    AppVersionService? appVersion,
  })  : _entries = entries,
        _storyArcs = storyArcs,
        _photos = photos,
        _cloudEntries = cloudEntries,
        _auth = auth ?? AuthService(),
        _aiJournal = aiJournal ?? AiJournalService(),
        _weather = weather ?? WeatherService(),
        _dailyReminder = dailyReminder ?? DailyReminderService(),
        _insightsEngine = insightsEngine ??
            EntryInsightsEngine(
              insights: storyArcs,
              ai: aiJournal ?? AiJournalService(),
            ),
        _appVersion = appVersion ?? AppVersionService();

  final LocalEntryService _entries;
  final LocalStoryArcService _storyArcs;
  final PhotoStorageService _photos;
  final EntryService _cloudEntries;
  final AuthService _auth;
  final AiJournalService _aiJournal;
  final WeatherService _weather;
  final DailyReminderService _dailyReminder;
  final EntryInsightsEngine _insightsEngine;
  final AppVersionService _appVersion;

  bool initialized = false;
  LaunchPhase launchPhase = LaunchPhase.initializing;
  AppVersionGateResult? versionGate;
  String appBuildLabel = '';
  bool onboardingComplete = false;
  AppFontId fontId = kDefaultFontId;
  AppFontId diaryFontId = kDefaultDiaryFontId;
  UserPreferences preferences = const UserPreferences();

  List<DailyEntry> allEntries = [];
  List<MoodOption> customMoods = [];
  DailyInsight? latestInsight;
  List<MonthlyReview> archivedMonthlyReviews = [];
  String? pendingMonthlyRevealPeriodKey;
  bool geminiConnected = false;
  String? geminiStatusMessage;
  DailyEntry? todayEntry;
  DailyEntry? memoryEntry;
  TodayWeather? todayWeather;
  bool loadingTodayWeather = false;

  StreamSubscription? _entrySub;
  bool _weatherFetchInFlight = false;
  String? _localUid;
  String? _streamUid;

  /// Firebase 익명 로그인 성공 시에만 true — Firestore rules와 uid 일치
  bool cloudSyncEnabled = false;
  String? lastCloudSyncError;

  bool dailyReminderEnabled = DailyReminderDefaults.enabled;
  int dailyReminderHour = DailyReminderDefaults.hour;
  int dailyReminderMinute = DailyReminderDefaults.minute;
  bool dailyReminderPermissionDenied = false;

  String get currentMonthPeriodKey =>
      MonthlyReviewPeriod.periodKeyFromDate(todayDate);

  List<MonthlyReview> get revealedMonthlyReviews => archivedMonthlyReviews
      .where((r) => r.wasRevealed)
      .toList()
    ..sort((a, b) => b.periodKey.compareTo(a.periodKey));

  MonthlyReview? get pendingMonthlyReveal {
    final key = pendingMonthlyRevealPeriodKey;
    if (key == null) return null;
    return monthlyReviewForPeriod(key);
  }

  MonthlyReview? monthlyReviewForPeriod(String periodKey) {
    for (final r in archivedMonthlyReviews) {
      if (r.periodKey == periodKey) return r;
    }
    return _storyArcs.monthlyReviewForPeriod(periodKey);
  }

  int get daysUntilMonthlyReview =>
      MonthlyReviewPeriod.daysUntilMonthEnd(todayDate);

  DailyEntry? entryForDay(DateTime date) {
    for (final e in allEntries) {
      if (_isSameDay(e.date, date)) return e;
    }
    return null;
  }

  DateTime get todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool isToday(DateTime date) => _isSameDay(date, todayDate);

  String get dailyReminderTimeLabel =>
      _dailyReminder.formatTimeLabel(dailyReminderHour, dailyReminderMinute);

  String? get uid => _localUid;

  /// Firestore rules의 request.auth.uid와 일치할 때만 (주문·클라우드 sync)
  String? get cloudAuthUid => _cloudSyncUid;

  bool get isAnonymousAccount => cloudSyncEnabled && _auth.isAnonymous;

  List<String> get linkedProviders => _auth.linkedProviderLabels;

  int get totalDays => allEntries.length;
  int get totalPhotos => allEntries.fold<int>(0, (sum, e) => sum + e.photoCount);

  double get bookProgress {
    const yearDays = 365.0;
    return (totalDays / yearDays).clamp(0.0, 1.0);
  }

  int get estimatedPages => (totalDays * 1.2).round().clamp(0, 400);

  Map<String, int> get moodDistribution {
    final counts = <String, int>{};
    for (final e in allEntries) {
      final m = e.moodEmoji ?? '😶';
      counts[m] = (counts[m] ?? 0) + 1;
    }
    return counts;
  }

  String get homeHeadline {
    if (totalDays > 0) return '순간을 쌓는 중';
    return 'CHAPTER';
  }

  bool get geminiAiEnabled => AiConfig.isGeminiConfigured && geminiConnected;

  /// Gemini 키 존재 여부 (연결 성공과 별개)
  bool get geminiKeyPresent => AiConfig.isGeminiConfigured;

  List<MoodOption> get personalizedMoods => MoodProfileService.personalized(
        entries: allEntries,
        customMoods: customMoods,
      );

  List<MoodOption> get recentMoods => MoodProfileService.recentFromEntries(allEntries);

  Future<void> addCustomMood(MoodOption mood) async {
    await MoodProfileService.saveCustomMood(mood);
    customMoods = await MoodProfileService.loadCustomMoods();
    notifyListeners();
  }

  /// 백그라운드 1회 — 45분 캐시, 기록 탭 진입 시만 호출 권장
  Future<void> refreshTodayWeatherIfNeeded({bool force = false}) async {
    if (_weatherFetchInFlight) return;
    if (!force &&
        todayWeather != null &&
        todayWeather!.isFresh(WeatherConfig.cacheTtl)) {
      return;
    }

    _weatherFetchInFlight = true;
    final showLoading = todayWeather == null;
    if (showLoading) {
      loadingTodayWeather = true;
      notifyListeners();
    }

    try {
      final fetched = await _weather.fetchCurrentIfNeeded(force: force);
      if (fetched != null) {
        todayWeather = fetched;
      }
    } finally {
      _weatherFetchInFlight = false;
      loadingTodayWeather = false;
      notifyListeners();
    }
  }

  Future<List<MoodOption>> suggestMoodsFromPhotos({
    required List<File> photoFiles,
    String? note,
  }) {
    return _aiJournal.recommendMoods(
      photoFiles: photoFiles,
      pastEntries: allEntries,
      customMoods: customMoods,
      note: note,
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      appBuildLabel = await _appVersion.currentBuildLabel();
    } catch (e, st) {
      debugPrint('PackageInfo skipped: $e\n$st');
    }

    final gate = await _appVersion.evaluate();
    if (gate.isBlocked) {
      versionGate = gate;
      initialized = true;
      launchPhase = gate.blockReason == VersionBlockReason.maintenance
          ? LaunchPhase.maintenance
          : LaunchPhase.forceUpdate;
      notifyListeners();
      return;
    }

    versionGate = null;
    await _completeInitialize(prefs);
  }

  /// 업데이트·점검 화면에서 Remote Config 재확인
  Future<void> retryVersionCheck() async {
    launchPhase = LaunchPhase.initializing;
    notifyListeners();

    final gate = await _appVersion.evaluate(forceFetch: true);
    if (gate.isBlocked) {
      versionGate = gate;
      launchPhase = gate.blockReason == VersionBlockReason.maintenance
          ? LaunchPhase.maintenance
          : LaunchPhase.forceUpdate;
      notifyListeners();
      return;
    }

    versionGate = null;
    final prefs = await SharedPreferences.getInstance();
    await _completeInitialize(prefs);
  }

  Future<void> _completeInitialize(SharedPreferences prefs) async {
    final savedOnboarding = prefs.getBool('onboarding_complete') ?? false;
    onboardingComplete = kPreviewOnboardingOnEveryRestart ? false : savedOnboarding;
    fontId = appFontIdFromKey(prefs.getString('app_font_id'));
    diaryFontId = appFontIdFromKey(prefs.getString('diary_font_id'), fallback: kDefaultDiaryFontId);

    final reminder = await _dailyReminder.loadSettings();
    dailyReminderEnabled = reminder.enabled;
    dailyReminderHour = reminder.hour;
    dailyReminderMinute = reminder.minute;
    dailyReminderPermissionDenied = false;
    try {
      await _syncDailyReminderSchedule();
    } catch (e, st) {
      debugPrint('DailyReminder init skipped: $e\n$st');
    }

    final legacyUid = prefs.getString('local_user_id');
    cloudSyncEnabled = false;
    lastCloudSyncError = null;
    try {
      final user = await _auth.signInAnonymously();
      _localUid = user.uid;
      cloudSyncEnabled = true;
      await prefs.setString('local_user_id', _localUid!);
      if (legacyUid != null && legacyUid != _localUid) {
        await _migrateEntriesUserId(from: legacyUid, to: _localUid!);
      }
    } catch (e, st) {
      debugPrint('Auth sign-in skipped, using local uid: $e\n$st');
      _localUid = legacyUid ?? const Uuid().v4();
      await prefs.setString('local_user_id', _localUid!);
      lastCloudSyncError = _authSetupHint(e);
    }

    final uid = _localUid!;

    _storyArcs.configureCloudSync(enabled: cloudSyncEnabled, uid: uid);

    customMoods = await MoodProfileService.loadCustomMoods();
    await _entries.loadEntries(uid);
    await _storyArcs.load(uid);
    if (cloudSyncEnabled) {
      await _syncEntriesFromCloud(uid);
    }
    _reloadMonthlyReviewArchive();
    latestInsight = _storyArcs.dailyInsight;
    final geminiIssue = AiConfig.geminiConfigIssue;
    if (geminiIssue != null) {
      geminiConnected = false;
      geminiStatusMessage = geminiIssue;
    } else if (AiConfig.isGeminiConfigured) {
      geminiStatusMessage = '키 설정됨 · 탭하여 연결 확인';
    }

    _bindUserStreams(uid);

    initialized = true;
    launchPhase = _resolveLaunchPhase(prefs);
    notifyListeners();
    await checkPendingMonthlyReviews();
  }

  LaunchPhase _resolveLaunchPhase(SharedPreferences prefs) {
    if (kPreviewSplashOnEveryRestart) {
      return LaunchPhase.splash;
    }
    if (!onboardingComplete) {
      return LaunchPhase.onboarding;
    }
    if (prefs.getBool('splash_seen') != true) {
      return LaunchPhase.splash;
    }
    return LaunchPhase.home;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Firestore 쓰기 — auth uid와 대상 uid가 일치할 때만
  bool _canSyncToCloud(String uid) {
    final authUid = _auth.uid;
    if (!cloudSyncEnabled || !_auth.isSignedIn || authUid == null) {
      return false;
    }
    if (authUid != uid || _localUid != uid) {
      return false;
    }
    return true;
  }

  String? get _cloudSyncUid {
    final authUid = _auth.uid;
    if (authUid == null || _localUid != authUid || !cloudSyncEnabled || !_auth.isSignedIn) {
      return null;
    }
    return authUid;
  }

  void _bindUserStreams(String uid) {
    _streamUid = uid;
    _entrySub?.cancel();

    _entrySub = _entries.watchEntries(uid).listen((list) async {
      if (_streamUid != uid || _localUid != uid) return;

      allEntries = list;
      final today = DateTime.now();
      DailyEntry? found;
      for (final e in list) {
        if (_isSameDay(e.date, today)) {
          found = e;
          break;
        }
      }
      todayEntry = found;
      notifyListeners();
      memoryEntry = await _entries.getOneYearAgo(uid, today);
      notifyListeners();
    });
  }

  /// Firestore → 로컬 병합. DB가 비어 있으면 로컬 기록 업로드.
  Future<List<DailyEntry>> _syncEntriesFromCloud(String uid) async {
    if (!_canSyncToCloud(uid)) return allEntries;
    try {
      final cloud = await _cloudEntries.fetchAllEntries(uid);
      if (cloud.isEmpty) {
        if (allEntries.isNotEmpty) {
          await _cloudEntries.uploadAll(uid, allEntries);
        }
        return allEntries;
      }
      return await _entries.mergeFromCloud(uid, cloud);
    } catch (e, st) {
      debugPrint('AppState: sync entries from cloud failed — $e\n$st');
      return allEntries;
    }
  }

  Future<void> completeOnboarding(UserPreferences prefs) async {
    preferences = prefs;
    onboardingComplete = true;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarding_complete', true);
    await sp.setStringList('keywords', prefs.keywords);
    launchPhase = LaunchPhase.home;
    notifyListeners();
  }

  Future<void> setFontId(AppFontId id) async {
    fontId = id;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('app_font_id', id.name);
    notifyListeners();
  }

  Future<void> setDiaryFontId(AppFontId id) async {
    diaryFontId = id;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('diary_font_id', id.name);
    notifyListeners();
  }

  Future<String?> setDailyReminderEnabled(bool enabled) async {
    dailyReminderEnabled = enabled;
    await _dailyReminder.saveSettings(
      enabled: enabled,
      hour: dailyReminderHour,
      minute: dailyReminderMinute,
    );
    return _syncDailyReminderSchedule();
  }

  Future<String?> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    dailyReminderHour = hour;
    dailyReminderMinute = minute;
    await _dailyReminder.saveSettings(
      enabled: dailyReminderEnabled,
      hour: hour,
      minute: minute,
    );
    if (!dailyReminderEnabled) {
      notifyListeners();
      return null;
    }
    return _syncDailyReminderSchedule();
  }

  Future<String?> _syncDailyReminderSchedule() async {
    final ok = await _dailyReminder.applySchedule(
      enabled: dailyReminderEnabled,
      hour: dailyReminderHour,
      minute: dailyReminderMinute,
    );
    dailyReminderPermissionDenied = dailyReminderEnabled && !ok;
    notifyListeners();
    if (dailyReminderPermissionDenied) {
      return '알림 권한이 필요해요. 기기 설정에서 허용해 주세요.';
    }
    return null;
  }

  Future<void> finishSplash() async {
    if (kPreviewOnboardingOnEveryRestart || !onboardingComplete) {
      launchPhase = LaunchPhase.onboarding;
    } else {
      launchPhase = LaunchPhase.home;
    }
    if (!kPreviewSplashOnEveryRestart) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('splash_seen', true);
    }
    notifyListeners();
  }

  Future<DailyEntry> saveTodayEntry({
    required List<File> newPhotoFiles,
    List<String>? keepLocalPaths,
    List<String>? keepRemoteUrls,
    String? moodEmoji,
    String? moodLabel,
    String? note,
    String? weather,
    String? temperature,
    void Function(RecordSaveStep step)? onStep,
  }) {
    return saveEntry(
      date: todayDate,
      newPhotoFiles: newPhotoFiles,
      keepLocalPaths: keepLocalPaths,
      keepRemoteUrls: keepRemoteUrls,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      note: note,
      weather: weather,
      temperature: temperature,
      onStep: onStep,
    );
  }

  Future<DailyEntry> saveEntry({
    required DateTime date,
    required List<File> newPhotoFiles,
    List<String>? keepLocalPaths,
    List<String>? keepRemoteUrls,
    String? moodEmoji,
    String? moodLabel,
    String? note,
    String? weather,
    String? temperature,
    void Function(RecordSaveStep step)? onStep,
  }) async {
    final uid = _localUid!;
    final day = DateTime(date.year, date.month, date.day);
    final editingToday = isToday(day);

    onStep?.call(RecordSaveStep.preparingPhotos);

    final existing = entryForDay(day);
    final previousLocal = existing?.localPhotoPaths ?? const [];

    final ({List<String> localPaths, List<String> remoteUrls}) photoSlots;
    if (keepLocalPaths != null) {
      photoSlots = (
        localPaths: List<String>.from(keepLocalPaths),
        remoteUrls: List<String>.from(
          keepRemoteUrls ?? existing?.remotePhotoUrls ?? const [],
        ),
      );
    } else if (existing != null) {
      photoSlots = EntryPhotos.editSlots(
        localPaths: existing.localPhotoPaths,
        remoteUrls: existing.remotePhotoUrls,
      );
    } else {
      photoSlots = (localPaths: <String>[], remoteUrls: <String>[]);
    }

    var localPaths = List<String>.from(photoSlots.localPaths);
    var remoteUrls = List<String>.from(photoSlots.remoteUrls);
    if (newPhotoFiles.isNotEmpty) {
      localPaths.addAll(await _entries.savePhotosLocal(newPhotoFiles));
    }
    localPaths = await EntryPhotos.persistLocalPaths(
      localPaths: localPaths,
      saveLocal: _entries.savePhotoLocal,
    );
    while (remoteUrls.length < localPaths.length) {
      remoteUrls.add('');
    }
    if (remoteUrls.length > localPaths.length) {
      remoteUrls.removeRange(localPaths.length, remoteUrls.length);
    }

    final compacted = EntryPhotos.compactPhotoSlots(
      localPaths: localPaths,
      remoteUrls: remoteUrls,
    );
    localPaths = compacted.locals;
    remoteUrls = compacted.remotes;

    if (localPaths.length > DiaryLimits.maxPhotosPerEntry) {
      localPaths.removeRange(DiaryLimits.maxPhotosPerEntry, localPaths.length);
      if (remoteUrls.length > localPaths.length) {
        remoteUrls.removeRange(localPaths.length, remoteUrls.length);
      }
    }

    onStep?.call(RecordSaveStep.uploadingPhotos);

    final entryDate = existing?.date ?? day;

    remoteUrls = await _photos.syncRemotePhotoUrls(
      userId: uid,
      localPaths: localPaths,
      existingRemoteUrls: remoteUrls,
      previousLocalPaths: previousLocal,
      date: entryDate,
    );

    final resolvedWeather = weather ??
        (editingToday ? todayWeather?.weather : existing?.weather);
    final resolvedTemp = temperature ??
        (editingToday ? todayWeather?.temperature : existing?.temperature);

    final draft = DailyEntry(
      id: existing?.id ?? '',
      userId: uid,
      date: entryDate,
      localPhotoPaths: localPaths,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      note: note,
      weather: resolvedWeather,
      temperature: resolvedTemp,
    );

    final pastForTone = allEntries.where((e) {
      final d = e.date;
      return d.year != entryDate.year || d.month != entryDate.month || d.day != entryDate.day;
    }).toList();

    String? aiLine;
    if (EntryDiaryAi.shouldGenerateAiDiary(
      note: note,
      hasPhotos: localPaths.isNotEmpty,
    )) {
      onStep?.call(RecordSaveStep.writingLine);
      aiLine = await _aiJournal.generateDailyLine(
        entry: draft,
        pastEntries: pastForTone,
        photoFiles: _photoFilesForAi(localPaths),
      );
    }

    onStep?.call(RecordSaveStep.bindingPage);

    var localSaved = await _entries.saveEntry(
      uid: uid,
      date: entryDate,
      localPhotoPaths: localPaths,
      remotePhotoUrls: remoteUrls,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      note: note,
      weather: resolvedWeather,
      temperature: resolvedTemp,
      aiLine: aiLine,
      existingId: existing?.id,
    );

    onStep?.call(RecordSaveStep.analyzingStory);
    final processResult = await _insightsEngine.processEntrySaved(
      uid: uid,
      entry: localSaved,
      allEntries: [
        ...allEntries.where((e) => e.id != localSaved.id),
        localSaved,
      ],
    );
    localSaved = await _entries.updateEntryAnalysis(
      entryId: localSaved.id,
      topics: processResult.analysis.topics,
      emotion: processResult.analysis.emotion,
      importanceScore: processResult.analysis.importanceScore,
    );
    latestInsight = processResult.insight;
    notifyListeners();

    if (!cloudSyncEnabled || !_auth.isSignedIn) {
      lastCloudSyncError ??= 'Firebase 로그인이 되지 않아 이 기기에만 저장됐어요.';
      notifyListeners();
      return localSaved;
    }

    try {
      final cloud = await _cloudEntries.saveEntry(localSaved);
      final cloudRemotes = cloud.remotePhotoUrls.isNotEmpty
          ? cloud.remotePhotoUrls
          : localSaved.remotePhotoUrls;
      final finalEntry = localSaved.copyWith(
        id: cloud.id,
        remotePhotoUrls: EntryPhotos.alignRemoteUrls(
          localPaths: localSaved.localPhotoPaths,
          remoteUrls: cloudRemotes,
        ),
      );
      localSaved = await _entries.saveEntry(
        uid: uid,
        date: finalEntry.date,
        localPhotoPaths: finalEntry.localPhotoPaths,
        remotePhotoUrls: finalEntry.remotePhotoUrls,
        moodEmoji: finalEntry.moodEmoji,
        moodLabel: finalEntry.moodLabel,
        note: finalEntry.note,
        weather: finalEntry.weather,
        temperature: finalEntry.temperature,
        aiLine: finalEntry.aiLine,
        topics: finalEntry.topics,
        emotion: finalEntry.emotion,
        importanceScore: finalEntry.importanceScore,
        storyArcId: finalEntry.storyArcId,
        existingId: finalEntry.id,
      );
      lastCloudSyncError = null;
      notifyListeners();
      return localSaved;
    } catch (e, st) {
      debugPrint('Firestore save failed (local saved): $e\n$st');
      lastCloudSyncError = e.toString().contains('permission-denied')
          ? 'Firestore 권한 거부 — Firebase 익명 로그인을 켜 주세요.'
          : '클라우드 저장 실패 (이 기기에는 저장됨)';
      notifyListeners();
      return localSaved;
    }
  }

  Future<void> deleteEntry(DateTime date) async {
    final uid = _localUid!;
    final day = DateTime(date.year, date.month, date.day);
    final existing = entryForDay(day);
    if (existing == null) return;

    for (final path in existing.localPhotoPaths) {
      if (path.startsWith('http')) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Local photo delete failed: $e');
      }
    }

    await _entries.deleteEntry(uid: uid, date: day);

    if (cloudSyncEnabled && _auth.isSignedIn) {
      try {
        await _cloudEntries.deleteEntry(uid, day);
        await _photos.deletePhotosForEntry(
          userId: uid,
          date: day,
          remoteUrls: existing.remotePhotoUrls,
        );
        lastCloudSyncError = null;
      } catch (e, st) {
        debugPrint('Cloud entry delete failed (local deleted): $e\n$st');
        lastCloudSyncError = e.toString().contains('permission-denied')
            ? 'Firestore 권한 거부 — 클라우드 삭제 실패 (이 기기에서는 삭제됨)'
            : '클라우드 삭제 실패 (이 기기에서는 삭제됨)';
      }
    }

    notifyListeners();
  }

  /// Firebase Console 설정 후 재시도
  Future<bool> retryCloudAuth() async {
    final user = await _auth.retrySignIn();
    if (user == null) {
      lastCloudSyncError = _authSetupHint(null);
      notifyListeners();
      return false;
    }
    _localUid = user.uid;
    cloudSyncEnabled = true;
    lastCloudSyncError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user_id', _localUid!);
    _storyArcs.configureCloudSync(enabled: true, uid: _localUid!);
    await _entries.loadEntries(_localUid!);
    await _storyArcs.load(_localUid!);
    await _syncEntriesFromCloud(_localUid!);
    notifyListeners();
    return true;
  }

  /// 익명 uid 그대로 — Firestore `users/{uid}` 유지
  Future<String?> linkGoogleAccount() async {
    try {
      final prep = await _ensureReadyForAccountLink();
      if (prep != null) return prep;

      await _auth.linkWithGoogle();
      await _afterAccountLinked();
      return lastCloudSyncError;
    } on AuthLinkException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('linkGoogleAccount: $e');
      return 'Google 연결에 실패했어요.';
    }
  }

  Future<String?> linkAppleAccount() async {
    try {
      final prep = await _ensureReadyForAccountLink();
      if (prep != null) return prep;

      await _auth.linkWithApple();
      await _afterAccountLinked();
      return lastCloudSyncError;
    } on AuthLinkException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('linkAppleAccount: $e');
      return 'Apple 연결에 실패했어요.';
    }
  }

  Future<String?> _ensureReadyForAccountLink() async {
    if (!_auth.isSignedIn || !cloudSyncEnabled) {
      final ok = await retryCloudAuth();
      if (!ok) {
        return lastCloudSyncError ?? 'Firebase 로그인 후 다시 시도해 주세요.';
      }
    }
    if (!_auth.isAnonymous) {
      return '이미 연결된 계정이에요.';
    }
    return null;
  }

  Future<void> _afterAccountLinked() async {
    final uid = _auth.uid;
    if (uid != null) {
      _localUid = uid;
      cloudSyncEnabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_id', uid);
      _storyArcs.configureCloudSync(enabled: true, uid: uid);
      _bindUserStreams(uid);
    }
    await _pushLocalDataToCloud();
    notifyListeners();
  }

  /// 연결 직후 — 로컬 기록·월간 리포트를 Firestore에 업로드
  Future<void> _pushLocalDataToCloud() async {
    final uid = _localUid;
    if (uid == null || !_canSyncToCloud(uid)) return;

    _storyArcs.configureCloudSync(enabled: true, uid: uid);
    try {
      if (allEntries.isNotEmpty) {
        await _cloudEntries.uploadAll(uid, allEntries);
      }
      await _storyArcs.ensureUploadedToCloud(uid);
      lastCloudSyncError = null;
    } catch (e, st) {
      debugPrint('AppState: pushLocalDataToCloud failed — $e\n$st');
      lastCloudSyncError = '백업 업로드 일부 실패 — 네트워크 확인 후 다시 저장해 주세요.';
      notifyListeners();
    }
  }

  /// 다른 기기 — Google로 로그인 후 Firestore 기록을 이 기기로 가져옴
  Future<({String? error, int count})> restoreFromGoogleAccount() async {
    try {
      final user = await _auth.signInWithGoogleForRestore();
      final count = await _applySignedInUser(
        user.uid,
        importFromFirestore: true,
      );
      return (error: null, count: count);
    } on AuthLinkException catch (e) {
      return (error: e.message, count: 0);
    } catch (e, st) {
      debugPrint('restoreFromGoogleAccount: $e\n$st');
      return (error: 'Google 불러오기에 실패했어요.', count: 0);
    }
  }

  Future<({String? error, int count})> restoreFromAppleAccount() async {
    try {
      final user = await _auth.signInWithAppleForRestore();
      final count = await _applySignedInUser(
        user.uid,
        importFromFirestore: true,
      );
      return (error: null, count: count);
    } on AuthLinkException catch (e) {
      return (error: e.message, count: 0);
    } catch (e, st) {
      debugPrint('restoreFromAppleAccount: $e\n$st');
      return (error: 'Apple 불러오기에 실패했어요.', count: 0);
    }
  }

  Future<int> _applySignedInUser(
    String uid, {
    required bool importFromFirestore,
  }) async {
    _localUid = uid;
    cloudSyncEnabled = true;
    lastCloudSyncError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user_id', uid);

    _storyArcs.configureCloudSync(enabled: true, uid: uid);
    _bindUserStreams(uid);

    var imported = 0;
    if (importFromFirestore) {
      try {
        final cloud = await _cloudEntries.fetchAllEntries(uid);
        imported = await _entries.replaceFromCloud(uid, cloud);
        await _storyArcs.load(uid);
      } catch (e, st) {
        debugPrint('Firestore import failed: $e\n$st');
        lastCloudSyncError = '클라우드 불러오기 실패 — 네트워크·로그인을 확인해 주세요.';
        await _entries.loadEntries(uid);
        await _storyArcs.load(uid);
      }
    } else {
      await _entries.loadEntries(uid);
      await _storyArcs.load(uid);
    }

    notifyListeners();
    return imported;
  }

  static String _authSetupHint(Object? error) {
    final code = error is FirebaseAuthException ? error.code : null;
    if (code == 'internal-error') {
      return 'Firebase 익명 로그인 오류 — Console에서 Authentication → 익명 사용 설정을 켜 주세요.';
    }
    return 'Firebase 로그인 실패 — 익명 로그인 설정을 확인해 주세요.';
  }

  Future<void> _migrateEntriesUserId({required String from, required String to}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_entries');
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => DailyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i].userId == from) {
        list[i] = DailyEntry(
          id: list[i].id,
          userId: to,
          date: list[i].date,
          localPhotoPaths: list[i].localPhotoPaths,
          remotePhotoUrls: list[i].remotePhotoUrls,
          moodEmoji: list[i].moodEmoji,
          moodLabel: list[i].moodLabel,
          note: list[i].note,
          weather: list[i].weather,
          temperature: list[i].temperature,
          location: list[i].location,
          aiLine: list[i].aiLine,
          topics: list[i].topics,
          emotion: list[i].emotion,
          importanceScore: list[i].importanceScore,
          storyArcId: list[i].storyArcId,
          createdAt: list[i].createdAt,
        );
        changed = true;
      }
    }
    if (changed) {
      await prefs.setString('local_entries', jsonEncode(list.map((e) => e.toJson()).toList()));
      await _entries.loadEntries(to);
    }
  }

  Future<void> checkGeminiConnection() async {
    final issue = AiConfig.geminiConfigIssue;
    if (issue != null) {
      geminiConnected = false;
      geminiStatusMessage = issue;
      notifyListeners();
      return;
    }

    geminiStatusMessage = '연결 확인 중…';
    notifyListeners();

    final ok = await _aiJournal.pingGemini();
    geminiConnected = ok;
    geminiStatusMessage = ok
        ? '연결됨 · AI 일기·월간 회고 사용 중'
        : (_aiJournal.lastGeminiError ?? 'API 호출 실패 — 키·Generative Language API 활성화 확인');
    notifyListeners();
  }

  Future<MonthlyReview?> refreshMonthlyReview() => syncMonthlyReviewArchive();

  void _reloadMonthlyReviewArchive() {
    archivedMonthlyReviews = _storyArcs.monthlyReviewArchive;
  }

  /// 말일·미생성 월 리포트 생성 및 reveal 대기 설정
  Future<void> checkPendingMonthlyReviews() async {
    final uid = _localUid;
    if (uid == null) return;

    _reloadMonthlyReviewArchive();
    await _backfillSnapshotMetadataOnce();

    final today = todayDate;
    final knownKeys = archivedMonthlyReviews.map((r) => r.periodKey).toSet();
    String? revealCandidate;

    for (final monthStart
        in MonthlyReviewPeriod.monthsSpanningEntries(allEntries, today)) {
      final year = monthStart.year;
      final month = monthStart.month;
      final periodKey = MonthlyReviewPeriod.periodKey(year, month);

      if (!MonthlyReviewPeriod.isEligibleForGeneration(
        year: year,
        month: month,
        today: today,
      )) {
        continue;
      }

      if (knownKeys.contains(periodKey)) {
        final existing = monthlyReviewForPeriod(periodKey);
        if (existing != null && !existing.wasRevealed) {
          revealCandidate = periodKey;
        }
        continue;
      }

      final review = await _insightsEngine.generateMonthlyReviewForPeriod(
        uid: uid,
        year: year,
        month: month,
        allEntries: allEntries,
      );
      if (review != null) {
        knownKeys.add(periodKey);
        revealCandidate = periodKey;
        _reloadMonthlyReviewArchive();
      }
    }

    if (revealCandidate != null) {
      pendingMonthlyRevealPeriodKey = revealCandidate;
      notifyListeners();
    }
  }

  Future<MonthlyReview?> syncMonthlyReviewArchive() async {
    final uid = _localUid;
    if (uid == null) return null;
    if (cloudSyncEnabled) {
      await _storyArcs.refreshFromCloud(uid);
      await _syncEntriesFromCloud(uid);
    }
    _reloadMonthlyReviewArchive();
    await checkPendingMonthlyReviews();
    notifyListeners();
    return pendingMonthlyReveal ??
        (revealedMonthlyReviews.isNotEmpty ? revealedMonthlyReviews.first : null);
  }

  List<DailyEntry> _entriesForMonthlyPeriod(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return [];
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return [];
    return MonthlyReviewPeriod.entriesInMonth(
      allEntries,
      year: year,
      month: month,
    );
  }

  /// 스냅샷 생성 후 해당 월 일기가 바뀌었는지
  bool isMonthlyReviewStale(String periodKey) {
    final review = monthlyReviewForPeriod(periodKey);
    final hash = review?.sourceEntryHash;
    if (review == null || hash == null || hash.isEmpty) return false;
    final window = _entriesForMonthlyPeriod(periodKey);
    if (window.isEmpty) return false;
    return MonthlyReviewSourceHash.compute(window) != hash;
  }

  /// 사용자가 요청할 때만 스냅샷 재생성
  Future<MonthlyReview?> regenerateMonthlyReview(String periodKey) async {
    final uid = _localUid;
    if (uid == null) return null;

    final parts = periodKey.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;

    final review = await _insightsEngine.generateMonthlyReviewForPeriod(
      uid: uid,
      year: year,
      month: month,
      allEntries: allEntries,
    );
    _reloadMonthlyReviewArchive();
    notifyListeners();
    return review;
  }

  /// hash가 없는 기존 리포트에 fingerprint만 1회 보강 (내용은 고정)
  Future<void> _backfillSnapshotMetadataOnce() async {
    for (final review in List<MonthlyReview>.from(archivedMonthlyReviews)) {
      if (review.sourceEntryHash != null && review.sourceEntryHash!.isNotEmpty) {
        continue;
      }

      final window = _entriesForMonthlyPeriod(review.periodKey);
      if (window.length < MonthlyReviewPeriod.minEntriesToGenerate) continue;

      var updated = review;
      if (review.digest == null || !review.digest!.hasFacts) {
        final digest = MonthlyReviewDigestBuilder.build(
          window,
          periodLabel: review.periodLabel,
        );
        updated = review.copyWith(
          digest: digest,
          summary: review.summary.isNotEmpty ? review.summary : digest.factSummary,
        );
      }

      updated = updated.copyWith(
        sourceEntryHash: MonthlyReviewSourceHash.compute(window),
      );
      await _storyArcs.upsertMonthlyReview(updated);
    }
    _reloadMonthlyReviewArchive();
  }

  Future<void> dismissMonthlyReveal() async {
    final key = pendingMonthlyRevealPeriodKey;
    if (key != null) {
      await _storyArcs.markMonthlyReviewRevealed(key);
      _reloadMonthlyReviewArchive();
    }
    pendingMonthlyRevealPeriodKey = null;
    notifyListeners();
  }

  void clearMonthlyReveal() {
    dismissMonthlyReveal();
  }

  List<File> _photoFilesForAi(List<String> localPaths) {
    final files = <File>[];
    for (final path in localPaths) {
      if (path.isEmpty || path.startsWith('http')) continue;
      final f = File(path);
      if (f.existsSync()) files.add(f);
      if (files.length >= 4) break;
    }
    return files;
  }

  @override
  void dispose() {
    _entrySub?.cancel();
    _entries.dispose();
    super.dispose();
  }
}
