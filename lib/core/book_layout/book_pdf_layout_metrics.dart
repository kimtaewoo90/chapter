import 'package:flutter/material.dart';

import '../constants/app_fonts.dart';
import 'book_layout_types.dart';
import 'book_pdf_diary_block.dart';
import 'book_pdf_photo_meta.dart';
import 'book_photo_style.dart';
import 'book_pdf_style.dart';
import 'book_sticker_collage.dart';

/// chapter_admin PDF 본문·사진·글박스 높이 추정 (위젯 렌더와 동일)
class BookPdfLayoutMetrics {
  BookPdfLayoutMetrics._();

  /// Flutter 텍스트/박스 vs 추정 오차 흡수
  static const pageSafetyMargin = 16.0;

  static double headerBlockHeight(BookDiaryEntry entry) {
    if (entry.date.isEmpty) return BookPdfStyle.headerBottomGap;
    return BookPdfStyle.dateSize * 1.2 +
        BookPdfStyle.dateGap +
        0.5 +
        BookPdfStyle.headerBottomGap +
        2;
  }

  static double photoCollageHeight(BookDiaryEntry entry) {
    if (entry.photoCount == 0) return 0;

    final innerWidth = BookEntryBoxStyle.photoInnerWidth(BookPdfPageSpec.contentWidth);
    final maxLong = entry.photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;

    final stickerItems = List.generate(entry.photoCount, (i) {
      final uri = i < entry.photoUris.length ? entry.photoUris[i] : '';
      final meta = BookPdfPhotoMeta.cached(uri) ?? BookPdfPhotoMeta.fallback;
      return BookStickerItem(index: i, meta: meta);
    });

    return BookStickerCollage.layoutStickerCollage(
      stickerItems,
      innerWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLong),
    ).totalHeight;
  }

  static double photoBlockHeight(BookDiaryEntry entry) {
    if (entry.photoCount == 0) return 0;
    return photoCollageHeight(entry) +
        BookEntryBoxStyle.pad * 2 +
        BookEntryBoxStyle.sectionGap;
  }

  static TextStyle _metricsTextStyle(BookLayoutPlan plan) {
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

  static TextStyle textStyleForPlan(
    BookLayoutPlan plan, {
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    final metrics = _metricsTextStyle(plan);
    return diaryFontStyle(
      diaryFontId,
      fontSize: metrics.fontSize ?? BookPdfStyle.bodySize,
      height: metrics.height ?? 1.55,
      color: metrics.color,
    );
  }

  static StrutStyle strutForPlan(
    BookLayoutPlan plan, {
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    final style = _metricsTextStyle(plan);
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
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    if (text.isEmpty) return 0;

    final style = _metricsTextStyle(plan);
    final innerWidth = maxWidth - BookEntryBoxStyle.pad * 2;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      strutStyle: strutForPlan(plan, diaryFontId: diaryFontId),
    )..layout(maxWidth: innerWidth);

    final minHeight = minLines * BookEntryBoxStyle.ruleSpacing + BookEntryBoxStyle.pad * 2;
    final contentHeight = painter.size.height + BookEntryBoxStyle.pad * 2 + 4;
    final height = contentHeight > minHeight ? contentHeight : minHeight;
    return height.ceilToDouble() + 1;
  }

  static double textBlockHeight(
    String text,
    BookLayoutPlan plan, {
    required int minLines,
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    return measureTextHeight(
          text,
          plan,
          maxWidth: BookPdfPageSpec.contentWidth,
          minLines: minLines,
          diaryFontId: diaryFontId,
        ) +
        BookEntryBoxStyle.boxGap;
  }

  static String fitTextChunk(
    String text,
    BookLayoutPlan plan, {
    required double maxBoxHeight,
    required int minLines,
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    if (text.isEmpty) return '';

    final totalMax = maxBoxHeight - BookEntryBoxStyle.boxGap;
    if (totalMax <= BookEntryBoxStyle.pad * 2) return '';

    if (measureTextHeight(
          text,
          plan,
          maxWidth: BookPdfPageSpec.contentWidth,
          minLines: minLines,
          diaryFontId: diaryFontId,
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
            diaryFontId: diaryFontId,
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

  static double blockHeight(
    BookDiaryBlock block, {
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) {
    return switch (block) {
      BookDiaryEntryGapBlock() => BookPdfStyle.entryGap,
      BookDiaryHeaderBlock(:final entry) => headerBlockHeight(entry),
      BookDiaryPhotosBlock(:final entry) => photoBlockHeight(entry),
      BookDiaryTextBlock(:final text, :final plan, :final compact) =>
        textBlockHeight(
          text,
          plan,
          minLines: minLinesForPlan(plan, compact: compact),
          diaryFontId: diaryFontId,
        ),
    };
  }

  static double pageBlocksHeight(
    List<BookDiaryBlock> blocks, {
    AppFontId diaryFontId = kDefaultDiaryFontId,
  }) =>
      blocks.fold(
        0.0,
        (sum, block) => sum + blockHeight(block, diaryFontId: diaryFontId),
      );
}
