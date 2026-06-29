import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/monthly_review.dart';
import '../../widgets/paper_background.dart';

/// 월간 리포트 상세
class MonthlyReviewDetailScreen extends StatelessWidget {
  const MonthlyReviewDetailScreen({super.key, required this.review});

  final MonthlyReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(review.periodLabel)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Section(
              title: '주요 주제',
              child: review.topTopics.isEmpty
                  ? Text('아직 주제가 모이지 않았어요', style: textTheme.bodyMedium)
                  : Wrap(
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
            const SizedBox(height: 16),
            _Section(
              title: '한 달 요약',
              child: Text(review.summary, style: textTheme.bodyLarge),
            ),
            if (review.emotionTrend.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: '감정 변화',
                child: Text(review.emotionTrend, style: textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 16),
            _Section(
              title: '성장 포인트',
              child: Text(review.growth, style: textTheme.bodyMedium),
            ),
            if (review.chapterChanges.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: '챕터 변화',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: review.chapterChanges
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
