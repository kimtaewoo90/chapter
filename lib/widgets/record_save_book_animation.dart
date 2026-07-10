import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/constants/book_cover_type.dart';
import '../core/theme/app_theme.dart';
import 'book_cover_artwork.dart';

/// 저장 완료 — 작성한 실제 일기 페이지가 책(앱 아이콘 표지)에 끼워 넣어지는 연출
class RecordSaveBookAnimation extends StatefulWidget {
  const RecordSaveBookAnimation({
    super.key,
    required this.diaryPage,
    this.bookProgressPercent,
    this.coverTitle = '나의책',
    this.width = 340,
    this.height = 340,
  });

  /// `BookPdfPageFrame` + `BookPdfDiaryPageContent` 등 실제 일기 페이지
  final Widget diaryPage;
  final int? bookProgressPercent;
  final String coverTitle;
  final double width;
  final double height;

  @override
  State<RecordSaveBookAnimation> createState() => _RecordSaveBookAnimationState();
}

class _RecordSaveBookAnimationState extends State<RecordSaveBookAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _paperColor = Color(0xFFFAF7F2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _c01(double v) => v.clamp(0.0, 1.0);

  double _easeOutCubic(double x) {
    final t = _c01(x);
    return 1 - math.pow(1 - t, 3).toDouble();
  }

  double _easeInOutCubic(double x) {
    final t = _c01(x);
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  double _easeInOutQuart(double x) {
    final t = _c01(x);
    return t < 0.5 ? 8 * t * t * t * t : 1 - math.pow(-2 * t + 2, 4) / 2;
  }

  double _easeInOutSine(double x) => (1 - math.cos(_c01(x) * math.pi)) / 2;

  double _easeInCubic(double x) {
    final t = _c01(x);
    return t * t * t;
  }

  double _seg(double t, double a, double b) => _c01((t - a) / (b - a));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final l = _layout();

        // 0.00–0.20  작성 페이지 (위쪽, 작게)
        // 0.14–0.38  책 등장 (아래 중앙, 크게)
        // 0.34–0.54  표지 열림
        // 0.46–0.90  페이지 삽입 (길게·부드럽게)
        final pageFocus = 1 - _easeInOutCubic(_seg(t, 0.14, 0.34));
        final bookEnter = _easeOutCubic(_seg(t, 0.14, 0.38));
        final coverOpen = _easeInOutCubic(_seg(t, 0.34, 0.54));
        final insert = _easeInOutSine(_seg(t, 0.46, 0.90));
        final settle = _easeInOutCubic(_seg(t, 0.78, 1.0));

        final spread = coverOpen * (1 - settle * 0.75);
        final inserted = insert > 0.975;
        final spinePulse = _easeOutCubic(_seg(t, 0.80, 1.0));
        final spineExtra = ((widget.bookProgressPercent ?? 10) / 100.0) * 4;
        final bookScale = 0.88 + bookEnter * 0.12;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: bookScale,
                alignment: Alignment(0, 0.55),
                child: Transform.translate(
                  offset: Offset(0, (1 - bookEnter) * 28),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _bookShadow(spread, l),
                      _spine(l, spread, spineExtra, spinePulse, inserted),
                      ..._innerPages(l, spread, inserted),
                      _coverPage(l, spread, coverOpen),
                    ],
                  ),
                ),
              ),
              if (!inserted) _flyingDiaryPage(l, pageFocus, insert, bookEnter),
            ],
          ),
        );
      },
    );
  }

  _Layout _layout() {
    const spineW = 12.0;
    final pageH = widget.height * 0.62;
    final halfW = pageH * 0.72;
    final bookWidth = spineW + halfW * 1.02;
    final spineX = (widget.width - bookWidth) / 2;
    final top = widget.height * 0.24;
    return _Layout(
      spineW: spineW,
      halfW: halfW,
      pageH: pageH,
      top: top,
      spineX: spineX,
      totalW: bookWidth,
    );
  }

  Widget _flyingDiaryPage(
    _Layout l,
    double pageFocus,
    double insert,
    double bookEnter,
  ) {
    final pageW = widget.width * 0.62;
    final pageH = pageW * (BookPdfPageSpec.height / BookPdfPageSpec.width);

    final focusScale = 0.44 + pageFocus * 0.14;

    final focusX = (widget.width - pageW * focusScale) / 2;
    final focusY = widget.height * 0.02;

    final slotX = l.spineX + l.spineW + 2;
    final slotY = l.top + l.pageH * 0.06;
    final slotW = l.halfW * 0.96;
    final endScale = (slotW / pageW).clamp(0.30, 0.58);

    // 삽입: 먼저 살짝 아래로 떨어진 뒤, 책등 쪽으로 스르륵 미끄러짐
    final drop = _easeOutCubic(_seg(insert, 0.0, 0.38));
    final slide = _easeInOutQuart(_seg(insert, 0.18, 1.0));
    final scaleT = _easeInOutSine(_seg(insert, 0.12, 1.0));

    final hoverY = focusY + (slotY - focusY) * 0.42;
    final y = focusY + (hoverY - focusY) * drop + (slotY - hoverY) * slide;
    final x = focusX + (slotX - focusX) * slide;

    final scale = focusScale + (endScale - focusScale) * scaleT;
    final w = pageW * scale;
    final h = pageH * scale;

    // 책 사이로 들어갈 때 왼쪽(등 쪽)부터 서서히 사라짐
    final tuck = _easeInCubic(_seg(insert, 0.72, 1.0));
    final widthFactor = (1 - tuck * 0.92).clamp(0.08, 1.0);
    final shadowBlur = (16 + pageFocus * 6) * (1 - tuck * 0.6);

    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: IgnorePointer(
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: RepaintBoundary(
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(-0.06 * slide * (1 - tuck)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warmShadow.withValues(
                          alpha: 0.22 + bookEnter * 0.18,
                        ),
                        blurRadius: shadowBlur,
                        offset: Offset(2 - slide * 4, 5 + insert * 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: widget.diaryPage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPage(_Layout l, double spread, double coverOpen) {
    final angle = math.sin(coverOpen * math.pi / 2) * 0.5 * math.pi;
    final stackX = (1 - coverOpen) * 1.5;

    return Positioned(
      left: l.spineX + l.spineW + stackX,
      top: l.top,
      width: l.halfW,
      height: l.pageH,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          child: BookCoverArtwork(
            coverType: BookCoverType.chapterIcon,
            dateRangeLabel: '',
            coverTitle: widget.coverTitle,
            coverYear: DateTime.now().year,
            compact: true,
            fillPage: true,
            showDate: false,
          ),
        ),
      ),
    );
  }

  List<Widget> _innerPages(_Layout l, double spread, bool inserted) {
    final count = inserted ? 3 : 2;
    final widgets = <Widget>[];

    for (var i = 0; i < count; i++) {
      final depth = count - i;
      final p = _easeInOutCubic((spread - depth * 0.07) / 0.85).clamp(0.0, 1.0);
      if (p <= 0.01) continue;

      final angle = math.sin(p * math.pi / 2) * (0.08 + depth * 0.035) * math.pi;
      final stackX = (1 - p) * depth * 1.1 + 3;
      final shade = math.sin(p * math.pi) * 0.14;

      widgets.add(
        Positioned(
          left: l.spineX + l.spineW + stackX,
          top: l.top + depth * 0.6,
          width: (l.halfW * 0.98 - stackX * 0.2).clamp(30.0, l.halfW),
          height: l.pageH - depth * 0.8,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _paperPage(lines: 2 + i % 2, highlight: inserted && i == 0),
                if (shade > 0.01)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          AppTheme.ink.withValues(alpha: shade),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _bookShadow(double spread, _Layout l) {
    return Positioned(
      top: l.top + l.pageH - 2,
      left: l.spineX - 4,
      child: Container(
        width: l.totalW + 8 + spread * 12,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08 + spread * 0.06),
              blurRadius: 18 + spread * 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spine(
    _Layout l,
    double spread,
    double spineExtra,
    double pulse,
    bool inserted,
  ) {
    final thickness = l.spineW + spread * 1.2 + spineExtra + pulse * 2 + (inserted ? 1.5 : 0);
    return Positioned(
      left: l.spineX - pulse * 0.5,
      top: l.top - spread * 0.4,
      child: Container(
        width: thickness,
        height: l.pageH + spread * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF5A4D42),
              Color.lerp(const Color(0xFF8B7355), AppTheme.accent, pulse * 0.22)!,
              const Color(0xFF5A4D42),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.12 * pulse),
              blurRadius: 6 + pulse * 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paperPage({required int lines, bool highlight = false}) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFFDF9) : _paperColor,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
        border: Border.all(
          color: highlight
              ? AppTheme.accent.withValues(alpha: 0.35)
              : AppTheme.paperDark.withValues(alpha: 0.35),
          width: highlight ? 0.8 : 0.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 2,
            color: AppTheme.accent.withValues(alpha: highlight ? 0.4 : 0.25),
          ),
          const SizedBox(height: 5),
          ...List.generate(
            lines,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              height: 2,
              width: double.infinity,
              color: AppTheme.inkMuted.withValues(alpha: 0.06 + i * 0.01),
            ),
          ),
        ],
      ),
    );
  }
}

class _Layout {
  const _Layout({
    required this.spineW,
    required this.halfW,
    required this.pageH,
    required this.top,
    required this.spineX,
    required this.totalW,
  });

  final double spineW;
  final double halfW;
  final double pageH;
  final double top;
  final double spineX;
  final double totalW;
}
