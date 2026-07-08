import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 책 한 페이지 — 등뼈·줄 노트 배경 (기록·피드 공용)
class BookPageShell extends StatelessWidget {
  const BookPageShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(26, 22, 18, 24),
    this.margin = const EdgeInsets.symmetric(horizontal: 4),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  static const decoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    boxShadow: [
      BoxShadow(
        color: Color(0x302C2824),
        blurRadius: 24,
        offset: Offset(5, 12),
      ),
      BoxShadow(
        color: Color(0x122C2824),
        blurRadius: 6,
        offset: Offset(1, 2),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BookPageLinedPainter())),
            const BookPageSpine(),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class BookPageSpine extends StatelessWidget {
  const BookPageSpine({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.ink.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택된 무드 — 스탬프 형태
class MoodStampBadge extends StatelessWidget {
  const MoodStampBadge({
    super.key,
    required this.emoji,
    required this.label,
    this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stamp = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Transform.rotate(angle: 0.06, child: stamp);
    }

    return Transform.rotate(
      angle: 0.06,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: stamp,
        ),
      ),
    );
  }
}

class BookPageLinedPainter extends CustomPainter {
  static const _paper = Color(0xFFFAF6EE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);

    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const lineGap = 28.0;
    for (var y = 56.0; y < size.height - 16; y += lineGap) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 10, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0xFFE8B4B4).withValues(alpha: 0.38)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
