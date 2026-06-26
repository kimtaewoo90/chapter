import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/chapter_bottom_bar.dart';
import '../../widgets/paper_background.dart';

/// 최근 30일 Story Arc 기반 월간 리포트
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await context.read<AppState>().refreshMonthlyReview();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final review = state.monthlyReview;
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('월간 리포트'),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + ChapterBottomBar.listBottomPadding(context),
          ),
          children: [
            if (review == null && !_loading)
              _EmptyReview(onGenerate: _load)
            else if (review != null) ...[
              Text(
                DateFormat('yyyy.MM.dd').format(review.generatedAt),
                style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 20),
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
              _Section(title: '한 달 요약', child: Text(review.summary, style: textTheme.bodyLarge)),
              if (review.emotionTrend.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(title: '감정 변화', child: Text(review.emotionTrend, style: textTheme.bodyMedium)),
              ],
              const SizedBox(height: 16),
              _Section(title: '성장 포인트', child: Text(review.growth, style: textTheme.bodyMedium)),
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
                                const Icon(Icons.auto_stories_outlined, size: 16, color: AppTheme.accent),
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
          ],
        ),
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('기록이 3일 이상 쌓이면 월간 리포트를 만들 수 있어요', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: onGenerate, child: const Text('리포트 생성')),
        ],
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
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
