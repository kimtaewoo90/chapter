import '../models/daily_entry.dart';
import '../models/daily_insight.dart';
import '../models/journal_analysis.dart';
import '../models/monthly_review.dart';
import '../models/monthly_review_digest.dart';
import '../core/utils/journal_analysis_fallback.dart';
import '../core/utils/monthly_review_digest_builder.dart';
import '../core/utils/monthly_review_period.dart';
import '../core/utils/monthly_review_source_hash.dart';
import 'ai_journal_service.dart';
import 'local_story_arc_service.dart';

/// 일기 저장 후 분석·월간 리포트 생성 (Story Arc / 챕터 봉인 없음)
class EntryInsightsEngine {
  EntryInsightsEngine({
    required LocalStoryArcService insights,
    required AiJournalService ai,
  })  : _insights = insights,
        _ai = ai;

  final LocalStoryArcService _insights;
  final AiJournalService _ai;

  Future<ProcessEntryResult> processEntrySaved({
    required String uid,
    required DailyEntry entry,
    required List<DailyEntry> allEntries,
  }) async {
    final analysis = JournalAnalysisFallback.analyze(entry);
    final insight = _buildInsight(entry, analysis);
    await _insights.saveDailyInsight(insight);
    return ProcessEntryResult(analysis: analysis, insight: insight);
  }

  Future<MonthlyReview?> generateMonthlyReviewForPeriod({
    required String uid,
    required int year,
    required int month,
    required List<DailyEntry> allEntries,
  }) async {
    final window = MonthlyReviewPeriod.entriesInMonth(
      allEntries,
      year: year,
      month: month,
    );
    if (window.length < MonthlyReviewPeriod.minEntriesToGenerate) return null;

    final periodKey = MonthlyReviewPeriod.periodKey(year, month);
    final periodLabel = MonthlyReviewPeriod.periodLabel(year, month);

    final digest = MonthlyReviewDigestBuilder.build(
      window,
      periodLabel: periodLabel,
    );
    final sourceEntryHash = MonthlyReviewSourceHash.compute(window);

    final review = await _ai.generateMonthlyReview(
      entries: window,
      digest: digest,
    );

    final fallback = _fallbackMonthlyReview(
      window,
      periodLabel: periodLabel,
      digest: digest,
    );

    final resolved = (review ?? fallback).copyWith(
      periodKey: periodKey,
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      digest: review?.digest ?? digest,
      sourceEntryHash: sourceEntryHash,
      summary: (review?.summary.isNotEmpty == true)
          ? review!.summary
          : fallback.summary,
    );

    await _insights.upsertMonthlyReview(resolved);
    return resolved;
  }

  DailyInsight _buildInsight(DailyEntry entry, JournalAnalysis analysis) {
    final topic = analysis.topics.isNotEmpty
        ? JournalAnalysisFallback.categoryLabel(analysis.topics.first)
        : '오늘';
    return DailyInsight(
      entryId: entry.id,
      message: '$topic 주제의 하루가 남았어요.',
      topics: analysis.topics,
    );
  }

  MonthlyReview _fallbackMonthlyReview(
    List<DailyEntry> window, {
    required String periodLabel,
    required MonthlyReviewDigest digest,
  }) {
    return MonthlyReview(
      periodKey: MonthlyReviewPeriod.periodKeyFromDate(window.first.date),
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      topTopics: const [],
      summary: digest.factSummary,
      growth: '',
      digest: digest,
    );
  }
}

class ProcessEntryResult {
  const ProcessEntryResult({
    required this.analysis,
    required this.insight,
  });

  final JournalAnalysis analysis;
  final DailyInsight insight;
}
