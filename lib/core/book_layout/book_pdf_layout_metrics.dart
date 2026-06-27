import 'package:flutter/material.dart';

import 'book_layout_types.dart';
import 'book_pdf_diary_block.dart';
import 'book_photo_style.dart';
import 'book_pdf_style.dart';
import 'book_sticker_collage.dart';

/// chapter_admin PDF 본문·사진·글박스 높이 추정 (위젯 렌더와 동일)
class BookPdfLayoutMetrics {
  BookPdfLayoutMetrics._();

  /// Flutter 텍스트/박스 vs 추정 오차 흡수
  static const pageSafetyMargin = 8.0;

  static double headerBlockHeight(BookDiaryEntry entry) {
    if (entry.date.isEmpty) return BookPdfStyle.headerBottomGap;
    return BookPdfStyle.dateSize * 1.2 +
        BookPdfStyle.dateGap +
        0.5 +
        BookPdfStyle.headerBottomGap;
  }

  static double photoBlockHeight(BookDiaryEntry entry) {
    if (entry.photoCount == 0) return 0;

    final innerWidth = BookEntryBoxStyle.photoInnerWidth(BookPdfPageSpec.contentWidth);
    final maxLong = entry.photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;
    final collageHeight = BookStickerCollage.estimateCollageHeight(
      entry.photoCount,
      innerWidth,
      maxLong,
    );

    return collageHeight + BookEntryBoxStyle.pad * 2 + BookEntryBoxStyle.sectionGap;
  }

  static TextStyle textStyleForPlan(BookLayoutPlan plan) {
    final fontSize = plan.textStyle == BookTextStyle.caption
        ? BookPdfStyle.captionSize
        : BookPdfStyle.bodySize;
    final lineHeight = plan.textStyle == BookTextStyle.fullStyle ? 1.55 : 1.35;
    return TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: BookPdfStyle.body,
    );
  }

  static StrutStyle strutForPlan(BookLayoutPlan plan) {
    final style = textStyleForPlan(plan);
    return StrutStyle(
      fontSize: style.fontSize,
      height: style.height,
      forceStrutHeight: true,
    );
  }

  static int minLinesForPlan(BookLayoutPlan plan, {required bool compact}) {
    if (compact) return 1;
    if (plan.textStyle == BookTextStyle.caption) return 2;
    return 4;
  }

  static double measureTextHeight(
    String text,
    BookLayoutPlan plan, {
    required double maxWidth,
    required int minLines,
  }) {
    if (text.isEmpty) return 0;

    final style = textStyleForPlan(plan);
    final innerWidth = maxWidth - BookEntryBoxStyle.pad * 2;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      strutStyle: strutForPlan(plan),
    )..layout(maxWidth: innerWidth);

    final minHeight = minLines * BookEntryBoxStyle.ruleSpacing + BookEntryBoxStyle.pad * 2;
    final contentHeight = painter.size.height + BookEntryBoxStyle.pad * 2 + 4;
    return contentHeight > minHeight ? contentHeight : minHeight;
  }

  static double textBlockHeight(
    String text,
    BookLayoutPlan plan, {
    required int minLines,
  }) {
    return measureTextHeight(
          text,
          plan,
          maxWidth: BookPdfPageSpec.contentWidth,
          minLines: minLines,
        ) +
        BookEntryBoxStyle.boxGap;
  }

  static String fitTextChunk(
    String text,
    BookLayoutPlan plan, {
    required double maxBoxHeight,
    required int minLines,
  }) {
    if (text.isEmpty) return '';

    final totalMax = maxBoxHeight - BookEntryBoxStyle.boxGap;
    if (totalMax <= BookEntryBoxStyle.pad * 2) return '';

    if (measureTextHeight(
          text,
          plan,
          maxWidth: BookPdfPageSpec.contentWidth,
          minLines: minLines,
        ) <=
        totalMax) {
      return text;
    }

    var lo = 0;
    var hi = text.length;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      final candidate = text.substring(0, mid);
      if (measureTextHeight(
            candidate,
            plan,
            maxWidth: BookPdfPageSpec.contentWidth,
            minLines: 1,
          ) <=
          totalMax) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    if (lo <= 0) return text.substring(0, 1);

    final slice = text.substring(0, lo);
    final lastNewline = slice.lastIndexOf('\n');
    final lastSpace = slice.lastIndexOf(' ');
    if (lastNewline > lo * 0.6) return text.substring(0, lastNewline + 1);
    if (lastSpace > lo * 0.6) return text.substring(0, lastSpace + 1);
    return slice;
  }

  static double blockHeight(BookDiaryBlock block) {
    return switch (block) {
      BookDiaryEntryGapBlock() => BookPdfStyle.entryGap,
      BookDiaryHeaderBlock(:final entry) => headerBlockHeight(entry),
      BookDiaryPhotosBlock(:final entry) => photoBlockHeight(entry),
      BookDiaryTextBlock(:final text, :final plan, :final compact) =>
        textBlockHeight(
          text,
          plan,
          minLines: minLinesForPlan(plan, compact: compact),
        ),
    };
  }

  static double pageBlocksHeight(List<BookDiaryBlock> blocks) =>
      blocks.fold(0.0, (sum, block) => sum + blockHeight(block));
}
