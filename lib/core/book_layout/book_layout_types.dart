/// chapter_admin `layout/types.js` — PDF 레이아웃 상수·타입

enum BookLayoutType {
  textOnly,
  singlePhotoVertical,
  dualPhoto,
  photoGrid,
}

enum BookPageMode { full, compact }

enum BookTextStyle { caption, shortStyle, fullStyle }

class BookLayoutThresholds {
  BookLayoutThresholds._();

  static const longText = 200;
  static const shortText = 150;
  static const compactTextMax = 120;
  static const gridPhotoMin = 3;
  static const pageContentHeight = 499.0;
  static const itemGap = 32.0;
}

class BookPdfPageSpec {
  BookPdfPageSpec._();

  static const width = 420.0;
  static const height = 595.0;
  static const margin = 48.0;
  static const contentWidth = width - margin * 2;
}

class BookDiaryEntry {
  const BookDiaryEntry({
    required this.date,
    required this.title,
    required this.body,
    this.photoUris = const [],
    this.moodEmoji,
    this.moodLabel,
  });

  final String date;
  final String title;
  final String body;
  final List<String> photoUris;
  final String? moodEmoji;
  final String? moodLabel;

  int get photoCount => photoUris.length;
}

class BookPhotoSlot {
  const BookPhotoSlot({
    required this.index,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
  });

  final int index;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
}

class BookLayoutPlan {
  const BookLayoutPlan({
    required this.type,
    required this.photoSlots,
    required this.textStyle,
    required this.gridColumns,
    required this.gridRows,
    required this.pageMode,
  });

  final BookLayoutType type;
  final List<BookPhotoSlot> photoSlots;
  final BookTextStyle textStyle;
  final int gridColumns;
  final int gridRows;
  final BookPageMode pageMode;
}

class BookEntryLayout {
  const BookEntryLayout({required this.entry, required this.plan});

  final BookDiaryEntry entry;
  final BookLayoutPlan plan;
}

class BookPageItem {
  const BookPageItem.full(this.layout) : kind = BookPageItemKind.full;

  const BookPageItem.compact(this.layout) : kind = BookPageItemKind.compact;

  final BookPageItemKind kind;
  final BookEntryLayout layout;
}

enum BookPageItemKind { full, compact }

class BookPagePlan {
  const BookPagePlan({required this.items});

  final List<BookPageItem> items;
}
