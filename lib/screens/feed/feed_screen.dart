import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/journal_book_page.dart';
import '../../widgets/paper_background.dart';
import 'entry_day_sheet.dart';

/// 메인 — 책장을 넘기듯 하루를 보는 화면
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    this.onGoToRecord,
    this.showHeader = true,
  });

  final VoidCallback? onGoToRecord;
  final bool showHeader;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _didAlignToToday = false;

  bool get _embedded => !widget.showHeader;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      HapticFeedback.selectionClick();
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // 최신순(0=오늘). 왼쪽 스와이프 → 과거
    final entries = state.allEntries;
    final textTheme = Theme.of(context).textTheme;
    final today = state.todayEntry;
    final showTodayPrompt = _isTodayBlank(today);

    if (entries.isNotEmpty && !_didAlignToToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAlignToToday || !_pageController.hasClients) return;
        _pageController.jumpToPage(0);
        setState(() {
          _currentPage = 0;
          _didAlignToToday = true;
        });
      });
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('나의 책', style: textTheme.titleLarge),
                      Text(
                        entries.isEmpty
                            ? '첫 페이지를 써 보세요'
                            : '옆으로 넘기며 읽어요',
                        style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    '${_currentPage + 1} / ${entries.length}',
                    style: textTheme.labelMedium?.copyWith(color: AppTheme.accent),
                  ),
              ],
            ),
          )
        else if (entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '← 과거 · → 최근 · ↑↓ 글 읽기',
                    style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ),
                Text(
                  '${_currentPage + 1} / ${entries.length}',
                  style: textTheme.labelMedium?.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
          ),
        if (showTodayPrompt)
          Padding(
            padding: EdgeInsets.fromLTRB(_embedded ? 0 : 16, 4, _embedded ? 0 : 16, 8),
            child: _TodayPagePrompt(onGoToRecord: widget.onGoToRecord),
          ),
        Expanded(
          child: entries.isEmpty
              ? _EmptyBook(onGoToRecord: widget.onGoToRecord)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        var scale = 1.0;
                        var rotateY = 0.0;
                        if (_pageController.position.haveDimensions) {
                          final delta = (_pageController.page ?? 0) - index;
                          scale = (1 - delta.abs() * 0.06).clamp(0.9, 1.0);
                          rotateY = (-delta * 0.18).clamp(-0.25, 0.25);
                        }
                        return Transform(
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotateY)
                            ..scale(scale),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: JournalBookPage(
                          entry: entry,
                          pageNumber: entries.length - index,
                          totalPages: entries.length,
                          scrollable: _embedded,
                          onTap: () {
                            context.read<AnalyticsService>().logDiaryOpen(source: 'spread');
                            showEntryDaySheet(context, entry);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (entries.isNotEmpty && !_embedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              '← 과거 · → 최근',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
            ),
          ),
      ],
    );

    if (_embedded) {
      return body;
    }

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: body,
        ),
      ),
    );
  }

  static bool _isTodayBlank(DailyEntry? e) {
    if (e == null) return true;
    return !e.hasPhotos &&
        (e.note == null || e.note!.trim().isEmpty) &&
        e.moodEmoji == null &&
        EntryDiaryAi.primaryDiaryText(e) == null &&
        e.weatherDisplayLine == null;
  }
}

class _EmptyBook extends StatelessWidget {
  const _EmptyBook({this.onGoToRecord});

  final VoidCallback? onGoToRecord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined, size: 56, color: AppTheme.accent.withValues(alpha: 0.45)),
            const SizedBox(height: 20),
            Text('아직 빈 책이에요', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '오늘 한 페이지를 쓰면\n여기서 책장처럼 넘겨 볼 수 있어요.',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
              textAlign: TextAlign.center,
            ),
            if (onGoToRecord != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onGoToRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text('첫 페이지 쓰기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayPagePrompt extends StatelessWidget {
  const _TodayPagePrompt({this.onGoToRecord});

  final VoidCallback? onGoToRecord;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('M월 d일 · EEEE', 'ko_KR');
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onGoToRecord,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${dateFmt.format(DateTime.now())} · 오늘 페이지가 비어 있어요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.inkMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
