import '../constants/app_fonts.dart';
import 'book_calendar_layout.dart';
import 'book_layout_engine.dart';
import 'book_layout_types.dart';
import 'book_pdf_diary_block.dart';
import 'book_pdf_layout_metrics.dart';
import 'book_pdf_style.dart';

enum BookPdfPreviewPageKind { cover, calendar, diary, emptyMessage }

class BookPdfPreviewPage {
  const BookPdfPreviewPage.cover(this.bookTitle)
      : kind = BookPdfPreviewPageKind.cover,
        calendarLayout = null,
        diaryBlocks = null,
        topInset = 0;

  const BookPdfPreviewPage.calendar(this.calendarLayout)
      : kind = BookPdfPreviewPageKind.calendar,
        bookTitle = null,
        diaryBlocks = null,
        topInset = 0;

  const BookPdfPreviewPage.diary(this.diaryBlocks, {this.topInset = 0})
      : kind = BookPdfPreviewPageKind.diary,
        bookTitle = null,
        calendarLayout = null;

  const BookPdfPreviewPage.emptyMessage()
      : kind = BookPdfPreviewPageKind.emptyMessage,
        bookTitle = null,
        calendarLayout = null,
        diaryBlocks = null,
        topInset = 0;

  final BookPdfPreviewPageKind kind;
  final String? bookTitle;
  final BookCalendarMonthLayout? calendarLayout;
  final List<BookDiaryBlock>? diaryBlocks;
  /// chapter_admin `centeredEntryStartY` — 짧은 글·월 첫 일기 세로 중앙
  final double topInset;
}

/// chapter_admin `generateBookPdf` 페이지 순서와 동일
class BookPdfPreviewPlanner {
  BookPdfPreviewPlanner._();

  static List<BookPdfPreviewPage> plan({
    required List<BookDiaryEntry> entries,
    required String bookTitle,
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final pages = <BookPdfPreviewPage>[BookPdfPreviewPage.cover(bookTitle)];

    if (sorted.isEmpty) {
      pages.add(const BookPdfPreviewPage.emptyMessage());
      return pages;
    }

    for (final month in BookCalendarLayout.listMonthsWithEntries(sorted)) {
      final monthEntries =
          BookCalendarLayout.entriesForMonth(sorted, month.year, month.month);
      final entriesByDate = BookCalendarLayout.indexEntriesByDate(monthEntries);
      final calendarLayout = BookCalendarLayout.buildCalendarMonthLayout(
        year: month.year,
        month: month.month,
        gridWidth: BookPdfPageSpec.contentWidth,
        entriesByDate: entriesByDate,
      );

      pages.add(BookPdfPreviewPage.calendar(calendarLayout));
      pages.addAll(
        _planDiaryPages(
          monthEntries,
          diaryFontId: diaryFontId,
        ),
      );
    }

    return pages;
  }

  static double get _pageHeight =>
      BookPdfStyle.pageContentHeight - BookPdfLayoutMetrics.pageSafetyMargin;

  /// chapter_admin `renderMonthEntries` — 1 entry = 1 page (본문 넘침 시 추가 페이지)
  static List<BookPdfPreviewPage> _planDiaryPages(
    List<BookDiaryEntry> entries, {
    required AppFontId diaryFontId,
  }) {
    final pages = <BookPdfPreviewPage>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final plan = BookLayoutEngine.decideLayout(entry);
      final isFull = plan.pageMode == BookPageMode.full;
      final compact = !isFull;

      final entryPages = _planSingleEntryPages(
        entry: entry,
        plan: plan,
        isFull: isFull,
        compact: compact,
        diaryFontId: diaryFontId,
      );

      if (entryPages.isEmpty) continue;

      if (_shouldCenterEntryOnPage(i, plan)) {
        final firstBlocks = entryPages.first.diaryBlocks!;
        final totalHeight = BookPdfLayoutMetrics.pageBlocksHeight(
          firstBlocks,
          diaryFontId: diaryFontId,
        );
        final topInset = _centeredEntryStartY(totalHeight);
        entryPages[0] = BookPdfPreviewPage.diary(firstBlocks, topInset: topInset);
      }

      pages.addAll(entryPages);
    }

    return pages;
  }

  static bool _shouldCenterEntryOnPage(int entryIndexInMonth, BookLayoutPlan plan) =>
      entryIndexInMonth == 0 || plan.pageMode == BookPageMode.compact;

  static double _centeredEntryStartY(double entryHeight) {
    final available = _pageHeight;
    if (entryHeight >= available) return 0;
    return (available - entryHeight) / 2;
  }

  static List<BookPdfPreviewPage> _planSingleEntryPages({
    required BookDiaryEntry entry,
    required BookLayoutPlan plan,
    required bool isFull,
    required bool compact,
    required AppFontId diaryFontId,
  }) {
    final pages = <BookPdfPreviewPage>[];
    var blocks = <BookDiaryBlock>[];
    var usedHeight = 0.0;

    void flush() {
      if (blocks.isEmpty) return;
      pages.add(BookPdfPreviewPage.diary(List.unmodifiable(blocks)));
      blocks = [];
      usedHeight = 0;
    }

    void ensureSpace(double needed) {
      if (usedHeight + needed > _pageHeight) flush();
    }

    void addBlock(BookDiaryBlock block) {
      final height = BookPdfLayoutMetrics.blockHeight(
        block,
        diaryFontId: diaryFontId,
      );
      ensureSpace(height);
      blocks.add(block);
      usedHeight += height;
    }

    addBlock(BookDiaryHeaderBlock(entry));

    if (isFull && entry.photoCount > 0) {
      addBlock(BookDiaryPhotosBlock(entry));
    }

    if (entry.body.isEmpty) {
      flush();
      return pages;
    }

    var remaining = entry.body.trim();
    final minLines = BookPdfLayoutMetrics.minLinesForPlan(plan, compact: compact);

    while (remaining.isNotEmpty) {
      final available = _pageHeight - usedHeight;
      final minBlockHeight = BookPdfLayoutMetrics.textBlockHeight(
        '가',
        plan,
        minLines: minLines.clamp(1, minLines),
        diaryFontId: diaryFontId,
      );

      if (available < minBlockHeight) {
        flush();
        continue;
      }

      final chunk = BookPdfLayoutMetrics.fitTextChunk(
        remaining,
        plan,
        maxBoxHeight: available,
        minLines: minLines,
        diaryFontId: diaryFontId,
      );

      if (chunk.isEmpty) {
        flush();
        continue;
      }

      addBlock(
        BookDiaryTextBlock(
          entry: entry,
          text: chunk,
          plan: plan,
          compact: compact,
        ),
      );

      remaining = remaining.substring(chunk.length).trimLeft();
      if (remaining.isNotEmpty) flush();
    }

    flush();
    return pages;
  }
}
