import 'package:flutter/material.dart';

import '../core/book_layout/book_pdf_body_style.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/constants/app_fonts.dart';
import '../core/constants/book_cover_type.dart';
import '../core/utils/book_cover_date_range.dart';
import '../core/book_layout/book_pdf_page_planner.dart';
import '../core/book_layout/book_pdf_photo_meta.dart';
import '../core/book_layout/book_pdf_style.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/theme/app_theme.dart';
import '../models/book_entry_snapshot.dart';
import '../models/daily_entry.dart';
import 'book_cover_artwork.dart';
import 'book_diary_page_renderer.dart';
import 'book_pdf_calendar_page.dart';
<<<<<<< Updated upstream
=======
import 'book_pdf_text_box.dart';
import 'book_pdf_photo_tile.dart';
>>>>>>> Stashed changes

/// chapter_admin PDF generator와 동일 레이아웃의 책 미리보기
class BookPdfPreview extends StatefulWidget {
  const BookPdfPreview({
    super.key,
    required this.diaryEntries,
    required this.bookTitle,
    this.coverType = BookCoverType.chapterIcon,
    this.coverDateRangeLabel = '',
    this.coverPhotoUri,
    this.coverTitle,
    this.diaryFontId = kDefaultDiaryFontId,
    this.bodyStyle = BookEntryBodyStyles.previewDefault,
  });

  final List<BookDiaryEntry> diaryEntries;
  final String bookTitle;
  final String coverType;
  final String coverDateRangeLabel;
  final String? coverPhotoUri;
  final String? coverTitle;
  final AppFontId diaryFontId;
  final BookEntryBodyStyle bodyStyle;

  factory BookPdfPreview.fromDailyEntries({
    Key? key,
    required List<DailyEntry> entries,
    required String bookTitle,
    String? coverType,
    String? coverDateRangeLabel,
    String? coverPhotoUri,
    String? coverTitle,
    AppFontId? diaryFontId,
    BookEntryBodyStyle? bodyStyle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromDailyEntries(entries),
      bookTitle: bookTitle,
      coverType: coverType ?? BookCoverType.chapterIcon,
      coverDateRangeLabel: coverDateRangeLabel ?? bookCoverDateRangeLabel(entries),
      coverPhotoUri: coverPhotoUri,
      coverTitle: coverTitle,
      diaryFontId: diaryFontId ?? kDefaultDiaryFontId,
      bodyStyle: bodyStyle ?? BookEntryBodyStyles.previewDefault,
    );
  }

  factory BookPdfPreview.fromSnapshots({
    Key? key,
    required List<BookEntrySnapshot> snapshots,
    required String bookTitle,
    String? coverType,
    String? coverDateRangeLabel,
    String? coverPhotoUri,
    String? coverTitle,
    String? diaryFontId,
    BookEntryBodyStyle? bodyStyle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromSnapshots(snapshots),
      bookTitle: bookTitle,
      coverType: coverType ?? BookCoverType.chapterIcon,
      coverDateRangeLabel: coverDateRangeLabel ?? bookCoverDateRangeFromSnapshots(snapshots),
      coverPhotoUri: coverPhotoUri,
      coverTitle: coverTitle,
      diaryFontId: appFontIdFromKey(diaryFontId, fallback: kDefaultDiaryFontId),
      bodyStyle: bodyStyle ?? BookEntryBodyStyles.previewDefault,
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

  @override
  void didUpdateWidget(covariant BookPdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryEntries != widget.diaryEntries ||
        oldWidget.bookTitle != widget.bookTitle ||
        oldWidget.diaryFontId != widget.diaryFontId ||
        oldWidget.bodyStyle != widget.bodyStyle) {
      _loadPages();
    }
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
        diaryFontId: widget.diaryFontId,
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
              return BookPdfPageFrame(
                child: switch (page.kind) {
                  BookPdfPreviewPageKind.cover =>
                    _BookPdfCoverPage(
                      coverType: widget.coverType,
                      dateRangeLabel: widget.coverDateRangeLabel,
                      photoUri: widget.coverPhotoUri,
                      coverTitle: widget.coverTitle,
                    ),
                  BookPdfPreviewPageKind.calendar =>
                    BookPdfCalendarPage(layout: page.calendarLayout!),
                  BookPdfPreviewPageKind.diary =>
                    BookPdfDiaryPageContent(
                      blocks: page.diaryBlocks!,
                      topInset: page.topInset,
                      diaryFontId: widget.diaryFontId,
                      bodyStyle: widget.bodyStyle,
                    ),
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
      ],
    );
  }
}

class _BookPdfCoverPage extends StatelessWidget {
  const _BookPdfCoverPage({
    required this.coverType,
    required this.dateRangeLabel,
    this.photoUri,
    this.coverTitle,
  });

  final String coverType;
  final String dateRangeLabel;
  final String? photoUri;
  final String? coverTitle;

  @override
  Widget build(BuildContext context) {
    return BookCoverArtwork(
      coverType: coverType,
      dateRangeLabel: dateRangeLabel,
      photoUri: photoUri,
      coverTitle: coverTitle,
      coverYear: DateTime.now().year,
      fillPage: true,
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
<<<<<<< Updated upstream
=======

class _BookPdfDiaryPage extends StatelessWidget {
  const _BookPdfDiaryPage({
    required this.blocks,
    required this.topInset,
    required this.diaryFontId,
    required this.bodyStyle,
  });

  final List<BookDiaryBlock> blocks;
  final double topInset;
  final AppFontId diaryFontId;
  final BookEntryBodyStyle bodyStyle;

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
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final block in blocks)
                      switch (block) {
                        BookDiaryEntryGapBlock() =>
                          const SizedBox(height: BookPdfStyle.entryGap),
                        BookDiaryHeaderBlock(:final entry) =>
                          _BookPdfEntryHeader(
                            entry: entry,
                            diaryFontId: diaryFontId,
                          ),
                        BookDiaryPhotosBlock(:final entry) =>
                          _BookPdfPhotoSection(entry: entry),
                        BookDiaryTextBlock(:final text, :final plan, :final compact) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.boxGap),
                            child: BookPdfTextBox(
                              text: text,
                              plan: plan,
                              minLines: BookPdfLayoutMetrics.minLinesForPlan(
                                plan,
                                compact: compact,
                              ),
                              diaryFontId: diaryFontId,
                              bodyStyle: bodyStyle,
                            ),
                          ),
                      },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPdfEntryHeader extends StatelessWidget {
  const _BookPdfEntryHeader({
    required this.entry,
    required this.diaryFontId,
  });

  final BookDiaryEntry entry;
  final AppFontId diaryFontId;

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
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: BookPdfStyle.dateSize,
                    height: 1.2,
                    color: BookPdfStyle.title,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (moodLabel != null)
                Text(
                  moodLabel,
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: BookPdfStyle.moodSize,
                    height: 1.2,
                    color: BookPdfStyle.muted,
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
    final maxLong = photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;

    final stickerItems = List.generate(
      photoCount,
      (i) => BookStickerItem(index: i, meta: metas[i]),
    );

    final collage = BookStickerCollage.layoutStickerCollage(
      stickerItems,
      outerWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLong),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
      child: SizedBox(
        width: outerWidth,
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
    );
  }
}
>>>>>>> Stashed changes
