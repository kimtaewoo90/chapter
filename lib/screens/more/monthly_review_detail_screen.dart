import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/monthly_review.dart';
import '../../models/monthly_review_digest.dart';
import '../../providers/app_state.dart';
import '../../widgets/paper_background.dart';

/// 월간 리포트 상세 — 일기 팩트 스냅샷 회고
class MonthlyReviewDetailScreen extends StatefulWidget {
  const MonthlyReviewDetailScreen({super.key, required this.review});

  final MonthlyReview review;

  @override
  State<MonthlyReviewDetailScreen> createState() => _MonthlyReviewDetailScreenState();
}

class _MonthlyReviewDetailScreenState extends State<MonthlyReviewDetailScreen> {
  late MonthlyReview _review;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
  }

  Future<void> _regenerate() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    try {
      final updated = await context.read<AppState>().regenerateMonthlyReview(_review.periodKey);
      if (updated != null && mounted) {
        setState(() => _review = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이번 달 리포트를 다시 정리했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final digest = _review.digest;
    final stale = context.watch<AppState>().isMonthlyReviewStale(_review.periodKey);

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(_review.periodLabel)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _TimingNote(periodLabel: _review.periodLabel),
            if (stale) ...[
              const SizedBox(height: 12),
              _StaleBanner(
                regenerating: _regenerating,
                onRegenerate: _regenerate,
              ),
            ],
            const SizedBox(height: 16),
            if (digest != null) ...[
              _StatsRow(digest: digest),
              const SizedBox(height: 16),
              if (_review.summary.isNotEmpty)
                _Section(
                  title: '한 달을 돌아보며',
                  child: Text(
                    _review.summary,
                    style: textTheme.bodyLarge?.copyWith(height: 1.65),
                  ),
                ),
              if (_review.summary.isNotEmpty) const SizedBox(height: 16),
              if (digest.moods.isNotEmpty)
                _FactSection(
                  title: '가장 많이 찍힌 무드',
                  icon: Icons.spa_outlined,
                  items: digest.moods,
                ),
              if (digest.places.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '자주 남긴 장소',
                  icon: Icons.place_outlined,
                  items: digest.places,
                ),
              ],
              if (digest.people.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '함께한 사람',
                  icon: Icons.favorite_outline,
                  items: digest.people,
                ),
              ],
              if (digest.words.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '자주 쓴 단어',
                  icon: Icons.text_fields_outlined,
                  items: digest.words,
                ),
              ],
              if (digest.emotions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '감정 톤',
                  icon: Icons.waves_outlined,
                  items: digest.emotions,
                ),
              ],
            ] else ...[
              _LegacyBody(review: _review),
            ],
            if (_review.chapterChanges.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: '이 달에 완성된 챕터',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _review.chapterChanges
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_stories_outlined,
                                size: 16,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(c, style: textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({
    required this.regenerating,
    required this.onRegenerate,
  });

  final bool regenerating;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 달 일기가 바뀌었어요',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '리포트는 만들 당시 그대로 보관 중이에요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: regenerating ? null : onRegenerate,
            child: regenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('다시 정리하기'),
          ),
        ],
      ),
    );
  }
}

class _TimingNote extends StatelessWidget {
  const _TimingNote({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$periodLabel이 지난 뒤, 그달 일기만 모아 스냅샷으로 저장했어요.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.inkMuted,
              height: 1.5,
            ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.digest});

  final MonthlyReviewDigest digest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(value: '${digest.recordedDays}', label: '기록한 날', textTheme: textTheme),
          _StatChip(value: '${digest.totalPhotos}', label: '사진', textTheme: textTheme),
          _StatChip(value: '${digest.noteDays}', label: '글 쓴 날', textTheme: textTheme),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.textTheme,
  });

  final String value;
  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: textTheme.titleLarge?.copyWith(color: AppTheme.accent)),
        Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted)),
      ],
    );
  }
}

class _FactSection extends StatelessWidget {
  const _FactSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<MonthlyFactItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _FactRow(item: items[i], rank: i + 1, textTheme: textTheme),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.item,
    required this.rank,
    required this.textTheme,
  });

  final MonthlyFactItem item;
  final int rank;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final bar = (item.count / 10).clamp(0.12, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: textTheme.labelMedium?.copyWith(color: AppTheme.inkMuted),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.label, style: textTheme.bodyMedium),
                  ),
                  Text(
                    '${item.count}번',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: bar,
                  minHeight: 5,
                  backgroundColor: AppTheme.paperDark,
                  color: AppTheme.accent.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegacyBody extends StatelessWidget {
  const _LegacyBody({required this.review});

  final MonthlyReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        if (review.summary.isNotEmpty)
          _Section(
            title: '한 달 요약',
            child: Text(review.summary, style: textTheme.bodyLarge),
          ),
        if (review.topTopics.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: '주요 주제',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.topTopics
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppTheme.accent),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
