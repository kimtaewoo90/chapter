import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// CHAPTER 하단 — 나의 책 · [기록] · 더보기
class ChapterBottomBar extends StatelessWidget {
  const ChapterBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onRecord,
    required this.recordSelected,
  });

  /// 0 홈 · 1 기록 · 2 더보기
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onRecord;
  final bool recordSelected;

  static const _barHeight = 48.0;
  static const _stackHeight = 56.0;
  static const _horizontalInset = 14.0;
  static const _bottomMargin = 10.0;
  static const _bookmarkWidth = 52.0;

  static double totalHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + _bottomMargin + _stackHeight;
  }

  static double listBottomPadding(BuildContext context) => totalHeight(context) + 12;

  /// 크게 보기 — 탭 바로 위까지 페이지를 길게 (extendBody)
  static double spreadBottomInset(BuildContext context) => totalHeight(context) + 2;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: bottom + _bottomMargin + _stackHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_horizontalInset, 0, _horizontalInset, bottom + _bottomMargin),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: const _ChapterSlab(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _ChapterNavItem(
                        label: '홈',
                        selected: currentIndex == 0,
                        onTap: () => onSelect(0),
                      ),
                    ),
                    const SizedBox(width: _bookmarkWidth),
                    Expanded(
                      child: _ChapterNavItem(
                        label: '더보기',
                        selected: currentIndex == 2,
                        onTap: () => onSelect(2),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: _ChapterBookmarkButton(
                  selected: recordSelected,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onRecord();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterSlab extends StatelessWidget {
  const _ChapterSlab();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.ink.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.accentLight.withValues(alpha: 0.9),
                      AppTheme.accent,
                    ],
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _SlabScratchPainter(),
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlabScratchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width * 0.72, 8), Offset(size.width * 0.38, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChapterNavItem extends StatelessWidget {
  const _ChapterNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          height: ChapterBottomBar._barHeight,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: selected ? 12.5 : 11.5,
                letterSpacing: selected ? 0.6 : 0.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.42),
                height: 1,
              ),
              child: Text(label, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterBookmarkButton extends StatelessWidget {
  const _ChapterBookmarkButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC4A882), AppTheme.accent, Color(0xFF4A3F36)],
  );

  @override
  Widget build(BuildContext context) {
    final w = selected ? 48.0 : 44.0;
    final h = selected ? 56.0 : 52.0;

    return Semantics(
      button: true,
      label: '기록',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: selected ? 0.35 : 0.22),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: w,
              height: h,
              child: ClipPath(
                clipper: _BookmarkClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? _gradient.colors
                          : [AppTheme.accent, const Color(0xFF5C5048), const Color(0xFF3D3530)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      selected ? Icons.edit_outlined : Icons.add_rounded,
                      color: Colors.white,
                      size: selected ? 26 : 24,
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
}

class _BookmarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final notch = size.height * 0.16;
    const topRadius = 6.0;
    return Path()
      ..moveTo(topRadius, 0)
      ..lineTo(size.width - topRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, topRadius)
      ..lineTo(size.width, size.height - notch)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height - notch)
      ..lineTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
