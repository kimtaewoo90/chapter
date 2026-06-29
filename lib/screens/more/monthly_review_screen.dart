import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/monthly_review_period.dart';
import '../../models/monthly_review.dart';
import '../../providers/app_state.dart';
import '../../core/layout/shell_insets.dart';
import '../../widgets/paper_background.dart';
import 'monthly_review_detail_screen.dart';

/// 월간 리포트 — 이번 달 힌트 + 지난 리포트 아카이브
class MonthlyReviewScreen extends StatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    await context.read<AppState>().syncMonthlyReviewArchive();
    if (mounted) setState(() => _loading = false);
  }

  void _openDetail(MonthlyReview review) {
    Navigator.push(
      context,
      analyticsPageRoute(
        name: 'monthly_review_detail',
        builder: (_) => MonthlyReviewDetailScreen(review: review),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final revealed = state.revealedMonthlyReviews;
    final currentKey = state.currentMonthPeriodKey;
    final currentRevealed = revealed.any((r) => r.periodKey == currentKey);
    final daysLeft = state.daysUntilMonthlyReview;
    final currentMonthEntries = MonthlyReviewPeriod.entriesInMonth(
      state.allEntries,
      year: state.todayDate.year,
      month: state.todayDate.month,
    );

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('월간 리포트')),
        body: _loading && revealed.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + ShellInsets.bottom(context),
                ),
                children: [
                  if (!currentRevealed)
                    _CurrentMonthHintCard(
                      daysLeft: daysLeft,
                      entryCount: currentMonthEntries.length,
                    ),
                  if (!currentRevealed && revealed.isNotEmpty)
                    const SizedBox(height: 20),
                  if (revealed.isEmpty && !currentRevealed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        '말일이 되면 이번 달 이야기가 정리돼요.\n기록이 쌓일수록 리포트가 풍성해져요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.inkMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (revealed.isNotEmpty) ...[
                    Text(
                      '지난 리포트',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    for (final review in revealed)
                      _ReviewListTile(
                        review: review,
                        onTap: () => _openDetail(review),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CurrentMonthHintCard extends StatelessWidget {
  const _CurrentMonthHintCard({
    required this.daysLeft,
    required this.entryCount,
  });

  final int daysLeft;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = MonthlyReviewPeriod.periodLabelFromDate(DateTime.now());

    String subtitle;
    if (daysLeft > 0) {
      subtitle = '말일까지 $daysLeft일 · 기록 $entryCount일';
    } else if (entryCount < MonthlyReviewPeriod.minEntriesToGenerate) {
      subtitle = '이번 달은 조용히 흘러갔어요';
    } else {
      subtitle = '곧 이번 달 이야기가 열려요';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            daysLeft > 0
                ? '이번 달 이야기는 말일에 열려요'
                : '이번 달 이야기를 정리하는 중이에요',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ReviewListTile extends StatelessWidget {
  const _ReviewListTile({required this.review, required this.onTap});

  final MonthlyReview review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.periodLabel,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (review.summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          review.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.inkMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
