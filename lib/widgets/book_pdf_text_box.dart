import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_fonts.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_body_style.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_style.dart';

/// chapter_admin `entryStyle.ts` — 본문 박스 (marginRail 기본)
class BookPdfTextBox extends StatelessWidget {
  const BookPdfTextBox({
    super.key,
    required this.text,
    required this.plan,
    this.minLines = 3,
    this.diaryFontId = kDefaultDiaryFontId,
    this.bodyStyle = BookEntryBodyStyles.previewDefault,
  });

  final String text;
  final BookLayoutPlan plan;
  final int minLines;
  final AppFontId diaryFontId;
  final BookEntryBodyStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final style = BookPdfLayoutMetrics.textStyleForPlan(
      plan,
      diaryFontId: diaryFontId,
    );
    final centerAlign = plan.textStyle == BookTextStyle.caption;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = BookPdfLayoutMetrics.measureTextHeight(
          text,
          plan,
          maxWidth: width,
          minLines: minLines,
          diaryFontId: diaryFontId,
          bodyStyle: bodyStyle,
        );

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _BodyTextBoxPainter(
              bodyStyle: bodyStyle,
              centerAlign: centerAlign,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                BookEntryBoxStyle.textPadLeft(
                  bodyStyle: bodyStyle,
                  centerAlign: centerAlign,
                ),
                BookEntryBoxStyle.pad,
                BookEntryBoxStyle.pad,
                BookEntryBoxStyle.pad,
              ),
              child: Text(
                text,
                textAlign: centerAlign ? TextAlign.center : TextAlign.left,
                style: style.copyWith(height: null),
                strutStyle: BookPdfLayoutMetrics.strutForPlan(
                  plan,
                  diaryFontId: diaryFontId,
                  bodyStyle: bodyStyle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BodyTextBoxPainter extends CustomPainter {
  const _BodyTextBoxPainter({
    required this.bodyStyle,
    required this.centerAlign,
  });

  final BookEntryBodyStyle bodyStyle;
  final bool centerAlign;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(BookEntryBoxStyle.radius),
    );

    switch (bodyStyle) {
      case BookEntryBodyStyle.notebook:
        _paintNotebook(canvas, rrect, size);
      case BookEntryBodyStyle.marginRail:
        if (centerAlign) {
          _paintCornerBrackets(canvas, rect);
        } else {
          _paintMarginRail(canvas, rect);
        }
      case BookEntryBodyStyle.dotGrid:
        _paintDotGrid(canvas, rrect, size);
      case BookEntryBodyStyle.wash:
        _paintWash(canvas, rrect, size);
      case BookEntryBodyStyle.tape:
        _paintTape(canvas, rect, size);
      case BookEntryBodyStyle.minimal:
        break;
    }
  }

  void _paintNotebook(Canvas canvas, RRect rrect, Size size) {
    canvas.drawRRect(rrect, Paint()..color = BookEntryBoxStyle.noteBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = BookEntryBoxStyle.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final innerLeft = BookEntryBoxStyle.pad;
    final innerRight = size.width - BookEntryBoxStyle.pad;
    final top = BookEntryBoxStyle.pad;
    final bottom = size.height - BookEntryBoxStyle.pad;
    final linePaint = Paint()
      ..color = BookEntryBoxStyle.ruleColor
      ..strokeWidth = 0.35;

    for (var y = top + BookEntryBoxStyle.ruleSpacing;
        y < bottom;
        y += BookEntryBoxStyle.ruleSpacing) {
      canvas.drawLine(Offset(innerLeft, y), Offset(innerRight, y), linePaint);
    }
  }

  void _paintMarginRail(Canvas canvas, Rect rect) {
    final railX = rect.left + BookEntryBoxStyle.railInset;
    final paint = Paint()
      ..color = BookEntryBoxStyle.railColor
      ..strokeWidth = BookEntryBoxStyle.railWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(railX, rect.top + BookEntryBoxStyle.railInset),
      Offset(railX, rect.bottom - BookEntryBoxStyle.railInset),
      paint,
    );
  }

  void _paintCornerBrackets(Canvas canvas, Rect rect) {
    final len = math.min(14.0, math.min(rect.width * 0.12, rect.height * 0.2));
    final paint = Paint()
      ..color = BookEntryBoxStyle.railColor
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + len)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + len, rect.top),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - len)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + len, rect.bottom),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - len),
      paint,
    );
  }

  void _paintDotGrid(Canvas canvas, RRect rrect, Size size) {
    canvas.drawRRect(rrect, Paint()..color = BookEntryBoxStyle.noteBg);

    final left = BookEntryBoxStyle.pad;
    final top = BookEntryBoxStyle.pad;
    final right = size.width - BookEntryBoxStyle.pad;
    final bottom = size.height - BookEntryBoxStyle.pad;
    final areaW = right - left;
    final areaH = bottom - top;
    if (areaW <= 0 || areaH <= 0) return;

    final cols = math.max(1, (areaW / BookEntryBoxStyle.dotSpacing).floor());
    final rows = math.max(1, (areaH / BookEntryBoxStyle.dotSpacing).floor());
    final gridW = cols * BookEntryBoxStyle.dotSpacing;
    final gridH = rows * BookEntryBoxStyle.dotSpacing;
    final startX = left + (areaW - gridW) / 2;
    final startY = top + (areaH - gridH) / 2;

    final dotPaint = Paint()..color = BookEntryBoxStyle.dotColor;
    for (var row = 0; row <= rows; row++) {
      for (var col = 0; col <= cols; col++) {
        canvas.drawCircle(
          Offset(startX + col * BookEntryBoxStyle.dotSpacing, startY + row * BookEntryBoxStyle.dotSpacing),
          BookEntryBoxStyle.dotRadius,
          dotPaint,
        );
      }
    }
  }

  void _paintWash(Canvas canvas, RRect rrect, Size size) {
    canvas.save();
    canvas.clipRRect(rrect);

    final blobs = [
      (cx: 0.28, cy: 0.22, rx: 0.42, ry: 0.32, color: const Color(0xFFE8D4C8), opacity: 0.5),
      (cx: 0.72, cy: 0.48, rx: 0.48, ry: 0.38, color: const Color(0xFFD4E0E8), opacity: 0.38),
      (cx: 0.4, cy: 0.78, rx: 0.44, ry: 0.28, color: const Color(0xFFE8E0D0), opacity: 0.45),
      (cx: 0.55, cy: 0.35, rx: 0.3, ry: 0.22, color: const Color(0xFFF0E4DC), opacity: 0.35),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..color = blob.color.withValues(alpha: blob.opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * blob.cx, size.height * blob.cy),
          width: size.width * blob.rx * 2,
          height: size.height * blob.ry * 2,
        ),
        paint,
      );
    }

    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFE8E0D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4,
    );
  }

  void _paintTape(Canvas canvas, Rect rect, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(BookEntryBoxStyle.radius)),
      Paint()..color = BookEntryBoxStyle.noteBg,
    );

    final tapeW = size.width * 0.42;
    final tapeH = 18.0;
    final tapeX = rect.left + (size.width - tapeW) / 2;
    final tapeY = rect.top - tapeH * 0.35;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tapeX, tapeY, tapeW, tapeH),
        const Radius.circular(4),
      ),
      Paint()..color = BookEntryBoxStyle.tapeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyTextBoxPainter oldDelegate) =>
      oldDelegate.bodyStyle != bodyStyle || oldDelegate.centerAlign != centerAlign;
}
