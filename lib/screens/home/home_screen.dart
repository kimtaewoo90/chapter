import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/entry_photo_grid.dart';
import '../../core/layout/shell_insets.dart';
import '../../widgets/paper_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onGoToRecord});

  final VoidCallback? onGoToRecord;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.todayEntry;
    final dateFmt = DateFormat('M월 d일 · EEEE', 'ko_KR');

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.homeHeadline,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('yyyy.MM').format(DateTime.now())} — Present',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _TodayCard(
                    dateLabel: dateFmt.format(DateTime.now()),
                    entry: today,
                    onRecord: onGoToRecord ?? () {},
                  ),
                ),
              ),
              if (state.memoryEntry != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MemoryBanner(entry: state.memoryEntry!),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _BookProgressCard(
                    progress: state.bookProgress,
                    pages: state.estimatedPages,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 16 + ShellInsets.bottom(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isTodayBlank(DailyEntry? e) {
  if (e == null) return true;
  return !e.hasPhotos &&
      (e.note == null || e.note!.trim().isEmpty) &&
      e.moodEmoji == null &&
      EntryDiaryAi.primaryDiaryText(e) == null &&
      e.weatherDisplayLine == null;
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.dateLabel,
    required this.entry,
    required this.onRecord,
  });

  final String dateLabel;
  final DailyEntry? entry;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final diaryFontId = context.watch<AppState>().diaryFontId;
    if (_isTodayBlank(e)) {
      return _EmptyTodayCard(dateLabel: dateLabel, onRecord: onRecord);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
                if (e?.moodEmoji != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(e!.moodEmoji!, style: const TextStyle(fontSize: 24)),
                      if (e.moodLabel != null && e.moodLabel!.isNotEmpty)
                        Text(
                          e.moodLabel!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: e != null && e.hasPhotos
                ? EntryPhotoGrid(
                    localPaths: EntryPhotos.displayUris(
                      localPaths: e.localPhotoPaths,
                      remoteUrls: e.remotePhotoUrls,
                    ),
                    height: 200,
                  )
                : const EntryPhotoGrid(localPaths: [], height: 200),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e?.weatherDisplayLine != null)
                  Text(
                    e!.weatherDisplayLine!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                if (e != null && EntryDiaryAi.primaryDiaryText(e) != null) ...[
                  const SizedBox(height: 12),
                  if (EntryDiaryAi.shouldShowAiLine(e))
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        EntryDiaryAi.primaryDiaryText(e)!,
                        style: diaryFontStyle(
                          diaryFontId,
                          fontSize: 16,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else
                    Text(
                      EntryDiaryAi.primaryDiaryText(e)!,
                      style: diaryFontStyle(diaryFontId, fontSize: 16, height: 1.5),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘 기록이 없을 때 — 빈 책 페이지 + 폴라로이드 힌트
class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard({required this.dateLabel, required this.onRecord});

  final String dateLabel;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final stamp = '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRecord,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(dateLabel, style: textTheme.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.paperDark),
                      ),
                      child: Text(
                        'Blank page',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.inkMuted,
                          letterSpacing: 0.3,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _BlankPageIllustration(),
                const SizedBox(height: 20),
                Text(
                  '오늘의 한 페이지',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '사진 한 컷, 무드, 짧은 한 줄이\n한 페이지의 이야기가 됩니다.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRecord,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('오늘 기록하기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_outline, size: 14, color: AppTheme.accent.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '가운데 책갈피에서도 기록할 수 있어요 · $stamp',
                      style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlankPageIllustration extends StatelessWidget {
  const _BlankPageIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.paper.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.paperDark),
              ),
              child: CustomPaint(
                painter: _RuledLinesPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const _GhostPolaroid(offset: Offset(-22, 8), rotation: -0.08, opacity: 0.45),
          const _GhostPolaroid(offset: Offset(18, -6), rotation: 0.06, opacity: 0.35),
          const _EmptyPolaroidHint(),
        ],
      ),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.paperDark.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    const gap = 22.0;
    for (var y = 36.0; y < size.height - 20; y += gap) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), paint);
    }
    final margin = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(52, 28), Offset(52, size.height - 16), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GhostPolaroid extends StatelessWidget {
  const _GhostPolaroid({
    required this.offset,
    required this.rotation,
    required this.opacity,
  });

  final Offset offset;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.paperDark),
            ),
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.paperDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPolaroidHint extends StatelessWidget {
  const _EmptyPolaroidHint();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stamp = '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Transform.rotate(
      angle: -0.02,
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.paperDark),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppTheme.accent.withValues(alpha: 0.9), size: 28),
              const SizedBox(height: 6),
              const Text('오늘의 컷', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink)),
              const SizedBox(height: 2),
              Text(stamp, style: TextStyle(fontSize: 10, color: AppTheme.inkMuted.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryBanner extends StatelessWidget {
  const _MemoryBanner({required this.entry});

  final DailyEntry entry;

  @override
  Widget build(BuildContext context) {
    final diaryFontId = context.watch<AppState>().diaryFontId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (entry.hasPhotos)
            SizedBox(
              height: 56,
              width: 56,
              child: EntryPhoto(url: entry.coverPhotoPath, height: 56, borderRadius: 8),
            )
          else
            const Icon(Icons.history, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('작년 이맘때', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.accent)),
                Text(
                  EntryDiaryAi.primaryDiaryText(entry) ?? '그날의 기록이 남아있어요',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: diaryFontStyle(diaryFontId, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookProgressCard extends StatelessWidget {
  const _BookProgressCard({required this.progress, required this.pages});

  final double progress;
  final int pages;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('올해의 이야기', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.paperDark,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pct% 완성', style: Theme.of(context).textTheme.bodySmall),
              Text('약 $pages pages', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
