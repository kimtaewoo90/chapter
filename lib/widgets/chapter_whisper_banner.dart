import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 백그라운드에서 쓰이는 중인 챕터 — 아련한 한 줄
class ChapterWhisperBanner extends StatelessWidget {
  const ChapterWhisperBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            AppTheme.paper.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.inkMuted,
              fontStyle: FontStyle.italic,
              height: 1.55,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '아직 당신만 모르는 이야기예요',
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.inkMuted.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
