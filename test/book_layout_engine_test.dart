import 'package:chapter/core/book_layout/book_layout_engine.dart';
import 'package:chapter/core/book_layout/book_layout_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BookDiaryEntry entry({
    required String date,
    required String title,
    required String body,
    List<String> photoUris = const [],
  }) {
    return BookDiaryEntry(
      date: date,
      title: title,
      body: body,
      photoUris: photoUris,
    );
  }

  test('사진 1장 + 긴 글 → single-photo-vertical', () {
    final plan = BookLayoutEngine.decideLayout(
      entry(
        date: '2026-03-01',
        title: '3월 1일',
        body: '가' * 500,
        photoUris: ['https://example.com/1.jpg'],
      ),
    );
    expect(plan.type, BookLayoutType.singlePhotoVertical);
    expect(plan.textStyle, BookTextStyle.fullStyle);
    expect(plan.photoSlots.length, 1);
  });

  test('사진 4장 + 짧은 글 → photo-grid', () {
    final plan = BookLayoutEngine.decideLayout(
      entry(
        date: '2026-03-02',
        title: '3월 2일',
        body: '짧은 코멘트',
        photoUris: ['a', 'b', 'c', 'd'],
      ),
    );
    expect(plan.type, BookLayoutType.photoGrid);
    expect(plan.textStyle, BookTextStyle.caption);
    expect(plan.gridColumns, 2);
    expect(plan.gridRows, 2);
    expect(plan.photoSlots.length, 4);
  });

  test('사진 없음 + 짧은 글 → compact', () {
    final plan = BookLayoutEngine.decideLayout(
      entry(
        date: '2026-03-05',
        title: '짧은 일기',
        body: '오늘은 날씨가 좋았다.',
      ),
    );
    expect(plan.type, BookLayoutType.textOnly);
    expect(plan.pageMode, BookPageMode.compact);
  });

  test('planBookPages — 일기마다 한 페이지', () {
    BookDiaryEntry short(int n) => entry(
          date: '2026-03-0$n',
          title: '일기 $n',
          body: '짧은 본문 $n',
        );

    final pages = BookLayoutEngine.planBookPages([short(1), short(2), short(3), short(4)]);
    expect(pages.length, 4);
    for (final page in pages) {
      expect(page.items.length, 1);
    }
  });
}
