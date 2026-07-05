import 'book_layout_types.dart';

/// chapter_admin `layout/engine.js` — PDF 페이지 배치
class BookLayoutEngine {
  BookLayoutEngine._();

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
    if (entries.isEmpty) return const [];

    return entries
        .map((entry) {
          final plan = decideLayout(entry);
          final layout = BookEntryLayout(entry: entry, plan: plan);
          final item = plan.pageMode == BookPageMode.full
              ? BookPageItem.full(layout)
              : BookPageItem.compact(layout);
          return BookPagePlan(items: [item]);
        })
        .toList(growable: false);
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
