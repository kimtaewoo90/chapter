import '../models/daily_entry.dart';
import '../models/daily_insight.dart';
import '../models/journal_analysis.dart';
import '../models/monthly_review.dart';
import '../models/story_arc.dart';
import '../models/story_arc_ai_results.dart';
import '../models/story_arc_mapping.dart';
import '../models/story_arc_status.dart';
import '../core/utils/ai_narrative.dart';
import '../core/utils/chapter_segmenter.dart';
import '../core/utils/journal_analysis_fallback.dart';
import '../core/utils/monthly_review_period.dart';
import '../models/chapter_moment.dart';
import '../core/config/ai_config.dart';
import 'ai_journal_service.dart';
import 'local_story_arc_service.dart';

/// Story Memory Layer — 일기 분류 · Arc 매칭 · 발견 · 리포트 오케스트레이션
class StoryArcEngine {
  StoryArcEngine({
    required LocalStoryArcService arcs,
    required AiJournalService ai,
  })  : _arcs = arcs,
        _ai = ai;

  final LocalStoryArcService _arcs;
  final AiJournalService _ai;

  static const minEntriesForGrowing = 5;
  static const minDaysForGrowing = 7;
  static const minEntriesToComplete = ChapterSegmenter.minEntriesToSeal;
  static const whisperMinDays = 7;
  static const whisperMinEntries = 3;
  static const whisperManyEntries = 7;
  static const discoveryMinEntries = 5;
  static const discoveryMinDays = 7;
  static const discoveryCooldownDays = 3;

  /// 저장 직후 — 분석 → 매칭 → 상태 갱신 → Daily Insight
  Future<ProcessEntryResult> processEntrySaved({
    required String uid,
    required DailyEntry entry,
    required List<DailyEntry> allEntries,
  }) async {
    final activeArcs = _arcs.activeArcs(uid);
    final recentTopics = _recentTopics(allEntries, limit: 12);

    final analysis = await _analyze(entry, activeArcs, recentTopics);
    final match = await _match(entry, analysis, activeArcs);

    StoryArc? arc;
    if (match.storyArcId != null) {
      arc = _arcs.arcById(match.storyArcId!);
    }

    if (arc == null && match.newCategory != null) {
      arc = _arcs.createArc(
        userId: uid,
        category: match.newCategory!,
        displayTitle: match.newDisplayTitle ??
            JournalAnalysisFallback.suggestDisplayTitle(match.newCategory!, [entry]),
        description: match.newDescription,
        confidence: match.confidence,
        status: StoryArcStatus.seeding,
      );
      await _arcs.upsertArc(arc);
    }

    if (arc != null) {
      await _arcs.upsertMapping(
        StoryArcMapping(
          entryId: entry.id,
          storyArcId: arc.id,
          confidence: match.confidence,
        ),
      );
      arc = await _refreshArcStats(uid, arc.id, allEntries);
    }

    ChapterRevealPayload? completed;
    if (arc != null && arc.isActive) {
      completed = await _tryAutoComplete(uid, arc.id, allEntries);
    }

    final insight = await _buildInsight(entry, analysis, arc);
    await _arcs.saveDailyInsight(insight);

    await _runDiscoveryIfNeeded(uid, allEntries);

    return ProcessEntryResult(
      analysis: analysis,
      storyArc: arc,
      insight: insight,
      storyArcId: arc?.id,
      chapterCompleted: completed,
    );
  }

  /// 일주일쯤 — 아련한 「쓰여지는 중」 힌트 (피드용, 백그라운드만)
  ChapterWhisper? whisperForPrimaryArc(String uid) {
    final arc = primaryActiveArc(uid);
    if (arc == null) return null;
    if (_arcs.whisperWasShown(arc.id)) return null;

    final span = _arcSpanDays(arc);
    final eligible = arc.entryCount >= whisperManyEntries ||
        (span >= whisperMinDays && arc.entryCount >= whisperMinEntries);
    if (!eligible) return null;

    final title = arc.displayTitle;
    return ChapterWhisper(
      arcId: arc.id,
      title: title,
      message: '『$title』 챕터가 쓰이고 있어요…',
    );
  }

  int _arcSpanDays(StoryArc arc) {
    if (arc.firstEntryDate == null || arc.lastEntryDate == null) return 0;
    return arc.lastEntryDate!.difference(arc.firstEntryDate!).inDays;
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
    final arcs = _arcs.arcsForUser(uid);

    final review = await _ai.generateMonthlyReview(
      entries: window,
      storyArcs: arcs,
    );

    final resolved = (review ??
            _fallbackMonthlyReview(
              window,
              arcs,
              periodLabel: periodLabel,
            ))
        .copyWith(
      periodKey: periodKey,
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
    );

    await _arcs.upsertMonthlyReview(resolved);
    return resolved;
  }

  /// @deprecated — [generateMonthlyReviewForPeriod] 사용
  Future<MonthlyReview?> generateMonthlyReview({
    required String uid,
    required List<DailyEntry> allEntries,
  }) async {
    final now = DateTime.now();
    return generateMonthlyReviewForPeriod(
      uid: uid,
      year: now.year,
      month: now.month,
      allEntries: allEntries,
    );
  }

  /// Story Arc 자동 완성 — 사용자 UI 없이 백그라운드
  Future<StoryArc?> completeArc({
    required String arcId,
    String? displayTitle,
    String? description,
  }) async {
    final arc = _arcs.arcById(arcId);
    if (arc == null) return null;

    final updated = arc.copyWith(
      displayTitle: displayTitle?.trim().isNotEmpty == true ? displayTitle!.trim() : arc.displayTitle,
      description: description ?? arc.description,
      status: StoryArcStatus.completed,
    );
    await _arcs.upsertArc(updated);
    return updated;
  }

  Future<ChapterRevealPayload?> _tryAutoComplete(
    String uid,
    String arcId,
    List<DailyEntry> allEntries,
  ) async {
    var arc = _arcs.arcById(arcId);
    if (arc == null || !arc.isActive) return null;

    final entryIds = _arcs.entryIdsForArc(arcId).toSet();
    final entries = allEntries.where((e) => entryIds.contains(e.id)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.length < minEntriesToComplete) return null;

    List<DailyEntry> toSeal = entries;
    DailyEntry? pivot;

    if (arc.status == StoryArcStatus.shifting && entries.length >= minEntriesToComplete + 1) {
      toSeal = entries.sublist(0, entries.length - 1);
      pivot = entries.last;
    } else if (_arcSpanDays(arc) >= 21 && entries.length >= minEntriesForGrowing) {
      toSeal = entries;
    } else if (AiConfig.isGeminiConfigured && entries.length >= minEntriesForGrowing) {
      final decision = await _ai.evaluateOpenChapterSeal(openEntries: entries);
      if (decision?.shouldSeal == true && (decision!.sealedEntries.length >= minEntriesToComplete)) {
        toSeal = decision.sealedEntries;
        if (decision.remainingEntries.isNotEmpty) {
          pivot = decision.remainingEntries.first;
        }
      } else {
        return null;
      }
    } else {
      return null;
    }

    if (toSeal.length < minEntriesToComplete) return null;

    final title = await _ai.generateChapterTitle(entries: toSeal) ??
        arc.displayTitle;
    final narrative = AiNarrative.chapterNarrative(entries: toSeal, title: title);

    arc = (await completeArc(
      arcId: arcId,
      displayTitle: title,
      description: narrative,
    ))!;

    if (pivot != null) {
      final analysis = JournalAnalysisFallback.analyze(pivot);
      final newArc = _arcs.createArc(
        userId: uid,
        category: analysis.topics.isNotEmpty ? analysis.topics.first : arc.category,
        displayTitle: JournalAnalysisFallback.suggestDisplayTitle(
          analysis.topics.isNotEmpty ? analysis.topics.first : arc.category,
          [pivot],
        ),
        status: StoryArcStatus.seeding,
      );
      await _arcs.upsertArc(newArc);
      await _arcs.remapEntryToArc(entryId: pivot.id, storyArcId: newArc.id);
    }

    return ChapterRevealPayload(
      storyArcId: arc.id,
      title: title,
      narrative: narrative,
      entryCount: toSeal.length,
      startDate: toSeal.first.date,
      endDate: toSeal.last.date,
    );
  }

  /// 열린 풀(미완성 Arc)의 기록 목록
  List<DailyEntry> openEntriesForArc(String uid, List<DailyEntry> allEntries) {
    final primary = primaryActiveArc(uid);
    if (primary == null) {
      return _unmappedRecent(allEntries);
    }
    final ids = _arcs.entryIdsForArc(primary.id).toSet();
    return allEntries.where((e) => ids.contains(e.id)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  StoryArc? primaryActiveArc(String uid) {
    final active = _arcs.activeArcs(uid);
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final c = b.entryCount.compareTo(a.entryCount);
      if (c != 0) return c;
      return (b.lastEntryDate ?? DateTime(2000)).compareTo(a.lastEntryDate ?? DateTime(2000));
    });
    return active.first;
  }

  Future<JournalAnalysis> _analyze(
    DailyEntry entry,
    List<StoryArc> activeArcs,
    List<String> recentTopics,
  ) async {
    final aiResult = await _ai.analyzeJournal(
      entry: entry,
      currentArcs: activeArcs,
      recentTopics: recentTopics,
    );
    return aiResult ?? JournalAnalysisFallback.analyze(entry);
  }

  Future<StoryArcMatchResult> _match(
    DailyEntry entry,
    JournalAnalysis analysis,
    List<StoryArc> activeArcs,
  ) async {
    if (activeArcs.isEmpty) {
      return StoryArcMatchResult(
        storyArcId: null,
        confidence: 0.4,
        newCategory: analysis.topics.isNotEmpty ? analysis.topics.first : 'daily_life',
        newDisplayTitle: null,
      );
    }

    final aiResult = await _ai.matchStoryArc(
      entry: entry,
      analysis: analysis,
      currentArcs: activeArcs,
    );

    if (aiResult != null) return aiResult;

    return _fallbackMatch(analysis, activeArcs);
  }

  StoryArcMatchResult _fallbackMatch(JournalAnalysis analysis, List<StoryArc> activeArcs) {
    for (final arc in activeArcs) {
      if (analysis.topics.contains(arc.category)) {
        return StoryArcMatchResult(
          storyArcId: arc.id,
          confidence: 0.65,
        );
      }
    }
    return StoryArcMatchResult(
      storyArcId: null,
      confidence: 0.45,
      newCategory: analysis.topics.isNotEmpty ? analysis.topics.first : 'daily_life',
    );
  }

  Future<StoryArc> _refreshArcStats(
    String uid,
    String arcId,
    List<DailyEntry> allEntries,
  ) async {
    var arc = _arcs.arcById(arcId)!;
    final entryIds = _arcs.entryIdsForArc(arcId).toSet();
    final entries = allEntries.where((e) => entryIds.contains(e.id)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final count = entries.length;
    DateTime? first;
    DateTime? last;
    if (entries.isNotEmpty) {
      first = entries.first.date;
      last = entries.last.date;
    }

    var status = arc.status;
    if (status != StoryArcStatus.completed) {
      final spanDays = first != null && last != null ? last.difference(first).inDays : 0;
      if (count >= minEntriesForGrowing && spanDays >= minDaysForGrowing) {
        status = StoryArcStatus.growing;
      } else {
        status = StoryArcStatus.seeding;
      }

      final active = _arcs.activeArcs(uid);
      if (active.isNotEmpty) {
        final maxCount = active.map((a) => a.entryCount).reduce((a, b) => a > b ? a : b);
        if (count >= maxCount && count >= 3) {
          status = StoryArcStatus.focused;
        }
      }

      if (entries.length >= 3) {
        final recent = entries.sublist(entries.length - 3);
        final recentTopics = recent.expand((e) => e.topics).toSet();
        if (recentTopics.isNotEmpty && !recentTopics.contains(arc.category)) {
          status = StoryArcStatus.shifting;
        }
      }
    }

    arc = arc.copyWith(
      entryCount: count,
      firstEntryDate: first,
      lastEntryDate: last,
      status: status,
      confidenceScore: (arc.confidenceScore + 0.05).clamp(0.0, 1.0),
    );
    await _arcs.upsertArc(arc);
    return arc;
  }

  Future<void> _runDiscoveryIfNeeded(String uid, List<DailyEntry> allEntries) async {
    final last = _arcs.lastDiscoveryAt;
    if (last != null && DateTime.now().difference(last).inDays < discoveryCooldownDays) {
      return;
    }

    final window = _entriesInLastDays(allEntries, 30);
    if (window.length < discoveryMinEntries) return;

    final span = window.last.date.difference(window.first.date).inDays;
    if (span < discoveryMinDays) return;

    final existing = _arcs.arcsForUser(uid);
    final candidates = await _ai.discoverNewStoryArcs(
      entries: window,
      existingArcs: existing,
    );

    if (candidates != null) {
      for (final c in candidates) {
        if (!c.newStoryDetected) continue;
        if (existing.any((a) => a.category == c.category && a.isActive)) continue;

        final arc = _arcs.createArc(
          userId: uid,
          category: c.category,
          displayTitle: c.title,
          confidence: c.confidence,
          status: StoryArcStatus.seeding,
        );
        await _arcs.upsertArc(arc);
      }
    }

    await _arcs.markDiscoveryRun();
  }

  Future<DailyInsight> _buildInsight(
    DailyEntry entry,
    JournalAnalysis analysis,
    StoryArc? arc,
  ) async {
    final aiLine = await _ai.generateDailyInsight(
      entry: entry,
      analysis: analysis,
      matchedArc: arc,
    );

    final message = aiLine ?? _fallbackInsightMessage(analysis, arc);

    return DailyInsight(
      entryId: entry.id,
      message: message,
      storyArcTitle: arc?.displayTitle,
      topics: analysis.topics,
    );
  }

  String _fallbackInsightMessage(JournalAnalysis analysis, StoryArc? arc) {
    if (arc != null) {
      return '「${arc.displayTitle}」 이야기에 오늘 기록이 더해졌어요.';
    }
    final topic = analysis.topics.isNotEmpty
        ? JournalAnalysisFallback.categoryLabel(analysis.topics.first)
        : '오늘';
    return '$topic 주제의 하루가 남았어요.';
  }

  MonthlyReview _fallbackMonthlyReview(
    List<DailyEntry> window,
    List<StoryArc> arcs, {
    required String periodLabel,
  }) {
    final topicCounts = <String, int>{};
    for (final e in window) {
      for (final t in e.topics) {
        topicCounts[t] = (topicCounts[t] ?? 0) + 1;
      }
    }
    final topTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final labels = topTopics.take(3).map((e) => JournalAnalysisFallback.categoryLabel(e.key)).toList();

    final changes = arcs
        .where((a) => a.status == StoryArcStatus.completed)
        .map((a) => a.displayTitle)
        .take(3)
        .toList();

    return MonthlyReview(
      periodKey: MonthlyReviewPeriod.periodKeyFromDate(window.first.date),
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      topTopics: labels,
      summary: labels.isEmpty
          ? '$periodLabel, ${window.length}일의 순간이 쌓였어요.'
          : '$periodLabel, ${labels.join(' · ')} 이야기가 두드러졌어요.',
      growth: '꾸준히 기록하며 자신만의 이야기를 쌓고 있어요.',
      chapterChanges: changes,
    );
  }

  List<String> _recentTopics(List<DailyEntry> allEntries, {required int limit}) {
    final topics = <String>[];
    for (final e in allEntries) {
      for (final t in e.topics) {
        if (!topics.contains(t)) topics.add(t);
        if (topics.length >= limit) return topics;
      }
    }
    return topics;
  }

  List<DailyEntry> _entriesInLastDays(List<DailyEntry> all, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final list = all.where((e) => e.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<DailyEntry> _unmappedRecent(List<DailyEntry> allEntries) {
    return allEntries.where((e) {
      final m = _arcs.mappingForEntry(e.id);
      if (m == null) return true;
      final arc = _arcs.arcById(m.storyArcId);
      return arc == null || arc.isActive;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class ProcessEntryResult {
  const ProcessEntryResult({
    required this.analysis,
    this.storyArc,
    required this.insight,
    this.storyArcId,
    this.chapterCompleted,
  });

  final JournalAnalysis analysis;
  final StoryArc? storyArc;
  final DailyInsight insight;
  final String? storyArcId;
  final ChapterRevealPayload? chapterCompleted;
}
