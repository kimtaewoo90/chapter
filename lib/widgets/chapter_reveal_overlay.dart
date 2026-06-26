import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/chapter_moment.dart';
import 'mini_ai_sparkle_lottie.dart';

/// 챕터 완성 순간 — 풀스크린 감동 리veal
class ChapterRevealOverlay extends StatefulWidget {
  const ChapterRevealOverlay({
    super.key,
    required this.payload,
    required this.onDismiss,
    required this.onViewChapter,
  });

  final ChapterRevealPayload payload;
  final VoidCallback onDismiss;
  final VoidCallback onViewChapter;

  @override
  State<ChapterRevealOverlay> createState() => _ChapterRevealOverlayState();
}

class _ChapterRevealOverlayState extends State<ChapterRevealOverlay> {
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
    final periodFmt = DateFormat('M월 d일', 'ko_KR');
    final period =
        '${periodFmt.format(widget.payload.startDate)} — ${periodFmt.format(widget.payload.endDate)}';

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
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
                        'Chapter',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppTheme.accentLight,
                          letterSpacing: 4,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 12),
                      Text(
                        '완성',
                        style: textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 8,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 600.ms)
                          .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut),
                      const SizedBox(height: 32),
                      Text(
                        widget.payload.title,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 550.ms, duration: 700.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                      Text(
                        '「${widget.payload.title}」 챕터가 완성되었어요',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.6,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 750.ms, duration: 600.ms),
                      const SizedBox(height: 12),
                      Text(
                        '$period · ${widget.payload.entryCount}일',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 500.ms),
                      if (widget.payload.narrative.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          widget.payload.narrative,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontStyle: FontStyle.italic,
                            height: 1.65,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 1050.ms, duration: 600.ms),
                      ],
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed: widget.onViewChapter,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentLight,
                          foregroundColor: AppTheme.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('챕터 읽기'),
                      )
                          .animate()
                          .fadeIn(delay: 1200.ms, duration: 500.ms)
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
                      ).animate().fadeIn(delay: 1300.ms, duration: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut);
  }
}
