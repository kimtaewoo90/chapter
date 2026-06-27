import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_style.dart';

/// chapter_admin `entryStyle.ts` — 공책 줄무늬 글 박스
class BookPdfNotebookBox extends StatelessWidget {
  const BookPdfNotebookBox({
    super.key,
    required this.text,
    required this.plan,
    this.minLines = 3,
  });

  final String text;
  final BookLayoutPlan plan;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final style = BookPdfLayoutMetrics.textStyleForPlan(plan);
    final align = plan.textStyle == BookTextStyle.caption
        ? TextAlign.center
        : TextAlign.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = BookPdfLayoutMetrics.measureTextHeight(
          text,
          plan,
          maxWidth: width,
          minLines: minLines,
        );

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _NotebookBoxPainter(),
            child: Padding(
              padding: const EdgeInsets.all(BookEntryBoxStyle.pad),
              child: Text(
                text,
                textAlign: align,
                style: style.copyWith(height: null),
                strutStyle: StrutStyle(
                  fontSize: style.fontSize,
                  height: style.height,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotebookBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(BookEntryBoxStyle.radius),
    );

    canvas.drawRRect(rrect, Paint()..color = BookEntryBoxStyle.noteBg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = BookEntryBoxStyle.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    const pad = BookEntryBoxStyle.pad;
    final innerLeft = pad;
    final innerRight = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;
    final marginX = innerLeft + BookEntryBoxStyle.marginLineInset;

    canvas.drawLine(
      Offset(marginX, top),
      Offset(marginX, bottom),
      Paint()
        ..color = BookEntryBoxStyle.marginLine
        ..strokeWidth = 0.45,
    );

    final linePaint = Paint()
      ..color = BookEntryBoxStyle.ruleColor
      ..strokeWidth = 0.35;

    for (var y = top + BookEntryBoxStyle.ruleSpacing;
        y < bottom;
        y += BookEntryBoxStyle.ruleSpacing) {
      canvas.drawLine(
        Offset(innerLeft, y),
        Offset(innerRight, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
