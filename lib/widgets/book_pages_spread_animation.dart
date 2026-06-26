import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 왼쪽 등뼈 → 오른쪽 앞으로 스르륵 펼쳐지는 책
///
/// rotateY **양수** = 페이지가 화면 쪽(앞)으로 열림 (뒤로 도는 느낌 X)
class BookPagesSpreadAnimation extends StatefulWidget {
  const BookPagesSpreadAnimation({
    super.key,
    this.width = 300,
    this.height = 200,
    this.pageCount = 6,
    this.autoPlay = true,
  });

  final double width;
  final double height;
  final int pageCount;
  final bool autoPlay;

  @override
  State<BookPagesSpreadAnimation> createState() => _BookPagesSpreadAnimationState();
}

class _BookPagesSpreadAnimationState extends State<BookPagesSpreadAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _paperColor = Color(0xFFFAF7F2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _c01(double v) => v.clamp(0.0, 1.0);

  double _ease(double x) {
    final t = _c01(x);
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  /// 바깥 페이지부터 — 길게 겹치며
  double _pageP(int outer, double t) {
    return _ease((t - outer * 0.04) / 0.76);
  }

  /// 앞으로(오른쪽) 펼쳐지는 각도 — 양수 rotateY
  double _forwardAngle(double p, int outer) {
    final t = _c01(p);
    final fan = math.sin(t * math.pi / 2);
    // 바깥쪽일수록 더 많이 펼쳐짐
    final spread = 0.18 + outer * 0.06;
    return fan * spread * math.pi;
  }

  _Layout _layout() {
    const spineW = 7.0;
    const margin = 4.0;
    final avail = widget.width - margin * 2;
    final halfW = (avail - spineW) / 2;
    final pageH = widget.height * 0.86;
    final top = (widget.height - pageH) / 2;
    // 등뼈 = 화면 왼쪽
    const spineX = margin;
    return _Layout(
      margin: margin,
      spineW: spineW,
      halfW: halfW,
      pageH: pageH,
      top: top,
      spineX: spineX,
      totalW: avail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _c01(_controller.value);
        final l = _layout();
        final openBlend = _ease((t - 0.8) / 0.2);

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                _shadow(t, l),
                if (openBlend > 0.01) _flatOpen(l, openBlend),
                if (openBlend < 0.99) ..._fanPages(t, l, 1 - openBlend),
                _spine(l),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _fanPages(double t, _Layout l, double vis) {
    if (vis <= 0) return [];
    final widgets = <Widget>[];

    for (var i = 0; i < widget.pageCount; i++) {
      final outer = widget.pageCount - 1 - i;
      final p = _pageP(outer, t);
      if (p <= 0.001) continue;

      final isCover = outer == 0;
      final angle = _forwardAngle(p, outer);
      // 닫힘: 오른쪽으로 살짝 겹침 / 열림: 앞으로 펼쳐짐
      final stackX = (1 - p) * outer * 1.5;
      final lift = math.sin(_c01(p) * math.pi) * 4;
      final shade = _c01(math.sin(_c01(p) * math.pi) * 0.25);

      widgets.add(
        Positioned(
          left: l.spineX + l.spineW + stackX,
          top: l.top - lift,
          width: (l.halfW * 1.05 - stackX * 0.3).clamp(20.0, l.halfW * 1.1),
          height: l.pageH,
          child: Opacity(
            opacity: _c01(vis * (0.5 + p * 0.5)),
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateY(angle),
              child: Stack(
                children: [
                  if (isCover) _cover() else _paper(lines: 3 + i % 2),
                  if (shade > 0.01)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.transparent, AppTheme.ink.withValues(alpha: shade)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 최종: 양쪽 페이지 쫙 펼침
  Widget _flatOpen(_Layout l, double blend) {
    final b = _c01(blend);
    return Stack(
      children: [
        Positioned(
          left: l.spineX + l.spineW,
          top: l.top,
          width: l.halfW,
          height: l.pageH,
          child: Opacity(
            opacity: b,
            child: _paper(isLeft: false, showEmoji: true, lines: 4),
          ),
        ),
        Positioned(
          left: l.spineX + l.spineW + l.halfW,
          top: l.top,
          width: l.halfW,
          height: l.pageH,
          child: Opacity(
            opacity: b,
            child: _paper(isLeft: true, showDate: true, lines: 4),
          ),
        ),
      ],
    );
  }

  Widget _cover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
        gradient: const LinearGradient(
          colors: [Color(0xFF6E5F52), Color(0xFF9A8268), Color(0xFF7A6A5C)],
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.ink.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(2, 2)),
        ],
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'CHAPTER',
              style: TextStyle(fontSize: 7, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paper({
    bool isLeft = false,
    int lines = 3,
    bool showDate = false,
    bool showEmoji = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _paperColor,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(5) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(5),
        ),
        border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.4), width: 0.5),
      ),
      padding: EdgeInsets.fromLTRB(isLeft ? 12 : 10, 14, isLeft ? 10 : 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 2,
            color: AppTheme.accent.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          ...List.generate(lines, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              height: 2,
              width: double.infinity,
              color: AppTheme.inkMuted.withValues(alpha: 0.08 + i * 0.012),
            );
          }),
          const Spacer(),
          if (showDate)
            Text('3.12', style: TextStyle(fontSize: 9, color: AppTheme.inkMuted.withValues(alpha: 0.5))),
          if (showEmoji)
            const Align(alignment: Alignment.bottomRight, child: Text('🌸', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _shadow(double t, _Layout l) {
    final s = _ease(t);
    return Positioned(
      bottom: 2,
      left: l.spineX,
      child: Container(
        width: l.totalW * (0.35 + s * 0.65),
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.ink.withValues(alpha: 0.05 + s * 0.04), blurRadius: 8 + s * 6)],
        ),
      ),
    );
  }

  Widget _spine(_Layout l) {
    return Positioned(
      left: l.spineX,
      top: l.top,
      child: Container(
        width: l.spineW,
        height: l.pageH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF5A4D42), Color(0xFF8B7355), Color(0xFF5A4D42)],
          ),
        ),
      ),
    );
  }
}

class _Layout {
  const _Layout({
    required this.margin,
    required this.spineW,
    required this.halfW,
    required this.pageH,
    required this.top,
    required this.spineX,
    required this.totalW,
  });

  final double margin;
  final double spineW;
  final double halfW;
  final double pageH;
  final double top;
  final double spineX;
  final double totalW;
}

typedef BookOpenAnimation = BookPagesSpreadAnimation;
