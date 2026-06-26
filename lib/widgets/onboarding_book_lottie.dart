import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// 온보딩 1페이지 — 책 펼침 Lottie (라인 아트 + CHAPTER 톤)
class OnboardingBookLottie extends StatelessWidget {
  const OnboardingBookLottie({
    super.key,
    this.autoPlay = true,
    this.loop = true,
  });

  final bool autoPlay;
  final bool loop;

  /// 원본 파란 라인 → CHAPTER 웜 브라운
  static final _chapterStroke = Color.lerp(AppTheme.accent, AppTheme.ink, 0.25)!;

  static final _delegates = LottieDelegates(
    values: [
      ValueDelegate.strokeColor(
        const ['book', 'Shape 1', 'Stroke 1'],
        value: _chapterStroke,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/book_open.json',
      delegates: _delegates,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      repeat: loop,
      animate: autoPlay,
      errorBuilder: (_, __, ___) => const _FallbackBook(),
    );
  }
}

class _FallbackBook extends StatelessWidget {
  const _FallbackBook();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Icon(
        Icons.menu_book_outlined,
        size: 72,
        color: AppTheme.accent.withValues(alpha: 0.45),
      ),
    );
  }
}

typedef BookOpenAnimation = OnboardingBookLottie;
typedef BookPagesSpreadAnimation = OnboardingBookLottie;
