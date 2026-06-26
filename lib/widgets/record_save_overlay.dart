import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';
import '../models/record_save_step.dart';
import 'onboarding_book_lottie.dart';

/// 저장 중 — 책 테마 + 단계별 메시지 (스피너 대신)
class RecordSaveOverlay extends StatelessWidget {
  const RecordSaveOverlay({
    super.key,
    required this.step,
    this.complete = false,
  });

  final RecordSaveStep step;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppTheme.paper.withValues(alpha: 0.92),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  height: 100,
                  child: complete
                      ? Icon(
                          Icons.check_circle_outline,
                          size: 72,
                          color: AppTheme.accent.withValues(alpha: 0.9),
                        )
                          .animate()
                          .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 280.ms)
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
                    complete ? '오늘이 책에 남았어요' : step.label,
                    key: ValueKey(complete ? 'done' : step.name),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                if (!complete) ...[
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
