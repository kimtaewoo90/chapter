import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/book_layout/book_pdf_style.dart';
import '../core/constants/dev_flags.dart';
import '../core/theme/app_theme.dart';
import '../models/record_save_step.dart';
import 'record_save_book_animation.dart';
import 'onboarding_book_lottie.dart';

/// 저장 중 — 책 테마 + 단계별 메시지 (스피너 대신)
class RecordSaveOverlay extends StatelessWidget {
  const RecordSaveOverlay({
    super.key,
    required this.step,
    this.complete = false,
    this.bookProgressPercent,
    this.diaryPage,
    this.coverTitle = '나의책',
  });

  final RecordSaveStep step;
  final bool complete;
  final int? bookProgressPercent;
  /// 저장된 실제 일기 페이지 (`BookPdfPageFrame` 등)
  final Widget? diaryPage;
  final String coverTitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final useV2 = kRecordSaveAnimationV2;

    return Material(
      color: AppTheme.paper.withValues(alpha: 0.92),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 340,
                  height: complete && diaryPage != null ? 340 : (useV2 ? 160 : 140),
                  child: complete
                      ? (diaryPage != null
                          ? RecordSaveBookAnimation(
                              diaryPage: diaryPage!,
                              bookProgressPercent: bookProgressPercent,
                              coverTitle: coverTitle,
                            )
                          : (useV2
                              ? _PageAddedAnimationV2(
                                  bookProgressPercent: bookProgressPercent,
                                )
                              : const _PageAddedAnimation()))
                      : OnboardingBookLottie()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.98, 0.98),
                            end: const Offset(1.02, 1.02),
                            duration: 1.4.seconds,
                            curve: Curves.easeInOut,
                          ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOut,
                  child: Text(
                    complete ? '한 장 더 쌓였어요' : step.label,
                    key: ValueKey(complete ? 'done' : step.name),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                if (complete) ...[
                  const SizedBox(height: 8),
                  Text(
                    bookProgressPercent != null && useV2
                        ? '오늘이 책에 남았어요 · 한 해 $bookProgressPercent%'
                        : '오늘이 책에 남았어요',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    '잠시만 기다려 주세요',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  _StepDots(activeIndex: step.stepIndex),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phase A 저장 완료 연출
class _PageAddedAnimation extends StatelessWidget {
  const _PageAddedAnimation();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: 56,
          color: AppTheme.accent.withValues(alpha: 0.22),
        ),
        _FlipPageCard()
            .animate()
            .fadeIn(duration: 280.ms)
            .slideX(
              begin: 0.35,
              end: 0,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
            .rotate(
              begin: 0.12,
              end: 0,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 520.ms,
              curve: Curves.easeOutBack,
            ),
      ],
    );
  }
}

/// Phase C — 책등 + 페이지 끼워 넣기
class _PageAddedAnimationV2 extends StatelessWidget {
  const _PageAddedAnimationV2({this.bookProgressPercent});

  final int? bookProgressPercent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SpineStack(pageCount: _spinePages),
            const SizedBox(width: 6),
            Icon(
              Icons.menu_book_rounded,
              size: 52,
              color: AppTheme.accent.withValues(alpha: 0.28),
            ),
          ],
        ),
        _FlipPageCard()
            .animate()
            .fadeIn(duration: 260.ms)
            .slideX(
              begin: 0.5,
              end: -0.08,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            )
            .rotate(
              begin: 0.18,
              end: -0.04,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),
      ],
    );
  }

  int get _spinePages {
    final p = bookProgressPercent ?? 12;
    return (p / 8).ceil().clamp(2, 6);
  }
}

class _SpineStack extends StatelessWidget {
  const _SpineStack({required this.pageCount});

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 56,
      child: Stack(
        children: List.generate(pageCount, (i) {
          return Positioned(
            left: i * 1.8,
            bottom: i * 2.0,
            child: Container(
              width: 10,
              height: 44 - i * 2,
              decoration: BoxDecoration(
                color: BookPdfStyle.paper,
                borderRadius: BorderRadius.circular(1),
                border: Border.all(color: BookPdfStyle.line, width: 0.4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FlipPageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 68,
      decoration: BoxDecoration(
        color: BookPdfStyle.paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: BookPdfStyle.line, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmShadow.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 0.5,
            color: BookPdfStyle.line,
          ),
          const SizedBox(height: 6),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(RecordSaveStep.values.length, (i) {
        final active = i <= activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : AppTheme.paperDark,
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(target: active ? 1 : 0).scale(duration: 220.ms);
      }),
    );
  }
}
