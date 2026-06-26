import '../../models/daily_entry.dart';
import '../../services/ai_journal_service.dart';
import '../config/ai_config.dart';
import 'ai_narrative.dart';
import 'chapter_open_pool.dart';
import 'chapter_segmenter.dart';

/// 저장 시점 — 아직 챕터에 안 묶인 기록을 보고 봉인 여부 판단
class ChapterSealEvaluator {
  ChapterSealEvaluator._();

  static const minEntries = ChapterSegmenter.minEntriesToSeal;

  static Future<ChapterSealDecision> evaluateOnSave({
    required List<DailyEntry> openEntries,
    required AiJournalService ai,
  }) async {
    if (openEntries.length < minEntries) {
      return ChapterSealDecision(
        shouldSeal: false,
        sealedEntries: const [],
        remainingEntries: openEntries,
      );
    }

    if (AiConfig.isGeminiConfigured) {
      try {
        final aiResult = await ai.evaluateOpenChapterSeal(openEntries: openEntries);
        if (aiResult != null) {
          return aiResult;
        }
      } catch (_) {
        // 규칙 폴백
      }
    }

    return _ruleFallback(openEntries);
  }

  static ChapterSealDecision _ruleFallback(List<DailyEntry> open) {
    final split = ChapterSegmenter.splitOpenPoolOnBoundary(open);
    if (split != null) {
      final title = AiNarrative.suggestChapterTitle(split.sealed);
      return ChapterSealDecision(
        shouldSeal: true,
        sealedEntries: split.sealed,
        remainingEntries: split.remaining,
        title: title,
        summary: AiNarrative.chapterNarrative(entries: split.sealed, title: title),
      );
    }

    return ChapterSealDecision(
      shouldSeal: false,
      sealedEntries: const [],
      remainingEntries: open,
    );
  }
}
