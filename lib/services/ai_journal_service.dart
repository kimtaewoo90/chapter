import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

import '../core/config/ai_config.dart';
import '../core/constants/moods.dart';
import '../core/utils/ai_narrative.dart';
import '../core/utils/entry_diary_ai.dart';
import '../models/daily_entry.dart';
import '../models/monthly_review.dart';
import '../models/monthly_review_digest.dart';
import 'mood_profile_service.dart';

/// 일기 AI — Gemini (일기 한 줄 · 무드 추천 · 월간 회고)
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

  /// 월간 리포트 — 팩트 digest 기반 한 줄 회고
  Future<MonthlyReview?> generateMonthlyReview({
    required List<DailyEntry> entries,
    required MonthlyReviewDigest digest,
  }) async {
    if (!AiConfig.isGeminiConfigured || entries.length < 3) return null;

    try {
      final model = _model(maxOutputTokens: 120, temperature: 0.45);
      final prompt = _buildMonthlyReviewPrompt(
        entries: entries,
        digest: digest,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final reflection = _parseMonthlyReflection(response.text ?? '');
      if (reflection == null || reflection.isEmpty) return null;

      return MonthlyReview(
        periodKey: '',
        periodLabel: '',
        generatedAt: DateTime.now(),
        topTopics: const [],
        summary: reflection,
        growth: '',
        digest: digest,
      );
    } catch (e, st) {
      debugPrint('AiJournalService: generateMonthlyReview failed — $e\n$st');
      return null;
    }
  }

  String _buildMonthlyReviewPrompt({
    required List<DailyEntry> entries,
    required MonthlyReviewDigest digest,
  }) {
    final digestJson = jsonEncode(digest.toJson());

    return '''
당신은 일기 앱 CHAPTER의 월간 회고 도우미입니다. **창작하지 말고** 아래 팩트만 사용하세요.

## 집계 팩트 (JSON)
$digestJson

## 기록 일수
${entries.length}일

## 할 일
위 팩트만 근거로, 사용자가 한 달을 돌아볼 때 도움이 되는 **한국어 1~2문장**(100자 이내)을 씁니다.
- 팩트에 없는 인물·장소·감정·사건을 **추가하지 마세요**
- streak·부족함 비난·클리셰 금지
- 따뜻한 회고 톤

## 출력 (JSON만)
{
  "reflection": "한 줄 회고"
}
''';
  }

  String? _parseMonthlyReflection(String raw) {
    final map = _extractJsonMap(raw);
    if (map != null) {
      final reflection = map['reflection'] as String? ?? map['summary'] as String?;
      if (reflection != null && reflection.trim().isNotEmpty) {
        return _cleanModelOutput(reflection.trim());
      }
    }
    final trimmed = _cleanModelOutput(raw.trim());
    return trimmed.isEmpty ? null : trimmed;
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
