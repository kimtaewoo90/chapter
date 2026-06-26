import 'book_photo_style.dart';

class BookImageMeta {
  const BookImageMeta({required this.width, required this.height});

  final double width;
  final double height;
}

class BookStickerItem {
  const BookStickerItem({required this.index, required this.meta});

  final int index;
  final BookImageMeta meta;
}

class BookPhotoPlacement {
  const BookPhotoPlacement({
    required this.index,
    required this.row,
    required this.x,
    required this.y,
    required this.photoW,
    required this.photoH,
    required this.frameW,
    required this.frameH,
  });

  final int index;
  final int row;
  final double x;
  final double y;
  final double photoW;
  final double photoH;
  final double frameW;
  final double frameH;
}

class BookStickerCollageResult {
  const BookStickerCollageResult({
    required this.placements,
    required this.totalHeight,
  });

  final List<BookPhotoPlacement> placements;
  final double totalHeight;
}

class BookStickerCollageOptions {
  const BookStickerCollageOptions({
    required this.maxLongEdge,
    this.maxPhotoH,
  });

  final double maxLongEdge;
  final double? maxPhotoH;
}

/// chapter_admin `layout/stickerCollage.js`
class BookStickerCollage {
  BookStickerCollage._();

  static List<List<int>> rowPattern(int count) {
    if (count <= 0) return [];
    if (count == 1) return [[0]];
    if (count == 2) return [[0, 1]];
    if (count == 3) return [
      [0, 1],
      [2],
    ];
    if (count == 4) return [
      [0, 1],
      [2, 3],
    ];
    if (count == 5) return [
      [0, 1, 2],
      [3, 4],
    ];
    if (count == 6) return [
      [0, 1, 2],
      [3, 4, 5],
    ];
    final rows = <List<int>>[];
    for (var i = 0; i < count; i += 3) {
      rows.add(List.generate(count - i > 3 ? 3 : count - i, (j) => i + j));
    }
    return rows;
  }

  static ({double photoW, double photoH}) scalePhoto(
    BookImageMeta meta,
    double maxPhotoW,
    double maxPhotoH,
    double maxLong,
  ) {
    final longEdge = meta.width > meta.height ? meta.width : meta.height;
    final scale = [
      maxPhotoW / meta.width,
      maxPhotoH / meta.height,
      maxLong / longEdge,
    ].reduce((a, b) => a < b ? a : b);
    return (photoW: meta.width * scale, photoH: meta.height * scale);
  }

  static ({double frameW, double frameH}) frameSize(double photoW, double photoH) {
    return (frameW: photoW, frameH: photoH);
  }

  static List<({
    int index,
    double photoW,
    double photoH,
    double frameW,
    double frameH,
  })> fitRowItems(
    List<({
      int index,
      double photoW,
      double photoH,
      double frameW,
      double frameH,
    })> items,
    double usableWidth,
  ) {
    final gap = BookPhotoFrameStyle.gap;
    final total = items.fold<double>(0, (sum, item) => sum + item.frameW) +
        gap * (items.length - 1);
    if (total <= usableWidth) return items;
    final factor = usableWidth / total;
    return items
        .map(
          (item) {
            final photoW = item.photoW * factor;
            final photoH = item.photoH * factor;
            final frame = frameSize(photoW, photoH);
            return (
              index: item.index,
              photoW: photoW,
              photoH: photoH,
              frameW: frame.frameW,
              frameH: frame.frameH,
            );
          },
        )
        .toList();
  }

  static BookStickerCollageResult layoutStickerCollage(
    List<BookStickerItem> items,
    double usableWidth, {
    BookStickerCollageOptions options = const BookStickerCollageOptions(
      maxLongEdge: BookPhotoFrameStyle.maxLongMulti,
    ),
  }) {
    if (items.isEmpty) {
      return const BookStickerCollageResult(placements: [], totalHeight: 0);
    }

    final maxPhotoH = options.maxPhotoH ?? options.maxLongEdge * 1.4;
    final pattern = rowPattern(items.length);
    final placements = <BookPhotoPlacement>[];
    var cursorY = 0.0;

    for (var r = 0; r < pattern.length; r++) {
      final indices = pattern[r];
      final maxPhotoW = indices.length == 1
          ? usableWidth
          : (usableWidth - BookPhotoFrameStyle.gap * (indices.length - 1)) /
              indices.length;

      var rowItems = indices.map((index) {
        final item = items.firstWhere((i) => i.index == index);
        final scaled = scalePhoto(
          item.meta,
          maxPhotoW.clamp(40, double.infinity),
          maxPhotoH,
          options.maxLongEdge,
        );
        final frame = frameSize(scaled.photoW, scaled.photoH);
        return (
          index: index,
          photoW: scaled.photoW,
          photoH: scaled.photoH,
          frameW: frame.frameW,
          frameH: frame.frameH,
        );
      }).toList();

      rowItems = fitRowItems(rowItems, usableWidth);

      final rowWidth = rowItems.fold<double>(0, (sum, item) => sum + item.frameW) +
          BookPhotoFrameStyle.gap * (rowItems.length - 1);
      final rowHeight = rowItems.map((item) => item.frameH).reduce((a, b) => a > b ? a : b);
      var cursorX = (usableWidth - rowWidth) / 2;

      for (final item in rowItems) {
        placements.add(
          BookPhotoPlacement(
            index: item.index,
            row: r,
            x: cursorX,
            y: cursorY,
            photoW: item.photoW,
            photoH: item.photoH,
            frameW: item.frameW,
            frameH: item.frameH,
          ),
        );
        cursorX += item.frameW + BookPhotoFrameStyle.gap;
      }

      cursorY += rowHeight;
      if (r < pattern.length - 1) {
        cursorY += BookPhotoFrameStyle.rowGap;
      }
    }

    return BookStickerCollageResult(
      placements: placements,
      totalHeight: cursorY + BookPhotoFrameStyle.bottomGap,
    );
  }

  static double estimateCollageHeight(
    int photoCount,
    double usableWidth,
    double maxLongEdge,
  ) {
    if (photoCount == 0) return 0;
    final placeholders = List.generate(
      photoCount,
      (i) => BookStickerItem(
        index: i,
        meta: const BookImageMeta(width: 1600, height: 1200),
      ),
    );
    return layoutStickerCollage(
      placeholders,
      usableWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLongEdge),
    ).totalHeight;
  }
}
