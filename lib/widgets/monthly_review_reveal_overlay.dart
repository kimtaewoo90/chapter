import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';
import '../models/monthly_review.dart';
import 'mini_ai_sparkle_lottie.dart';

/// 월간 리포트 말일 reveal
class MonthlyReviewRevealOverlay extends StatefulWidget {
  const MonthlyReviewRevealOverlay({
    super.key,
    required this.review,
    required this.onDismiss,
    required this.onViewReview,
  });

  final MonthlyReview review;
  final VoidCallback onDismiss;
  final VoidCallback onViewReview;

  @override
  State<MonthlyReviewRevealOverlay> createState() =>
      _MonthlyReviewRevealOverlayState();
}

class _MonthlyReviewRevealOverlayState extends State<MonthlyReviewRevealOverlay> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _showContent = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showContent) ...[
                  const MiniAiSparkleLottie()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack),
                  const SizedBox(height: 28),
                  Text(
                    widget.review.periodLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 700.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Text(
                    '한 달을 돌아볼 준비가 됐어요',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.6,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 600.ms),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: widget.onViewReview,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentLight,
                      foregroundColor: AppTheme.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('펼쳐보기'),
                  )
                      .animate()
                      .fadeIn(delay: 1050.ms, duration: 500.ms)
                      .slideY(begin: 0.12, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      '나중에',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1150.ms, duration: 400.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOut);
  }
}
