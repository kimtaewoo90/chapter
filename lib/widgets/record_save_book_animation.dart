import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/constants/book_cover_type.dart';
import '../core/theme/app_theme.dart';
import 'book_cover_artwork.dart';

/// 저장 완료 — 작성한 실제 일기 페이지가 책(앱 아이콘 표지)에 끼워 넣어지는 연출
///
/// 모션 원칙 (Flutter에서 현실적으로 가장 자연스럽게):
/// 1. Interval + Curves 로 단계 분리 (등장 → 열림 → 삽입 → 닫힘)
/// 2. 페이지는 직선이 아니라 2차 베지어 호로 이동
/// 3. Anticipation / Follow-through (잠깐 머무름 → 스르륵 → 살짝 정착)
/// 4. Impeller 이슈 회피: 3D Transform 위에 Opacity 겹치지 않음
class RecordSaveBookAnimation extends StatefulWidget {
  const RecordSaveBookAnimation({
    super.key,
    required this.diaryPage,
    this.bookProgressPercent,
    this.coverTitle = '나의책',
    this.width = 340,
    this.height = 340,
  });

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

  late final Animation<double> _pageHold;
  late final Animation<double> _bookEnter;
  late final Animation<double> _coverOpen;
  late final Animation<double> _pageTravel;
  late final Animation<double> _pageTuck;
  late final Animation<double> _coverClose;
  late final Animation<double> _settlePulse;

  static const _paperColor = Color(0xFFFAF7F2);
  bool _didHaptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // 0.00–0.22  페이지 홀드 (작성한 장 보여주기)
    _pageHold = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
    );

    // 0.10–0.34  책 등장
    _bookEnter = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.34, curve: Curves.easeOutCubic),
    );

    // 0.28–0.48  표지 열림
    _coverOpen = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.48, curve: Curves.easeOutCubic),
    );

    // 0.42–0.82  페이지가 책으로 이동 (호 경로)
    _pageTravel = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.82, curve: Curves.easeInOutCubic),
    );

    // 0.68–0.92  책등 쪽으로 끼워지며 가려짐
    _pageTuck = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 0.92, curve: Curves.easeInCubic),
    );

    // 0.82–1.00  표지 닫힘 + 정착
    _coverClose = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: Curves.easeInOutCubic),
    );
    _settlePulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.86, 1.0, curve: Curves.easeOutBack),
    );

    _controller.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  void _onTick() {
    if (!_didHaptic && _pageTuck.value > 0.85) {
      _didHaptic = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  double _c01(double v) => v.clamp(0.0, 1.0);

  /// 2차 베지어 — 페이지가 살짝 오른쪽으로 호를 그리며 책 슬롯으로
  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final l = _layout();

        final bookEnter = _bookEnter.value;
        final coverOpenRaw = _coverOpen.value;
        final coverClose = _coverClose.value;
        final travel = _pageTravel.value;
        final tuck = _pageTuck.value;
        final hold = _pageHold.value;
        final pulse = _settlePulse.value;

        // 삽입 중엔 열린 상태 유지, 닫힘은 뒤쪽에서만
        final coverOpen = coverOpenRaw * (1 - coverClose * 0.88);
        final spread = coverOpen;
        final inserted = travel > 0.97 && tuck > 0.92;
        final spineExtra = ((widget.bookProgressPercent ?? 10) / 100.0) * 4;
        final bookScale = lerpDouble(0.88, 1.0, bookEnter)!;
        final bookLift = (1 - bookEnter) * 36.0;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, bookLift),
                child: Transform.scale(
                  scale: bookScale,
                  alignment: const Alignment(0, 0.4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _bookShadow(spread, l, pulse),
                      _spine(l, spread, spineExtra, pulse, inserted),
                      ..._innerPages(l, spread, inserted, travel),
                      _coverPage(l, coverOpen),
                    ],
                  ),
                ),
              ),
              if (!inserted)
                _flyingDiaryPage(
                  l: l,
                  hold: hold,
                  travel: travel,
                  tuck: tuck,
                  bookEnter: bookEnter,
                ),
            ],
          ),
        );
      },
    );
  }

  _Layout _layout() {
    const spineW = 12.0;
    final pageH = widget.height * 0.60;
    final halfW = pageH * 0.72;
    final bookWidth = spineW + halfW * 1.02;
    final spineX = (widget.width - bookWidth) / 2;
    final top = widget.height * 0.28;
    return _Layout(
      spineW: spineW,
      halfW: halfW,
      pageH: pageH,
      top: top,
      spineX: spineX,
      totalW: bookWidth,
    );
  }

  Widget _flyingDiaryPage({
    required _Layout l,
    required double hold,
    required double travel,
    required double tuck,
    required double bookEnter,
  }) {
    final pageW = widget.width * 0.66;
    final pageH = pageW * (BookPdfPageSpec.height / BookPdfPageSpec.width);

    // 홀드: 위에서 크게 / 이동 끝: 책 슬롯 크기
    final startScale = lerpDouble(0.42, 0.58, hold)!;
    final endScale = (l.halfW * 0.94 / pageW).clamp(0.34, 0.58);
    final scale = lerpDouble(startScale, endScale, Curves.easeInOutCubic.transform(travel))!;

    final start = Offset(
      (widget.width - pageW * startScale) / 2,
      widget.height * 0.02,
    );
    final end = Offset(
      l.spineX + l.spineW + 4,
      l.top + l.pageH * 0.04,
    );
    // 살짝 오른쪽으로 볼록한 호 → 책 입구로 미끄러지는 느낌
    final control = Offset(
      lerpDouble(start.dx, end.dx, 0.45)! + widget.width * 0.08,
      lerpDouble(start.dy, end.dy, 0.35)! - 8,
    );

    final pos = _quad(start, control, end, travel);
    final w = pageW * scale;
    final h = pageH * scale;

    // 끼워넣을 때 등 쪽부터 천천히 가려짐
    final widthFactor = (1 - tuck * 0.9).clamp(0.1, 1.0);
    // 살짝만 기울어 종이 느낌 (Impeller: Opacity와 분리)
    final tilt = -0.05 * Curves.easeOutCubic.transform(travel) * (1 - tuck);
    final shadowAlpha = (0.18 + bookEnter * 0.14) * (1 - tuck * 0.8);
    final shadowBlur = lerpDouble(18, 8, travel)!;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
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
                  ..rotateY(tilt),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warmShadow.withValues(alpha: shadowAlpha),
                        blurRadius: shadowBlur,
                        offset: Offset(
                          lerpDouble(2, -2, travel)!,
                          lerpDouble(6, 10, travel)!,
                        ),
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

  Widget _coverPage(_Layout l, double coverOpen) {
    // 천천히 크게 열렸다가, coverOpen이 줄어들면 다시 닫힘
    final angle = math.sin(_c01(coverOpen) * math.pi / 2) * 0.58 * math.pi;

    return Positioned(
      left: l.spineX + l.spineW,
      top: l.top,
      width: l.halfW,
      height: l.pageH,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(angle),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BookCoverArtwork(
                coverType: BookCoverType.chapterIcon,
                dateRangeLabel: '',
                coverTitle: widget.coverTitle,
                coverYear: DateTime.now().year,
                compact: true,
                fillPage: true,
                showDate: false,
              ),
              // 열릴 때 안쪽 그늘
              if (coverOpen > 0.05)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.ink.withValues(alpha: 0.12 * coverOpen),
                        Colors.transparent,
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

  List<Widget> _innerPages(
    _Layout l,
    double spread,
    bool inserted,
    double travel,
  ) {
    final count = inserted ? 3 : 2;
    final widgets = <Widget>[];

    for (var i = 0; i < count; i++) {
      final depth = count - i;
      final p = Curves.easeOutCubic.transform(
        ((spread - depth * 0.06) / 0.88).clamp(0.0, 1.0),
      );
      if (p <= 0.01) continue;

      final angle = math.sin(p * math.pi / 2) * (0.07 + depth * 0.03) * math.pi;
      final stackX = (1 - p) * depth * 1.0 + 2;
      final shade = math.sin(p * math.pi) * 0.12;
      // 페이지가 들어오면 맨 앞 속지 살짝 하이라이트
      final highlight = inserted && i == 0 || (travel > 0.7 && i == 0);

      widgets.add(
        Positioned(
          left: l.spineX + l.spineW + stackX,
          top: l.top + depth * 0.5,
          width: (l.halfW * 0.98 - stackX * 0.2).clamp(30.0, l.halfW),
          height: l.pageH - depth * 0.7,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _paperPage(lines: 2 + i % 2, highlight: highlight),
                if (shade > 0.01)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.horizontal(right: Radius.circular(5)),
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

  Widget _bookShadow(double spread, _Layout l, double pulse) {
    return Positioned(
      top: l.top + l.pageH - 2,
      left: l.spineX - 4,
      child: Container(
        width: l.totalW + 8 + spread * 14 + pulse * 4,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.07 + spread * 0.05),
              blurRadius: 16 + spread * 10,
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
    final thickness =
        l.spineW + spread * 1.1 + spineExtra + pulse * 2.2 + (inserted ? 1.8 : 0);
    return Positioned(
      left: l.spineX - pulse * 0.4,
      top: l.top - spread * 0.35,
      child: Container(
        width: thickness,
        height: l.pageH + spread * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF5A4D42),
              Color.lerp(const Color(0xFF8B7355), AppTheme.accent, pulse * 0.25)!,
              const Color(0xFF5A4D42),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.14 * pulse),
              blurRadius: 8 + pulse * 10,
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
