import 'book_layout_types.dart';
import 'book_photo_style.dart';
import 'book_sticker_collage.dart';

/// chapter_admin `layout/engine.js` — PDF 페이지 배치
class BookLayoutEngine {
  BookLayoutEngine._();

  static const _contentWidth = BookPdfPageSpec.contentWidth;

  static BookLayoutPlan decideLayout(BookDiaryEntry entry) {
    final photoCount = entry.photoCount;
    final textLength = entry.body.trim().length;
    final type = _pickLayoutType(photoCount, textLength);
    final textStyle = _pickTextStyle(type, textLength);
    final slots = _buildPhotoSlots(type, photoCount);
    final pageMode = decidePageMode(photoCount, textLength, type: type);

    return BookLayoutPlan(
      type: type,
      photoSlots: slots.photoSlots,
      textStyle: textStyle,
      gridColumns: slots.gridColumns,
      gridRows: slots.gridRows,
      pageMode: pageMode,
    );
  }

  static BookPageMode decidePageMode(
    int photoCount,
    int textLength, {
    BookLayoutType? type,
  }) {
    final layoutType = type ?? _pickLayoutType(photoCount, textLength);
    if (layoutType != BookLayoutType.textOnly) return BookPageMode.full;
    if (textLength >= BookLayoutThresholds.longText) return BookPageMode.full;
    if (textLength <= BookLayoutThresholds.compactTextMax) {
      return BookPageMode.compact;
    }
    return BookPageMode.full;
  }

  static List<BookPagePlan> planBookPages(List<BookDiaryEntry> entries) {
    final pages = <BookPagePlan>[];
    var currentItems = <BookPageItem>[];
    var usedHeight = 0.0;

    void flush() {
      if (currentItems.isNotEmpty) {
        pages.add(BookPagePlan(items: List.unmodifiable(currentItems)));
        currentItems = [];
        usedHeight = 0;
      }
    }

    bool tryAdd(BookPageItem item) {
      final height = _estimateItemHeight(item);
      final gap = currentItems.isNotEmpty ? BookLayoutThresholds.itemGap : 0;
      if (usedHeight + gap + height > BookLayoutThresholds.pageContentHeight) {
        return false;
      }
      currentItems.add(item);
      usedHeight += gap + height;
      return true;
    }

    void forceAdd(BookPageItem item) {
      final height = _estimateItemHeight(item);
      currentItems.add(item);
      usedHeight = height;
    }

    for (final entry in entries) {
      final plan = decideLayout(entry);
      final layout = BookEntryLayout(entry: entry, plan: plan);
      final item = plan.pageMode == BookPageMode.full
          ? BookPageItem.full(layout)
          : BookPageItem.compact(layout);

      if (!tryAdd(item)) {
        flush();
        if (!tryAdd(item)) {
          forceAdd(item);
          flush();
        }
      }
    }
    flush();
    return pages;
  }

  static double _photoAreaHeight(BookLayoutPlan plan, int photoCount) {
    if (photoCount == 0 || plan.type == BookLayoutType.textOnly) return 0;
    final maxLong = photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;
    return BookStickerCollage.estimateCollageHeight(
      photoCount,
      _contentWidth,
      maxLong,
    );
  }

  static double _estimateFullHeight(BookDiaryEntry entry, BookLayoutPlan plan) {
    final charsPerLine = plan.textStyle == BookTextStyle.caption ? 40 : 32;
    final bodyLines = (entry.body.length / charsPerLine).ceil().clamp(1, 9999);
    final bodyLineHeight = plan.textStyle == BookTextStyle.fullStyle ? 14.0 : 12.0;

    var height = 18.0;
    height += 16 + 14;
    height += 14;
    final photos = _photoAreaHeight(plan, entry.photoCount);
    if (photos > 0) height += photos + 16;
    height += bodyLines * bodyLineHeight + 8;
    // Flutter 텍스트 줄바꿈·사진 렌더가 JS 추정보다 클 수 있음
    return height * 1.08;
  }

  static double _estimateCompactHeight(BookDiaryEntry entry) {
    final bodyLines = (entry.body.length / 32).ceil();
    var height = 18.0;
    height += 16 + 14;
    height += 14;
    if (entry.body.isNotEmpty) {
      height += bodyLines.clamp(1, 9999) * 14 + 8;
    }
    return height * 1.06;
  }

  static double _estimateItemHeight(BookPageItem item) {
    if (item.kind == BookPageItemKind.compact) {
      return _estimateCompactHeight(item.layout.entry);
    }
    return _estimateFullHeight(item.layout.entry, item.layout.plan);
  }

  static BookLayoutType _pickLayoutType(int photoCount, int textLength) {
    if (photoCount == 0) return BookLayoutType.textOnly;
    if (photoCount >= BookLayoutThresholds.gridPhotoMin &&
        textLength < BookLayoutThresholds.shortText) {
      return BookLayoutType.photoGrid;
    }
    if (photoCount == 1) return BookLayoutType.singlePhotoVertical;
    if (photoCount == 2 && textLength < BookLayoutThresholds.shortText) {
      return BookLayoutType.dualPhoto;
    }
    if (photoCount >= BookLayoutThresholds.gridPhotoMin) {
      return BookLayoutType.photoGrid;
    }
    return BookLayoutType.singlePhotoVertical;
  }

  static BookTextStyle _pickTextStyle(BookLayoutType type, int textLength) {
    if (type == BookLayoutType.photoGrid || type == BookLayoutType.dualPhoto) {
      return BookTextStyle.caption;
    }
    if (textLength >= BookLayoutThresholds.longText) {
      return BookTextStyle.fullStyle;
    }
    if (textLength < BookLayoutThresholds.shortText) {
      return BookTextStyle.shortStyle;
    }
    return BookTextStyle.fullStyle;
  }

  static ({
    int gridColumns,
    int gridRows,
    List<BookPhotoSlot> photoSlots,
  }) _buildPhotoSlots(BookLayoutType type, int photoCount) {
    switch (type) {
      case BookLayoutType.textOnly:
        return (gridColumns: 0, gridRows: 0, photoSlots: const []);
      case BookLayoutType.singlePhotoVertical:
        return (
          gridColumns: 1,
          gridRows: 1,
          photoSlots: const [
            BookPhotoSlot(index: 0, row: 0, col: 0),
          ],
        );
      case BookLayoutType.dualPhoto:
        return (
          gridColumns: 2,
          gridRows: 1,
          photoSlots: const [
            BookPhotoSlot(index: 0, row: 0, col: 0),
            BookPhotoSlot(index: 1, row: 0, col: 1),
          ],
        );
      case BookLayoutType.photoGrid:
        return _buildGridSlots(photoCount);
    }
  }

  static ({
    int gridColumns,
    int gridRows,
    List<BookPhotoSlot> photoSlots,
  }) _buildGridSlots(int photoCount) {
    const gridColumns = 2;
    final gridRows = (photoCount / gridColumns).ceil();
    final photoSlots = <BookPhotoSlot>[];
    for (var i = 0; i < photoCount; i++) {
      final row = i ~/ gridColumns;
      final col = i % gridColumns;
      final isLastOdd = photoCount.isOdd && i == photoCount - 1 && photoCount > 1;
      photoSlots.add(
        BookPhotoSlot(
          index: i,
          row: row,
          col: col,
          colSpan: isLastOdd ? 2 : 1,
        ),
      );
    }
    return (gridColumns: gridColumns, gridRows: gridRows, photoSlots: photoSlots);
  }
}
