import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_photo_style.dart';
import '../core/book_layout/book_pdf_diary_block.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_photo_meta.dart';
import '../core/book_layout/book_pdf_style.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/book_layout/book_sticker_collage.dart';
import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';
import 'book_pdf_notebook_box.dart';
import 'book_pdf_photo_tile.dart';

/// PDF·미리보기 공용 — 책 한 페이지 프레임 (A4 비율)
class BookPdfPageFrame extends StatelessWidget {
  const BookPdfPageFrame({
    super.key,
    required this.child,
    this.horizontalPadding = 4,
  });

  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BookPdfStyle.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmShadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: BookPdfPageSpec.width,
              height: BookPdfPageSpec.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// PDF 일기 페이지 본문 — `BookPdfPreview`·기록 미리보기 공용
class BookPdfDiaryPageContent extends StatelessWidget {
  const BookPdfDiaryPageContent({
    super.key,
    required this.blocks,
    required this.topInset,
    required this.diaryFontId,
  });

  final List<BookDiaryBlock> blocks;
  final double topInset;
  final AppFontId diaryFontId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BookPdfStyle.paper,
      child: Padding(
        padding: const EdgeInsets.all(BookPdfPageSpec.margin),
        child: SizedBox(
          height: BookPdfStyle.pageContentHeight,
          width: BookPdfPageSpec.contentWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final block in blocks)
                      switch (block) {
                        BookDiaryEntryGapBlock() =>
                          const SizedBox(height: BookPdfStyle.entryGap),
                        BookDiaryHeaderBlock(:final entry) =>
                          BookPdfEntryHeader(
                            entry: entry,
                            diaryFontId: diaryFontId,
                          ),
                        BookDiaryPhotosBlock(:final entry) =>
                          BookPdfPhotoSection(entry: entry),
                        BookDiaryTextBlock(:final text, :final plan, :final compact) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.boxGap),
                            child: BookPdfNotebookBox(
                              text: text,
                              plan: plan,
                              minLines: BookPdfLayoutMetrics.minLinesForPlan(
                                plan,
                                compact: compact,
                              ),
                              diaryFontId: diaryFontId,
                            ),
                          ),
                      },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookPdfEntryHeader extends StatelessWidget {
  const BookPdfEntryHeader({
    super.key,
    required this.entry,
    required this.diaryFontId,
  });

  final BookDiaryEntry entry;
  final AppFontId diaryFontId;

  @override
  Widget build(BuildContext context) {
    final dateLabel = entry.date.isNotEmpty
        ? BookPreviewEntryMapper.formatDateLabel(entry.date)
        : '';
    final moodLabel = BookPreviewEntryMapper.formatMoodDisplay(
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dateLabel.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: BookPdfStyle.dateSize,
                    height: 1.2,
                    color: BookPdfStyle.title,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (moodLabel != null)
                Text(
                  moodLabel,
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: BookPdfStyle.moodSize,
                    height: 1.2,
                    color: BookPdfStyle.muted,
                  ),
                ),
            ],
          ),
        if (dateLabel.isNotEmpty) const SizedBox(height: BookPdfStyle.dateGap),
        Container(height: 0.5, color: BookPdfStyle.line),
        const SizedBox(height: BookPdfStyle.headerBottomGap),
      ],
    );
  }
}

class BookPdfPhotoSection extends StatefulWidget {
  const BookPdfPhotoSection({super.key, required this.entry});

  final BookDiaryEntry entry;

  @override
  State<BookPdfPhotoSection> createState() => _BookPdfPhotoSectionState();
}

class _BookPdfPhotoSectionState extends State<BookPdfPhotoSection> {
  late Future<List<BookImageMeta>> _metaFuture;

  @override
  void initState() {
    super.initState();
    _metaFuture = BookPdfPhotoMeta.resolveAll(widget.entry.photoUris);
  }

  @override
  void didUpdateWidget(covariant BookPdfPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.photoUris != widget.entry.photoUris) {
      _metaFuture = BookPdfPhotoMeta.resolveAll(widget.entry.photoUris);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookImageMeta>>(
      future: _metaFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          final estimated = BookPdfLayoutMetrics.photoBlockHeight(widget.entry);
          if (estimated <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
            child: SizedBox(
              width: BookPdfPageSpec.contentWidth,
              height: estimated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BookEntryBoxStyle.photoBg,
                  borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
                  border: Border.all(color: BookEntryBoxStyle.border, width: 0.6),
                ),
              ),
            ),
          );
        }

        return BookPdfPhotoCollage(
          entry: widget.entry,
          metas: snapshot.data!,
        );
      },
    );
  }
}

class BookPdfPhotoCollage extends StatelessWidget {
  const BookPdfPhotoCollage({
    super.key,
    required this.entry,
    required this.metas,
  });

  final BookDiaryEntry entry;
  final List<BookImageMeta> metas;

  @override
  Widget build(BuildContext context) {
    final photoCount = entry.photoCount;
    final outerWidth = BookPdfPageSpec.contentWidth;
    final innerWidth = BookEntryBoxStyle.photoInnerWidth(outerWidth);
    final maxLong = photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;

    final stickerItems = List.generate(
      photoCount,
      (i) => BookStickerItem(index: i, meta: metas[i]),
    );

    final collage = BookStickerCollage.layoutStickerCollage(
      stickerItems,
      innerWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLong),
    );

    final boxHeight = collage.totalHeight + BookEntryBoxStyle.pad * 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
      child: SizedBox(
        width: outerWidth,
        height: boxHeight,
        child: CustomPaint(
          painter: _PhotoFrameBoxPainter(),
          child: Padding(
            padding: const EdgeInsets.all(BookEntryBoxStyle.pad),
            child: SizedBox(
              width: innerWidth,
              height: collage.totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final placement in collage.placements)
                    Positioned(
                      left: placement.x,
                      top: placement.y,
                      width: placement.photoW,
                      height: placement.photoH,
                      child: BookPdfPhotoTile(
                        uri: entry.photoUris[placement.index],
                        meta: metas[placement.index],
                        slotW: placement.photoW,
                        slotH: placement.photoH,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoFrameBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(BookEntryBoxStyle.radius),
    );
    canvas.drawRRect(rrect, Paint()..color = BookEntryBoxStyle.photoBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = BookEntryBoxStyle.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
