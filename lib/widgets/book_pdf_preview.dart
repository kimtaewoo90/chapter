import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_photo_style.dart';
import '../core/book_layout/book_pdf_diary_block.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_page_planner.dart';
import '../core/book_layout/book_pdf_photo_meta.dart';
import '../core/book_layout/book_pdf_style.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/book_layout/book_sticker_collage.dart';
import '../core/theme/app_theme.dart';
import '../models/book_entry_snapshot.dart';
import '../models/daily_entry.dart';
import 'book_pdf_calendar_page.dart';
import 'book_pdf_notebook_box.dart';
import 'book_pdf_photo_tile.dart';

/// chapter_admin PDF generator와 동일 레이아웃의 책 미리보기
class BookPdfPreview extends StatefulWidget {
  const BookPdfPreview({
    super.key,
    required this.diaryEntries,
    required this.bookTitle,
  });

  final List<BookDiaryEntry> diaryEntries;
  final String bookTitle;

  factory BookPdfPreview.fromDailyEntries({
    Key? key,
    required List<DailyEntry> entries,
    required String bookTitle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromDailyEntries(entries),
      bookTitle: bookTitle,
    );
  }

  factory BookPdfPreview.fromSnapshots({
    Key? key,
    required List<BookEntrySnapshot> snapshots,
    required String bookTitle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromSnapshots(snapshots),
      bookTitle: bookTitle,
    );
  }

  @override
  State<BookPdfPreview> createState() => _BookPdfPreviewState();
}

class _BookPdfPreviewState extends State<BookPdfPreview> {
  late final PageController _controller;
  int _pageIndex = 0;
  List<BookPdfPreviewPage> _pages = const [];
  bool _pagesReady = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final uris = widget.diaryEntries
        .expand((entry) => entry.photoUris)
        .where((uri) => uri.isNotEmpty);
    await BookPdfPhotoMeta.preload(uris);
    if (!mounted) return;
    setState(() {
      _pages = BookPdfPreviewPlanner.plan(
        entries: widget.diaryEntries,
        bookTitle: widget.bookTitle,
      );
      _pagesReady = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_pagesReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.inkMuted.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '미리보기 준비 중…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.inkMuted,
                ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _BookPdfPageShell(
                paperBackground: page.kind != BookPdfPreviewPageKind.cover,
                child: switch (page.kind) {
                  BookPdfPreviewPageKind.cover =>
                    _BookPdfCoverPage(title: page.bookTitle ?? widget.bookTitle),
                  BookPdfPreviewPageKind.calendar =>
                    BookPdfCalendarPage(layout: page.calendarLayout!),
                  BookPdfPreviewPageKind.diary =>
                    _BookPdfDiaryPage(blocks: page.diaryBlocks!),
                  BookPdfPreviewPageKind.emptyMessage => const _BookPdfEmptyPage(),
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _pageIndex > 0
                  ? () => _controller.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      )
                  : null,
            ),
            Text(
              '${_pageIndex + 1} / ${_pages.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkMuted,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _pageIndex < _pages.length - 1
                  ? () => _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '좌우로 넘기면 실제 인쇄 PDF와 같은 배치로 볼 수 있어요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.inkMuted,
              ),
        ),
      ],
    );
  }
}

class _BookPdfPageShell extends StatelessWidget {
  const _BookPdfPageShell({
    required this.child,
    this.paperBackground = false,
  });

  final Widget child;
  final bool paperBackground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paperBackground ? BookPdfStyle.paper : Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmShadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: BookPdfPageSpec.width,
              height: BookPdfPageSpec.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPdfCoverPage extends StatelessWidget {
  const _BookPdfCoverPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const centerY = BookPdfPageSpec.height * 0.38;
    const margin = BookPdfPageSpec.margin;
    const contentWidth = BookPdfPageSpec.contentWidth;

    return Stack(
      children: [
        Positioned(
          left: margin + 40,
          right: margin + 40,
          top: centerY + 50,
          child: Container(height: 0.5, color: BookPdfStyle.line),
        ),
        Positioned(
          left: margin,
          top: centerY - 20,
          width: contentWidth,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: BookPdfStyle.title,
              height: 1.25,
            ),
          ),
        ),
        Positioned(
          left: margin,
          top: centerY + 64,
          width: contentWidth,
          child: const Text(
            'Chapter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: BookPdfStyle.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookPdfEmptyPage extends StatelessWidget {
  const _BookPdfEmptyPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BookPdfPageSpec.margin),
        child: Text(
          '스냅샷에 일기가 없습니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BookPdfStyle.subtitle,
              ),
        ),
      ),
    );
  }
}

class _BookPdfDiaryPage extends StatelessWidget {
  const _BookPdfDiaryPage({required this.blocks});

  final List<BookDiaryBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BookPdfStyle.paper,
      child: Padding(
        padding: const EdgeInsets.all(BookPdfPageSpec.margin),
        child: SizedBox(
          height: BookPdfStyle.pageContentHeight,
          width: BookPdfPageSpec.contentWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                for (final block in blocks)
                  switch (block) {
                    BookDiaryEntryGapBlock() =>
                      const SizedBox(height: BookPdfStyle.entryGap),
                    BookDiaryHeaderBlock(:final entry) =>
                      _BookPdfEntryHeader(entry: entry),
                    BookDiaryPhotosBlock(:final entry) =>
                      _BookPdfPhotoSection(entry: entry),
                    BookDiaryTextBlock(:final text, :final plan, :final compact) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.boxGap),
                        child: BookPdfNotebookBox(
                          text: text,
                          plan: plan,
                          minLines: BookPdfLayoutMetrics.minLinesForPlan(
                            plan,
                            compact: compact,
                          ),
                        ),
                      ),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPdfEntryHeader extends StatelessWidget {
  const _BookPdfEntryHeader({required this.entry});

  final BookDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateLabel = entry.date.isNotEmpty
        ? BookPreviewEntryMapper.formatDateLabel(entry.date)
        : '';
    final moodLabel = BookPreviewEntryMapper.formatMoodDisplay(
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dateLabel.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: BookPdfStyle.dateSize,
                    fontWeight: FontWeight.w600,
                    color: BookPdfStyle.title,
                    height: 1.2,
                  ),
                ),
              ),
              if (moodLabel != null)
                Text(
                  moodLabel,
                  style: const TextStyle(
                    fontSize: BookPdfStyle.moodSize,
                    color: BookPdfStyle.muted,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        if (dateLabel.isNotEmpty) const SizedBox(height: BookPdfStyle.dateGap),
        Container(height: 0.5, color: BookPdfStyle.line),
        const SizedBox(height: BookPdfStyle.headerBottomGap),
      ],
    );
  }
}

class _BookPdfPhotoSection extends StatefulWidget {
  const _BookPdfPhotoSection({required this.entry});

  final BookDiaryEntry entry;

  @override
  State<_BookPdfPhotoSection> createState() => _BookPdfPhotoSectionState();
}

class _BookPdfPhotoSectionState extends State<_BookPdfPhotoSection> {
  late final Future<List<BookImageMeta>> _metaFuture;

  @override
  void initState() {
    super.initState();
    _metaFuture = BookPdfPhotoMeta.resolveAll(widget.entry.photoUris);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookImageMeta>>(
      future: _metaFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          final estimated = BookPdfLayoutMetrics.photoBlockHeight(widget.entry);
          if (estimated <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
            child: SizedBox(
              width: BookPdfPageSpec.contentWidth,
              height: estimated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BookEntryBoxStyle.photoBg,
                  borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
                  border: Border.all(color: BookEntryBoxStyle.border, width: 0.6),
                ),
              ),
            ),
          );
        }

        return _BookPdfPhotoCollage(
          entry: widget.entry,
          metas: snapshot.data!,
        );
      },
    );
  }
}

class _BookPdfPhotoCollage extends StatelessWidget {
  const _BookPdfPhotoCollage({
    required this.entry,
    required this.metas,
  });

  final BookDiaryEntry entry;
  final List<BookImageMeta> metas;

  @override
  Widget build(BuildContext context) {
    final photoCount = entry.photoCount;
    final outerWidth = BookPdfPageSpec.contentWidth;
    final innerWidth = BookEntryBoxStyle.photoInnerWidth(outerWidth);
    final maxLong = photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;

    final stickerItems = List.generate(
      photoCount,
      (i) => BookStickerItem(index: i, meta: metas[i]),
    );

    final collage = BookStickerCollage.layoutStickerCollage(
      stickerItems,
      innerWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLong),
    );

    final boxHeight = collage.totalHeight + BookEntryBoxStyle.pad * 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
      child: SizedBox(
        width: outerWidth,
        height: boxHeight,
        child: CustomPaint(
          painter: _PhotoFrameBoxPainter(),
          child: Padding(
            padding: const EdgeInsets.all(BookEntryBoxStyle.pad),
            child: SizedBox(
              width: innerWidth,
              height: collage.totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final placement in collage.placements)
                    Positioned(
                      left: placement.x,
                      top: placement.y,
                      width: placement.photoW,
                      height: placement.photoH,
                      child: BookPdfPhotoTile(
                        uri: entry.photoUris[placement.index],
                        meta: metas[placement.index],
                        slotW: placement.photoW,
                        slotH: placement.photoH,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoFrameBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(BookEntryBoxStyle.radius),
    );
    canvas.drawRRect(rrect, Paint()..color = BookEntryBoxStyle.photoBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = BookEntryBoxStyle.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
