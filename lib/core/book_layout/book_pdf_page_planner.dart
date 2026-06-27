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
        diaryBlocks = null;

  const BookPdfPreviewPage.calendar(this.calendarLayout)
      : kind = BookPdfPreviewPageKind.calendar,
        bookTitle = null,
        diaryBlocks = null;

  const BookPdfPreviewPage.diary(this.diaryBlocks)
      : kind = BookPdfPreviewPageKind.diary,
        bookTitle = null,
        calendarLayout = null;

  const BookPdfPreviewPage.emptyMessage()
      : kind = BookPdfPreviewPageKind.emptyMessage,
        bookTitle = null,
        calendarLayout = null,
        diaryBlocks = null;

  final BookPdfPreviewPageKind kind;
  final String? bookTitle;
  final BookCalendarMonthLayout? calendarLayout;
  final List<BookDiaryBlock>? diaryBlocks;
}

/// chapter_admin `generateBookPdf` 페이지 순서와 동일
class BookPdfPreviewPlanner {
  BookPdfPreviewPlanner._();

  static List<BookPdfPreviewPage> plan({
    required List<BookDiaryEntry> entries,
    required String bookTitle,
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
      pages.addAll(_planDiaryPages(monthEntries));
    }

    return pages;
  }

  static double get _pageHeight =>
      BookPdfStyle.pageContentHeight - BookPdfLayoutMetrics.pageSafetyMargin;

  static List<BookPdfPreviewPage> _planDiaryPages(List<BookDiaryEntry> entries) {
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
      final height = BookPdfLayoutMetrics.blockHeight(block);
      ensureSpace(height);
      blocks.add(block);
      usedHeight += height;
    }

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final plan = BookLayoutEngine.decideLayout(entry);
      final isFull = plan.pageMode == BookPageMode.full;

      if (i > 0 && usedHeight > 0) {
        addBlock(const BookDiaryEntryGapBlock());
      }

      addBlock(BookDiaryHeaderBlock(entry));

      if (isFull && entry.photoCount > 0) {
        addBlock(BookDiaryPhotosBlock(entry));
      }

      if (entry.body.isEmpty) continue;

      var remaining = entry.body.trim();
      final compact = !isFull;
      final minLines = BookPdfLayoutMetrics.minLinesForPlan(plan, compact: compact);

      while (remaining.isNotEmpty) {
        final available = _pageHeight - usedHeight;
        final minBlockHeight = BookPdfLayoutMetrics.textBlockHeight(
          '가',
          plan,
          minLines: minLines.clamp(1, minLines),
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
    }

    flush();
    return pages;
  }
}
