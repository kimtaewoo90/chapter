import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';

/// 기록 탭 — 종이 + 연필 필기 느낌 입력창
class PaperJournalField extends StatelessWidget {
  const PaperJournalField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = '오늘 마음에 남는 것을 적어 보세요…',
    this.minLines = 10,
    this.maxLength = 500,
    this.embedded = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int minLines;
  final int maxLength;
  /// 책 페이지 안에 직접 높일 때 — 바깥 그림자·여백 없음
  final bool embedded;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final diaryFontId = context.watch<AppState>().diaryFontId;
    final handwriting = diaryFontStyle(
      diaryFontId,
      fontSize: 20,
      height: 1.75,
    );

    Widget field = ClipRRect(
      borderRadius: BorderRadius.circular(embedded ? 4 : 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _JournalLinesPainter(minLines: minLines, linesOnly: embedded),
            ),
          ),
          if (!embedded)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.ink.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(embedded ? 8 : 26, embedded ? 12 : 16, embedded ? 4 : 16, embedded ? 12 : 16),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              minLines: minLines,
              maxLines: null,
              maxLength: maxLength,
              style: handwriting,
              cursorColor: AppTheme.accent,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: handwriting.copyWith(
                  color: AppTheme.inkMuted.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                counterStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.inkMuted,
                    ),
              ),
              buildCounter: readOnly
                  ? (_, {required currentLength, required isFocused, required maxLength}) => null
                  : null,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      field = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(embedded ? 4 : 8),
          child: AbsorbPointer(child: field),
        ),
      );
    }

    if (embedded) return field;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: field,
    );
  }
}

class _JournalLinesPainter extends CustomPainter {
  _JournalLinesPainter({required this.minLines, this.linesOnly = false});

  final int minLines;
  final bool linesOnly;

  @override
  void paint(Canvas canvas, Size size) {
    if (!linesOnly) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFAF6EE));
    }

    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: linesOnly ? 0.05 : 0.08)
      ..strokeWidth = 1;
    const lineGap = 35.0;
    final lines = (size.height / lineGap).ceil().clamp(minLines, 24);
    for (var i = 0; i < lines; i++) {
      final y = 24 + i * lineGap;
      canvas.drawLine(Offset(linesOnly ? 4 : 20, y), Offset(size.width - 8, y), linePaint);
    }

    if (!linesOnly) {
      final marginPaint = Paint()
        ..color = const Color(0xFFE8B4B4).withValues(alpha: 0.4)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(20, 0), Offset(20, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _JournalLinesPainter oldDelegate) =>
      oldDelegate.minLines != minLines || oldDelegate.linesOnly != linesOnly;
}
