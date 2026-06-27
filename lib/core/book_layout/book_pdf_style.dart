import 'package:flutter/material.dart';

import 'book_layout_types.dart';

/// chapter_admin `pdf/generator.ts` · `pdf/entryStyle.ts` 상수
class BookPdfStyle {
  BookPdfStyle._();

  static const paper = Color(0xFFF5F0E8);
  static const title = Color(0xFF2C2824);
  static const subtitle = Color(0xFF6B6560);
  static const body = Color(0xFF2C2824);
  static const muted = Color(0xFF9A948C);
  static const line = Color(0xFFE3DDD3);
  static const placeholder = Color(0xFFC5BFB8);

  static const entryGap = 28.0;
  static const headerMinHeight = 42.0;
  static const dateSize = 12.0;
  static const moodSize = 10.0;
  static const bodySize = 11.0;
  static const captionSize = 10.0;
  static const bodyLineGap = 9.0;
  static const captionLineGap = 6.0;
  static const dateGap = 16.0;
  static const headerBottomGap = 14.0;

  static double get pageContentHeight =>
      BookPdfPageSpec.height - BookPdfPageSpec.margin * 2;
}

class BookEntryBoxStyle {
  BookEntryBoxStyle._();

  static const radius = 8.0;
  static const pad = 12.0;
  static const border = Color(0xFFDDD6CA);
  static const photoBg = Colors.white;
  static const noteBg = Color(0xFFFFFEF8);
  static const ruleColor = Color(0xFFE8E2D6);
  static const marginLine = Color(0xFFF0D4D4);
  static const marginLineInset = 22.0;
  static const ruleSpacing = 20.0;
  static const sectionGap = 10.0;
  static const boxGap = 14.0;

  static double photoInnerWidth(double outerWidth) => outerWidth - pad * 2;
}

class BookCalendarStyle {
  BookCalendarStyle._();

  static const paper = BookPdfStyle.paper;
  static const ink = Color(0xFF2C2824);
  static const inkMuted = Color(0xFF6B6560);
  static const dayEmpty = Color(0xFFB8B2AA);
  static const cellHasEntry = Colors.white;
  static const cellBorderEntry = Color(0x4D8B7355);
  static const photoAspect = 3 / 4;
  static const gap = 4.0;
  static const dateRowHeight = 10.0;
  static const innerPad = 3.0;
}
