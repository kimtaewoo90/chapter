import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

import '../core/config/ai_config.dart';
import '../core/constants/moods.dart';
import '../core/utils/ai_narrative.dart';
import '../core/utils/chapter_open_pool.dart';
import '../core/utils/entry_diary_ai.dart';
import '../models/daily_entry.dart';
import '../models/journal_analysis.dart';
import '../models/monthly_review.dart';
import '../models/story_arc.dart';
import '../models/story_arc_ai_results.dart';
import 'mood_profile_service.dart';

/// 일기 AI — Gemini Structured JSON + Story Arc 분류 (실패 시 규칙 폴백)
class AiJournalService {
  String? lastGeminiError;

  /// 앱 시작·설정 화면에서 연결 확인
  Future<bool> pingGemini() async {
    if (!AiConfig.isGeminiConfigured) {
      lastGeminiError = AiConfig.geminiConfigIssue;
      return false;
    }

    try {
      final model = _model(maxOutputTokens: 16, temperature: 0);
      await model.generateContent([Content.text('ping')]);
      lastGeminiError = null;
      return true;
    } catch (e, st) {
      lastGeminiError = _humanizeGeminiError(e);
      debugPrint('AiJournalService: ping failed — $e\n$st');
      return false;
    }
  }

  static String _humanizeGeminiError(Object e) {
    final msg = e.toString();
    if (msg.contains('429') || msg.contains('RESOURCE_EXHAUSTED') || msg.contains('prepayment credits')) {
      return 'Gemini 크레딧이 소진됐어요. AI Studio → Billing에서 충전해 주세요.';
    }
    if (msg.contains('403') || msg.contains('PERMISSION_DENIED')) {
      return 'API 키가 거부됐어요. 키·Generative Language API 활성화를 확인해 주세요.';
    }
    if (msg.contains('401') || msg.contains('API_KEY_INVALID')) {
      return 'API 키가 유효하지 않아요. AI Studio에서 새 키를 발급해 주세요.';
    }
    return msg.length > 120 ? '${msg.substring(0, 117)}…' : msg;
  }

  /// Story Memory Layer — 일기 분류 (topics, emotion, importance)
  Future<JournalAnalysis?> analyzeJournal({
    required DailyEntry entry,
    required List<StoryArc> currentArcs,
    required List<String> recentTopics,
  }) async {
    if (!AiConfig.isGeminiConfigured) return null;

    try {
      final model = _model(maxOutputTokens: 180, temperature: 0.35);
      final prompt = _buildJournalAnalysisPrompt(
        entry: entry,
        currentArcs: currentArcs,
        recentTopics: recentTopics,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseJournalAnalysis(response.text ?? '');
    } catch (e, st) {
      debugPrint('AiJournalService: analyzeJournal failed — $e\n$st');
      return null;
    }
  }

  /// 기존 Story Arc에 매칭
  Future<StoryArcMatchResult?> matchStoryArc({
    required DailyEntry entry,
    required JournalAnalysis analysis,
    required List<StoryArc> currentArcs,
  }) async {
    if (!AiConfig.isGeminiConfigured || currentArcs.isEmpty) return null;

    try {
      final model = _model(maxOutputTokens: 160, temperature: 0.3);
      final prompt = _buildStoryArcMatchPrompt(
        entry: entry,
        analysis: analysis,
        currentArcs: currentArcs,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseStoryArcMatch(response.text ?? '', currentArcs);
    } catch (e, st) {
      debugPrint('AiJournalService: matchStoryArc failed — $e\n$st');
      return null;
    }
  }

  /// 최근 30일 — 신규 Story Arc 발견
  Future<List<NewStoryArcCandidate>?> discoverNewStoryArcs({
    required List<DailyEntry> entries,
    required List<StoryArc> existingArcs,
  }) async {
    if (!AiConfig.isGeminiConfigured || entries.length < 5) return null;

    try {
      final model = _model(maxOutputTokens: 280, temperature: 0.4);
      final prompt = _buildDiscoveryPrompt(entries: entries, existingArcs: existingArcs);
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseDiscovery(response.text ?? '');
    } catch (e, st) {
      debugPrint('AiJournalService: discoverNewStoryArcs failed — $e\n$st');
      return null;
    }
  }

  /// 월간 리포트
  Future<MonthlyReview?> generateMonthlyReview({
    required List<DailyEntry> entries,
    required List<StoryArc> storyArcs,
  }) async {
    if (!AiConfig.isGeminiConfigured || entries.length < 3) return null;

    try {
      final model = _model(maxOutputTokens: 400, temperature: 0.55);
      final prompt = _buildMonthlyReviewPrompt(entries: entries, storyArcs: storyArcs);
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseMonthlyReview(response.text ?? '');
    } catch (e, st) {
      debugPrint('AiJournalService: generateMonthlyReview failed — $e\n$st');
      return null;
    }
  }

  /// Daily Insight — 한 줄 인사이트
  Future<String?> generateDailyInsight({
    required DailyEntry entry,
    required JournalAnalysis analysis,
    StoryArc? matchedArc,
  }) async {
    if (!AiConfig.isGeminiConfigured) return null;

    try {
      final model = _model(maxOutputTokens: 80, temperature: 0.6);
      final arcLine = matchedArc != null
          ? '연결된 Story Arc: ${matchedArc.displayTitle} (${matchedArc.category})'
          : '아직 연결된 Story Arc 없음';
      final prompt = '''
당신은 일기 앱 CHAPTER의 이야기 발견 도우미입니다. 생성형 작가가 아니라 **분류·연결**만 합니다.

## 오늘 기록
${_entrySummaryLine(entry)}

## 분류
- topics: ${analysis.topics.join(', ')}
- emotion: ${analysis.emotion}
- importance: ${analysis.importanceScore.toStringAsFixed(2)}

## $arcLine

## 할 일
사용자에게 보여줄 **Daily Insight 1문장**(60자 이내). 따뜻하고 구체적으로, 클리셰 금지.
본문만 출력.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) return _cleanModelOutput(text);
    } catch (e, st) {
      debugPrint('AiJournalService: generateDailyInsight failed — $e\n$st');
    }
    return null;
  }

  String _buildJournalAnalysisPrompt({
    required DailyEntry entry,
    required List<StoryArc> currentArcs,
    required List<String> recentTopics,
  }) {
    final arcsBlock = currentArcs.isEmpty
        ? '(없음)'
        : currentArcs
            .map((a) => '- id:${a.id} category:${a.category} title:${a.displayTitle} status:${a.status.name}')
            .join('\n');
    final topicsBlock = recentTopics.isEmpty ? '(없음)' : recentTopics.join(', ');

    return '''
당신은 일기 **분류기**입니다. 창작하지 마세요.

## Story Memory
Current Story Arcs:
$arcsBlock

Recent Topics: $topicsBlock

## New Journal
${_entrySummaryLine(entry)}

## 출력 (JSON만)
{
  "topics": ["career", "job_change"],
  "emotion": "negative",
  "importance_score": 0.74
}

## 규칙
- topics: 영문 snake_case, 1~3개 (career_change, health_recovery, relationship, startup, travel, study, daily_life 등)
- emotion: positive | negative | neutral | mixed
- importance_score: 0.0~1.0
''';
  }

  String _buildStoryArcMatchPrompt({
    required DailyEntry entry,
    required JournalAnalysis analysis,
    required List<StoryArc> currentArcs,
  }) {
    final arcsBlock = currentArcs
        .map((a) => '- id:${a.id} category:${a.category} title:${a.displayTitle}')
        .join('\n');

    return '''
당신은 일기와 Story Arc **연결** 판단기입니다.

## Current Story Arcs
$arcsBlock

## New Journal
${_entrySummaryLine(entry)}

## Analysis
topics: ${analysis.topics.join(', ')}
emotion: ${analysis.emotion}

## 출력 (JSON만)
{
  "story_arc_id": "기존 id 또는 null",
  "confidence": 0.92,
  "new_category": "career_change 또는 null",
  "new_display_title": "새 arc일 때만 한국어 제목",
  "new_description": "선택"
}

## 규칙
- 기존 arc와 같은 주제면 story_arc_id + confidence
- 완전히 새 주제면 story_arc_id null + new_category + new_display_title
- category는 snake_case, display_title은 2~14자 한국어
''';
  }

  String _buildDiscoveryPrompt({
    required List<DailyEntry> entries,
    required List<StoryArc> existingArcs,
  }) {
    final lines = entries.take(20).map(_entrySummaryLine).join('\n');
    final existing = existingArcs
        .map((a) => '- ${a.category}: ${a.displayTitle}')
        .join('\n');

    return '''
최근 ${entries.length}개 일기에서 **새 Story Arc** 후보를 찾으세요.

## 기존 Arc (중복 제외)
${existing.isEmpty ? '(없음)' : existing}

## 최근 일기
$lines

## 조건
- 동일 주제 반복, 관련 일기 5개 이상, 7일 이상 지속 느낌

## 출력 (JSON 배열만)
[
  {
    "new_story_detected": true,
    "category": "startup",
    "title": "창업을 고민하기 시작하다",
    "confidence": 0.81
  }
]

없으면 빈 배열 [].
''';
  }

  String _buildMonthlyReviewPrompt({
    required List<DailyEntry> entries,
    required List<StoryArc> storyArcs,
  }) {
    final lines = entries.take(25).map(_entrySummaryLine).join('\n');
    final arcs = storyArcs.map((a) => '${a.displayTitle} (${a.status.label})').join(', ');

    return '''
최근 ${entries.length}일 일기 + Story Arc를 바탕으로 월간 리포트 JSON을 만드세요.

## Story Arcs
${arcs.isEmpty ? '(없음)' : arcs}

## 일기
$lines

## 출력 (JSON만)
{
  "top_topics": ["주제1", "주제2"],
  "summary": "2~3문장 요약",
  "growth": "성장 포인트 1~2문장",
  "emotion_trend": "감정 변화 한 줄",
  "chapter_changes": ["완성·전환된 챕터 제목"]
}
''';
  }

  String _entrySummaryLine(DailyEntry e) {
    final parts = <String>[
      '${e.date.month}/${e.date.day}',
      if (e.moodLabel != null) '무드:${e.moodLabel}',
      if (e.moodEmoji != null) e.moodEmoji!,
      if (e.note != null && e.note!.trim().isNotEmpty) e.note!.trim(),
      if (e.aiLine != null && e.aiLine!.trim().isNotEmpty) e.aiLine!.trim(),
    ];
    return parts.join(' ');
  }

  JournalAnalysis? _parseJournalAnalysis(String raw) {
    final map = _extractJsonMap(raw);
    if (map == null) return null;
    return JournalAnalysis(
      topics: (map['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const ['daily_life'],
      emotion: map['emotion'] as String? ?? 'neutral',
      importanceScore: (map['importance_score'] as num?)?.toDouble() ??
          (map['importanceScore'] as num?)?.toDouble() ??
          0.5,
    );
  }

  StoryArcMatchResult? _parseStoryArcMatch(String raw, List<StoryArc> arcs) {
    final map = _extractJsonMap(raw);
    if (map == null) return null;

    final id = map['story_arc_id'] as String?;
    final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.5;

    if (id != null && id.isNotEmpty && arcs.any((a) => a.id == id)) {
      return StoryArcMatchResult(storyArcId: id, confidence: confidence);
    }

    final category = map['new_category'] as String?;
    if (category != null && category.isNotEmpty) {
      return StoryArcMatchResult(
        storyArcId: null,
        confidence: confidence,
        newCategory: category,
        newDisplayTitle: map['new_display_title'] as String?,
        newDescription: map['new_description'] as String?,
      );
    }

    return StoryArcMatchResult(storyArcId: null, confidence: confidence);
  }

  List<NewStoryArcCandidate>? _parseDiscovery(String raw) {
    var s = raw.trim();
    if (s.contains('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      s = s.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start < 0 || end <= start) return [];

    try {
      final list = jsonDecode(s.substring(start, end + 1)) as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return NewStoryArcCandidate(
          newStoryDetected: m['new_story_detected'] == true,
          category: m['category'] as String? ?? 'daily_life',
          title: m['title'] as String? ?? '새 이야기',
          confidence: (m['confidence'] as num?)?.toDouble() ?? 0.5,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  MonthlyReview? _parseMonthlyReview(String raw) {
    final map = _extractJsonMap(raw);
    if (map == null) return null;

    return MonthlyReview(
      periodKey: '',
      periodLabel: '',
      generatedAt: DateTime.now(),
      topTopics: (map['top_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      summary: map['summary'] as String? ?? '',
      growth: map['growth'] as String? ?? '',
      emotionTrend: map['emotion_trend'] as String? ?? '',
      chapterChanges: (map['chapter_changes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic>? _extractJsonMap(String raw) {
    var s = raw.trim();
    if (s.contains('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      s = s.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s.substring(start, end + 1)) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 사진·메모·과거 무드로 오늘 무드 3개 추천
  Future<List<MoodOption>> recommendMoods({
    required List<File> photoFiles,
    List<DailyEntry> pastEntries = const [],
    List<MoodOption> customMoods = const [],
    String? note,
  }) async {
    if (photoFiles.isEmpty) return [];

    if (!AiConfig.isGeminiConfigured) {
      return _fallbackMoodSuggestions(note: note);
    }

    try {
      final parsed = await _recommendMoodsWithGemini(
        photoFiles: photoFiles,
        pastEntries: pastEntries,
        customMoods: customMoods,
        note: note,
      );
      if (parsed.isNotEmpty) return parsed;
    } catch (e, st) {
      debugPrint('AiJournalService: mood recommend failed — $e\n$st');
    }

    return _fallbackMoodSuggestions(note: note);
  }

  Future<String?> generateDailyLine({
    required DailyEntry entry,
    List<DailyEntry> pastEntries = const [],
    List<File> photoFiles = const [],
  }) async {
    if (!EntryDiaryAi.shouldGenerateAiDiaryForEntry(entry)) {
      return null;
    }

    if (!AiConfig.isGeminiConfigured) {
      return AiNarrative.fallbackDailyLine(entry, pastEntries: pastEntries);
    }

    try {
      final line = await _generateWithGemini(
        entry: entry,
        pastEntries: pastEntries,
        photoFiles: photoFiles,
      );
      if (line != null && line.trim().isNotEmpty) {
        return _cleanModelOutput(line);
      }
    } catch (e, st) {
      debugPrint('AiJournalService: Gemini failed, using fallback — $e\n$st');
    }

    return AiNarrative.fallbackDailyLine(entry, pastEntries: pastEntries);
  }

  /// 챕터 제목 — Gemini (메모·무드 기반) → 규칙 폴백
  Future<String?> generateChapterTitle({
    required List<DailyEntry> entries,
  }) async {
    if (entries.isEmpty) return null;

    if (!AiConfig.isGeminiConfigured) {
      return null;
    }

    try {
      final title = await _generateChapterTitleWithGemini(entries);
      if (title != null && title.trim().isNotEmpty) {
        return _cleanChapterTitle(title);
      }
    } catch (e, st) {
      debugPrint('AiJournalService: chapter title failed — $e\n$st');
    }
    return null;
  }

  /// 저장 시 — 챕터에 아직 안 묶인 기록을 보고 봉인할지 판단
  Future<ChapterSealDecision?> evaluateOpenChapterSeal({
    required List<DailyEntry> openEntries,
  }) async {
    if (openEntries.length < 3 || !AiConfig.isGeminiConfigured) return null;

    try {
      final model = _model(maxOutputTokens: 220, temperature: 0.45);
      final prompt = _buildOpenChapterSealPrompt(openEntries);
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseSealDecision(response.text ?? '', openEntries);
    } catch (e, st) {
      debugPrint('AiJournalService: chapter seal evaluate failed — $e\n$st');
      return null;
    }
  }

  ChapterSealDecision? _parseSealDecision(String raw, List<DailyEntry> openEntries) {
    var s = raw.trim();
    if (s.contains('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      s = s.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    try {
      final map = jsonDecode(s.substring(start, end + 1)) as Map<String, dynamic>;
      final seal = map['seal'] == true;
      if (!seal) {
        return ChapterSealDecision(
          shouldSeal: false,
          sealedEntries: const [],
          remainingEntries: openEntries,
        );
      }

      final sorted = [...openEntries]..sort((a, b) => a.date.compareTo(b.date));
      final through = map['sealThroughIndex'];
      int lastIndex = sorted.length - 1;
      if (through is num) {
        lastIndex = through.round().clamp(2, sorted.length - 1);
      }

      final sealed = sorted.sublist(0, lastIndex + 1);
      final remaining = sorted.sublist(lastIndex + 1);
      if (sealed.length < 3) return null;

      final title = _cleanChapterTitle((map['title'] as String?) ?? '');
      final summary = (map['summary'] as String?)?.trim();

      return ChapterSealDecision(
        shouldSeal: true,
        sealedEntries: sealed,
        remainingEntries: remaining,
        title: title.isEmpty ? null : title,
        summary: summary?.isEmpty ?? true ? null : summary,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildOpenChapterSealPrompt(List<DailyEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final lines = <String>[];
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final parts = <String>[
        '#$i ${e.date.month}/${e.date.day}',
        if (e.moodLabel != null && e.moodLabel!.isNotEmpty) '무드:${e.moodLabel}',
        if (e.moodEmoji != null) e.moodEmoji!,
        if (e.note != null && e.note!.trim().isNotEmpty) '메모:${e.note!.trim()}',
        if (e.location != null && e.location!.trim().isNotEmpty) '장소:${e.location!.trim()}',
        if (e.hasPhotos) '사진${e.photoCount}',
      ];
      lines.add(parts.join(' '));
    }

    return '''
당신은 일기 앱 CHAPTER의 챕터 편집자입니다.

## 상황
아래 ${sorted.length}개의 기록은 **아직 어떤 챕터에도 묶이지 않은** 최근 순간들입니다 (오래된 순).
사용자가 방금 저장했습니다. 이 묶음을 **지금 챕터로 완성할지**, 아니면 **더 쌓을지** 판단하세요.

## 기록
${lines.map((l) => '- $l').join('\n')}

## 출력 (JSON만)
{
  "seal": true 또는 false,
  "sealThroughIndex": 숫자 또는 null,
  "title": "챕터 제목 (seal true일 때)",
  "summary": "1~2문장 요약 (seal true일 때)"
}

## 규칙
- seal false: 아직 같은 이야기가 이어지는 중, 챕터로 닫기 이릅다
- seal true: 분위기·주제·생활 리듬이 한 덩어리로 느껴지거나, 끝에서 분위기가 바뀌어 앞부분을 닫을 때
- sealThroughIndex: 0부터 inclusive. null이면 전부 봉인. 맨 끝만 분위기가 바뀌면 끝 제외하고 앞만 봉인
- 봉인 구간은 최소 3개 기록
- title 2~12자, 메모·무드에서 구체적 단어. "조용한 여름" 같은 클리셰 금지
- summary는 따뜻한 회고 톤, 120자 이내
''';
  }

  Future<String?> _generateChapterTitleWithGemini(List<DailyEntry> entries) async {
    final model = _model(maxOutputTokens: 40, temperature: 0.65);
    final prompt = _buildChapterTitlePrompt(entries);
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text;
  }

  String _buildChapterTitlePrompt(List<DailyEntry> entries) {
    final lines = <String>[];
    for (final e in entries.take(10)) {
      final parts = <String>[
        '${e.date.month}/${e.date.day}',
        if (e.moodLabel != null && e.moodLabel!.isNotEmpty) '무드:${e.moodLabel}',
        if (e.moodEmoji != null) e.moodEmoji!,
        if (e.note != null && e.note!.trim().isNotEmpty) '메모:${e.note!.trim()}',
        if (e.location != null && e.location!.trim().isNotEmpty) '장소:${e.location!.trim()}',
        if (e.hasPhotos) '사진${e.photoCount}장',
      ];
      lines.add(parts.join(' '));
    }

    return '''
당신은 일기 앱 CHAPTER의 챕터 제목 작가입니다.

## 기록 요약 (${entries.length}일)
${lines.map((l) => '- $l').join('\n')}

## 할 일
위 기록 묶음에 어울리는 **챕터 제목 1개**만 출력하세요.

## 규칙
- 2~12자, 한국어 또는 영문 혼용 가능 (예: SBI 미팅, 카페집중, 3월 출장)
- 사용자 메모·장소·활동에서 **구체적 단어**를 우선 사용
- "조용한 여름", "설레던 계절", "비 오던 날" 같은 **시적 클리셰 금지**
- 따옴표·설명·부제 없이 제목만
''';
  }

  String _cleanChapterTitle(String raw) {
    var s = raw.trim();
    if (s.contains('```')) {
      s = s.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
    }
    s = s.replaceAll(RegExp(r'^["「『\u201c]|[」』"\u201d]$'), '').trim();
    final firstLine = s.split('\n').first.trim();
    if (firstLine.length > 20) return firstLine.substring(0, 18);
    return firstLine;
  }

  Future<List<MoodOption>> _recommendMoodsWithGemini({
    required List<File> photoFiles,
    required List<DailyEntry> pastEntries,
    required List<MoodOption> customMoods,
    String? note,
  }) async {
    final model = _model(maxOutputTokens: 200, temperature: 0.55);
    final imageParts = await _imagePartsFromFiles(photoFiles);
    if (imageParts.isEmpty) return [];

    final prompt = _buildMoodRecommendPrompt(
      pastEntries: pastEntries,
      customMoods: customMoods,
      note: note,
      photoCount: imageParts.length,
    );

    final response = await model.generateContent([
      Content.multi([TextPart(prompt), ...imageParts]),
    ]);

    return _parseMoodJson(response.text ?? '');
  }

  Future<String?> _generateWithGemini({
    required DailyEntry entry,
    required List<DailyEntry> pastEntries,
    required List<File> photoFiles,
  }) async {
    final imageParts = await _imagePartsFromFiles(photoFiles);
    if (imageParts.isEmpty) {
      debugPrint('AiJournalService: no image bytes for vision, skipping Gemini');
      return null;
    }

    final model = _model(maxOutputTokens: 160, temperature: 0.72);
    final prompt = _buildPrompt(entry: entry, pastEntries: pastEntries, photoCount: imageParts.length);

    final response = await model.generateContent([
      Content.multi([TextPart(prompt), ...imageParts]),
    ]);

    return response.text;
  }

  GenerativeModel _model({required int maxOutputTokens, required double temperature}) {
    return GenerativeModel(
      model: AiConfig.geminiModel,
      apiKey: AiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
      ),
    );
  }

  Future<List<Part>> _imagePartsFromFiles(List<File> photoFiles) async {
    final imageParts = <Part>[];
    for (final file in photoFiles.take(AiConfig.maxPhotosForVision)) {
      final bytes = await _prepareImageBytes(file);
      if (bytes == null) continue;
      imageParts.add(DataPart(_mimeForPath(file.path), bytes));
    }
    return imageParts;
  }

  String _buildMoodRecommendPrompt({
    required List<DailyEntry> pastEntries,
    required List<MoodOption> customMoods,
    required String? note,
    required int photoCount,
  }) {
    final pastMoods = <String>[];
    for (final e in pastEntries.reversed) {
      if (e.moodEmoji == null) continue;
      final label = e.moodLabel ?? MoodProfileService.labelForEmoji(e.moodEmoji!, customMoods: customMoods);
      pastMoods.add('${e.moodEmoji} $label');
      if (pastMoods.length >= 6) break;
    }

    final noteLine = (note == null || note.trim().isEmpty) ? '(없음)' : note.trim();
    final pastBlock = pastMoods.isEmpty ? '(없음)' : pastMoods.map((m) => '- $m').join('\n');

    return '''
당신은 일기 앱 CHAPTER의 무드 추천 도우미입니다.

## 입력
- 사진 $photoCount장 (첨부)
- 오늘 메모: $noteLine
- 사용자가 예전에 쓴 무드:
$pastBlock

## 할 일
사진 장면·메모·사용자 말투에 맞는 **무드 3개**를 골라 주세요.

## 출력 형식 (JSON 배열만, 다른 글 금지)
[{"emoji":"이모지1","label":"2~6자한국어"},{"emoji":"이모지2","label":"..."},{"emoji":"이모지3","label":"..."}]

## 규칙
- label은 **일상 말투** (예: 카페집중, 육아텅, 버거움). "비오는", "고요한", "설레는" 같은 **시적 클리셰 금지**.
- 사진에 보이는 분위기·활동을 반영.
- 과거에 쓴 무드 스타일과 비슷한 단어를 쓰면 좋음.
- emoji는 1개씩만.
''';
  }

  List<MoodOption> _parseMoodJson(String raw) {
    var s = raw.trim();
    if (s.contains('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      s = s.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start < 0 || end <= start) return [];

    try {
      final list = jsonDecode(s.substring(start, end + 1)) as List<dynamic>;
      final out = <MoodOption>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final emoji = (item['emoji'] as String?)?.trim();
        var label = (item['label'] as String?)?.trim();
        if (emoji == null || emoji.isEmpty || label == null || label.isEmpty) continue;
        if (label.length > 8) label = label.substring(0, 8);
        out.add(MoodOption(emoji, label));
        if (out.length >= 3) break;
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  List<MoodOption> _fallbackMoodSuggestions({String? note}) {
    final n = note?.trim() ?? '';
    if (n.contains('피곤') || n.contains('졸')) {
      return const [MoodOption('😴', '피곤'), MoodOption('🫥', '텅 빈'), MoodOption('😌', '편안')];
    }
    if (n.contains('좋') || n.contains('행복') || n.contains('신')) {
      return const [MoodOption('🎉', '신남'), MoodOption('🙂', '괜찮'), MoodOption('🤍', '소중')];
    }
    if (n.contains('답') || n.contains('짜') || n.contains('빡')) {
      return const [MoodOption('😤', '답답'), MoodOption('😵', '벅참'), MoodOption('💭', '생각 많')];
    }
    final h = DateTime.now().hour;
    if (h >= 22 || h < 6) {
      return const [MoodOption('😴', '피곤'), MoodOption('🫥', '텅 빈'), MoodOption('😌', '편안')];
    }
    if (h >= 17) {
      return const [MoodOption('☕', '저녁'), MoodOption('😌', '편안'), MoodOption('💭', '생각 많')];
    }
    return [kDefaultMoods[0], kDefaultMoods[2], kDefaultMoods[4]];
  }

  String _buildPrompt({
    required DailyEntry entry,
    required List<DailyEntry> pastEntries,
    required int photoCount,
  }) {
    final toneSamples = <String>[];
    for (final e in pastEntries.reversed) {
      final n = e.note?.trim();
      if (n != null && n.isNotEmpty) {
        toneSamples.add(n);
      }
      if (toneSamples.length >= 5) break;
    }

    final mood = entry.moodEmoji == null
        ? '(선택 안 함)'
        : '${entry.moodEmoji} ${entry.moodLabel ?? ''}'.trim();
    final samplesBlock = toneSamples.isEmpty
        ? '(아직 과거 일기 없음 — 자연스럽고 따뜻한 해요체)'
        : toneSamples.map((s) => '- $s').join('\n');
    final multiPhoto = photoCount > 1
        ? '사진이 여러 장이면 **장면마다 다른 점**을 짧게 엮어 하나의 하루로 써 주세요.'
        : '사진 한 장의 **눈에 보이는 디테일**을 골라 써 주세요.';

    return '''
당신은 감성 일기 앱 CHAPTER의 글쓰기 도우미입니다.

## 상황
사용자는 오늘 **직접 쓴 글 없이** 사진만 남겼습니다.
첨부된 사진 $photoCount장을 **반드시 보고**, 그 장면만 근거로 일기 본문을 씁니다.

## 과거 일기 (말투·문장 길이·끝맺음만 참고)
$samplesBlock

## 오늘 보조 정보 (사진이 우선)
- 무드: $mood
- 날씨: ${entry.weatherDisplayLine ?? '(없음)'}
- 사용자 메모: 없음

## 해야 할 일
$multiPhoto
과거 일기와 비슷한 **말투**로 한국어 **1~2문장**(90자 이내)을 씁니다. 일기 본문만 출력하세요.

## 규칙
- 사진에 **실제로 보이는** 장소·사물·사람·빛·활동·분위기를 구체적으로 짚으세요.
- 사진에 없는 날씨·시간·감정·스토리를 **추측하지 마세요** (무드·날씨도 사진과 맞을 때만 가볍게 반영).
- "오늘의 한 페이지", "사진 한 장" 같은 **빈 문장·클리셰**는 쓰지 마세요.
- 이모지, 해시태그, 따옴표, 제목, 설명 없이 **본문만** 출력하세요.
''';
  }

  Future<Uint8List?> _prepareImageBytes(File file) async {
    if (!await file.exists()) return null;
    final raw = await file.readAsBytes();
    if (raw.length > AiConfig.maxPhotoBytes) {
      final decoded = img.decodeImage(raw);
      if (decoded == null) return null;
      final w = decoded.width;
      final h = decoded.height;
      final maxEdge = w > h ? w : h;
      final scale = maxEdge > AiConfig.photoMaxEdgePx ? AiConfig.photoMaxEdgePx / maxEdge : 1.0;
      final resized = img.copyResize(
        decoded,
        width: (w * scale).round(),
        height: (h * scale).round(),
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    }
    return Uint8List.fromList(raw);
  }

  String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _cleanModelOutput(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
    }
    s = s.replaceAll(RegExp(r'^["\u201c]|[\u201d"]$'), '').trim();
    final lines = s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).take(2);
    s = lines.join(' ');
    if (s.length > 100) {
      s = '${s.substring(0, 97)}…';
    }
    return s;
  }
}
