import 'package:flutter/material.dart';

import '../core/constants/app_fonts.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_style.dart';

/// 공책 줄무늬 글 박스 — 편집 모드 (Phase B)
class BookPdfEditableNotebookBox extends StatelessWidget {
  const BookPdfEditableNotebookBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.plan,
    this.minLines = 3,
    this.diaryFontId = kDefaultDiaryFontId,
    this.maxLength = 500,
    this.hintText = '마음에 남는 것을 적어 보세요…',
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final BookLayoutPlan plan;
  final int minLines;
  final AppFontId diaryFontId;
  final int maxLength;
  final String hintText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = BookPdfLayoutMetrics.textStyleForPlan(
      plan,
      diaryFontId: diaryFontId,
    );
    final align = plan.textStyle == BookTextStyle.caption
        ? TextAlign.center
        : TextAlign.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final text = controller.text.isEmpty ? hintText : controller.text;
        final height = BookPdfLayoutMetrics.measureTextHeight(
          text,
          plan,
          maxWidth: width,
          minLines: minLines,
          diaryFontId: diaryFontId,
        ).clamp(
          BookPdfLayoutMetrics.measureTextHeight(
            '가',
            plan,
            maxWidth: width,
            minLines: minLines,
            diaryFontId: diaryFontId,
          ),
          BookPdfStyle.pageContentHeight,
        );

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _NotebookBoxPainter(),
            child: Padding(
              padding: const EdgeInsets.all(BookEntryBoxStyle.pad),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                maxLength: maxLength,
                textAlign: align,
                style: style.copyWith(height: null, color: BookPdfStyle.body),
                strutStyle: StrutStyle(
                  fontSize: style.fontSize,
                  height: style.height,
                  forceStrutHeight: true,
                ),
                cursorColor: BookPdfStyle.title,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                  hintText: hintText,
                  hintStyle: style.copyWith(
                    height: null,
                    color: BookPdfStyle.muted.withValues(alpha: 0.65),
                  ),
                ),
                onChanged: (_) => onChanged?.call(),
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
