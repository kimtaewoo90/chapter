import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/chapter_cover.dart';
import '../../models/chapter_model.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../core/layout/shell_insets.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/paper_background.dart';
import 'chapter_detail_screen.dart';

/// 완성된 챕터만 — 진행 중인 이야기는 백그라운드
class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({
    super.key,
    this.embedInShell = false,
    this.onGoToRecord,
  });

  final bool embedInShell;
  final VoidCallback? onGoToRecord;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chapters = state.allChapters;
    final entries = state.allEntries;
    final bottomPad = embedInShell ? ShellInsets.bottom(context) : 0.0;
    final periodFmt = DateFormat('yyyy.MM', 'ko_KR');

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.paper.withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              title: const Text('챕터'),
            ),
            if (chapters.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyChaptersState(onGoToRecord: onGoToRecord),
              ),
            if (chapters.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPad),
                sliver: SliverList.separated(
                  itemCount: chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final chapter = chapters[i];
                    return _CompletedChapterCard(
                      chapter: chapter,
                      index: chapters.length - i,
                      periodFmt: periodFmt,
                      allEntries: entries,
                      onTap: () => _openDetail(context, chapter),
                    );
                  },
                ),
              )
            else
              SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
          ],
        ),
      ),
    );
  }

  static void _openDetail(BuildContext context, ChapterModel chapter) {
    Navigator.push(
      context,
      analyticsPageRoute(
        name: 'chapter_detail',
        builder: (_) => ChapterDetailScreen(chapter: chapter),
      ),
    );
  }
}

class _EmptyChaptersState extends StatelessWidget {
  const _EmptyChaptersState({this.onGoToRecord});

  final VoidCallback? onGoToRecord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아직 펼쳐진 챕터가 없어요',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '당신의 순간들은 조용히 쌓이고 있어요.\n'
                  '이야기가 한 덩어리가 되면, 여기에 챕터가 열립니다.',
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.65),
                ),
              ],
            ),
          ),
          if (onGoToRecord != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onGoToRecord,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('오늘 순간 남기기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedChapterCard extends StatelessWidget {
  const _CompletedChapterCard({
    required this.chapter,
    required this.index,
    required this.periodFmt,
    required this.allEntries,
    required this.onTap,
  });

  final ChapterModel chapter;
  final int index;
  final DateFormat periodFmt;
  final List<DailyEntry> allEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cover = ChapterCover.coverUri(chapter: chapter, allEntries: allEntries);

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cover != null)
              SizedBox(
                height: 160,
                child: EntryPhoto(url: cover, height: 160, borderRadius: 0),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${index.toString().padLeft(2, '0')}',
                    style: textTheme.labelSmall?.copyWith(color: AppTheme.accent, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chapter.title,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${periodFmt.format(chapter.startDate)} — ${periodFmt.format(chapter.endDate)}',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${chapter.entryCount}일 · 사진 ${chapter.photoCount}장',
                    style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                  if (chapter.narrative.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      chapter.narrative,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.inkMuted,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
