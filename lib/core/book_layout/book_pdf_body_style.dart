/// chapter_admin `pdf/bodyStyle.ts` · `pdf/entryStyle.ts`
enum BookEntryBodyStyle {
  notebook,
  marginRail,
  dotGrid,
  wash,
  tape,
  minimal,
}

class BookEntryBodyStyles {
  BookEntryBodyStyles._();

  /// admin `generateBookPdf` — 본문 스타일 4번(워시)
  static const previewDefault = BookEntryBodyStyle.wash;

  static const catalog = [
    (index: 1, id: BookEntryBodyStyle.notebook, label: '공책 줄무늬'),
    (index: 2, id: BookEntryBodyStyle.marginRail, label: '마진 레일'),
    (index: 3, id: BookEntryBodyStyle.dotGrid, label: '도트 그리드'),
    (index: 4, id: BookEntryBodyStyle.wash, label: '워시 배경'),
    (index: 5, id: BookEntryBodyStyle.tape, label: '마스킹 테이프'),
    (index: 6, id: BookEntryBodyStyle.minimal, label: '미니멀'),
  ];

  static BookEntryBodyStyle fromIndex(int index) {
    for (final item in catalog) {
      if (item.index == index) return item.id;
    }
    return previewDefault;
  }
}
