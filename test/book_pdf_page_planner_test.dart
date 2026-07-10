import 'package:chapter/core/book_layout/book_layout_engine.dart';
import 'package:chapter/core/book_layout/book_layout_types.dart';
import 'package:chapter/core/book_layout/book_pdf_diary_block.dart';
import 'package:chapter/core/book_layout/book_pdf_layout_metrics.dart';
import 'package:chapter/core/book_layout/book_pdf_page_planner.dart';
import 'package:chapter/core/book_layout/book_pdf_style.dart';
import 'package:chapter/core/book_layout/book_preview_entry_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plan — 표지 → 월 캘린더 → 일기 페이지 순서', () {
    final pages = BookPdfPreviewPlanner.plan(
      bookTitle: '나의 책',
      entries: [
        const BookDiaryEntry(
          date: '2026-03-01',
          title: '',
          body: '3월 첫날',
        ),
        const BookDiaryEntry(
          date: '2026-04-02',
          title: '',
          body: '4월 둘째날',
        ),
      ],
    );

    expect(pages.first.kind, BookPdfPreviewPageKind.cover);
    expect(
      pages.where((p) => p.kind == BookPdfPreviewPageKind.calendar).length,
      2,
    );
    expect(pages.any((p) => p.kind == BookPdfPreviewPageKind.diary), isTrue);
  });

  test('diary 페이지 — 일기마다 별도 페이지', () {
    final pages = BookPdfPreviewPlanner.plan(
      bookTitle: '나의 책',
      entries: [
        const BookDiaryEntry(
          date: '2026-03-01',
          title: '',
          body: '3월 첫날',
        ),
        const BookDiaryEntry(
          date: '2026-03-02',
          title: '',
          body: '3월 둘째날',
        ),
        const BookDiaryEntry(
          date: '2026-04-02',
          title: '',
          body: '4월 둘째날',
        ),
      ],
    );

    final diaryPages = pages.where((p) => p.kind == BookPdfPreviewPageKind.diary).toList();
    expect(diaryPages.length, 3);
  });

  test('diary 페이지 블록 높이가 콘텐츠 영역을 넘지 않음', () {
    final pages = BookPdfPreviewPlanner.plan(
      bookTitle: '나의 책',
      entries: [
        BookDiaryEntry(
          date: '2026-03-01',
          title: '',
          body: '오늘은 ' * 120,
          photoUris: const ['https://example.com/a.jpg'],
        ),
        const BookDiaryEntry(
          date: '2026-03-02',
          title: '',
          body: '짧은 하루',
          moodEmoji: '☕',
        ),
      ],
    );

    for (final page in pages) {
      if (page.kind != BookPdfPreviewPageKind.diary) continue;
      final height = BookPdfLayoutMetrics.pageBlocksHeight(page.diaryBlocks!);
      expect(
        height,
        lessThanOrEqualTo(BookPdfStyle.pageContentHeight + 1),
      );
    }
  });

  test('planSingleEntry — 단일 일기 헤더·본문 페이지', () {
    final pages = BookPdfPreviewPlanner.planSingleEntry(
      entry: const BookDiaryEntry(
        date: '2026-07-10',
        title: '',
        body: 'Phase A 테스트',
        moodEmoji: '☀️',
        moodLabel: '맑음',
      ),
    );

    expect(pages, isNotEmpty);
    expect(pages.first.kind, BookPdfPreviewPageKind.diary);
    expect(pages.first.diaryBlocks, isNotEmpty);
  });

  test('planSingleEntry — 사진 3장 그리드 레이아웃', () {
    final entry = BookPreviewEntryMapper.fromDraft(
      date: DateTime(2026, 7, 10),
      note: '짧은 글',
      photoUris: const ['a.jpg', 'b.jpg', 'c.jpg'],
    );
    final plan = BookLayoutEngine.decideLayout(entry);
    expect(plan.type, BookLayoutType.photoGrid);

    final pages = BookPdfPreviewPlanner.planSingleEntry(entry: entry);
    expect(pages.first.diaryBlocks!.any((b) => b is BookDiaryPhotosBlock), isTrue);
  });
}
