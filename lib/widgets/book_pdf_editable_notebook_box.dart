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
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final BookLayoutPlan plan;
  final int minLines;
  final AppFontId diaryFontId;
  final int maxLength;
  final String hintText;
  final VoidCallback? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = BookPdfLayoutMetrics.textStyleForPlan(
      plan,
      diaryFontId: diaryFontId,
    );
    // 책 페이지 미리보기(클릭 전)만 글씨를 키움 — PDF 실측은 그대로
    const previewScale = 1.55;
    final style = readOnly
        ? baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? BookPdfStyle.bodySize) * previewScale,
          )
        : baseStyle;
    final align = plan.textStyle == BookTextStyle.caption
        ? TextAlign.center
        : TextAlign.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final text = controller.text.isEmpty ? hintText : controller.text;
        final measured = BookPdfLayoutMetrics.measureTextHeight(
          text,
          plan,
          maxWidth: width,
          minLines: minLines,
          diaryFontId: diaryFontId,
        );
        final minMeasured = BookPdfLayoutMetrics.measureTextHeight(
          '가',
          plan,
          maxWidth: width,
          minLines: minLines,
          diaryFontId: diaryFontId,
        );
        final height = (readOnly ? measured * previewScale : measured).clamp(
          readOnly ? minMeasured * previewScale : minMeasured,
          BookPdfStyle.pageContentHeight,
        );

        final hintStyle = style.copyWith(
          height: null,
          color: BookPdfStyle.muted.withValues(alpha: 0.65),
        );
        final bodyStyle = style.copyWith(height: null, color: BookPdfStyle.body);
        final strutStyle = StrutStyle(
          fontSize: style.fontSize,
          height: style.height,
          forceStrutHeight: true,
        );

        Widget child;
        if (readOnly) {
          final isEmpty = controller.text.trim().isEmpty;
          child = Text(
            isEmpty ? hintText : controller.text,
            textAlign: align,
            style: isEmpty ? hintStyle : bodyStyle,
            strutStyle: strutStyle,
          );
        } else {
          child = TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            maxLength: maxLength,
            textAlign: align,
            style: bodyStyle,
            strutStyle: strutStyle,
            cursorColor: BookPdfStyle.title,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
              hintText: hintText,
              hintStyle: hintStyle,
            ),
            onChanged: (_) => onChanged?.call(),
          );
        }

        Widget box = SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _NotebookBoxPainter(),
            child: Padding(
              padding: const EdgeInsets.all(BookEntryBoxStyle.pad),
              child: child,
            ),
          ),
        );

        if (readOnly && onTap != null) {
          box = Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
              child: box,
            ),
          );
        }

        return box;
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
