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
