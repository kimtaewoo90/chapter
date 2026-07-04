import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'chapter_wordmark.dart';

/// 홈 상단 — 손글씨 워드마크 · 더보기(⋯)
class ChapterHomeHeader extends StatelessWidget {
  const ChapterHomeHeader({
    super.key,
    required this.onOpenMore,
  });

  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ChapterWordmark(height: 50, horizontalScale: 1.5),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: '더보기',
            color: AppTheme.inkMuted,
            onPressed: onOpenMore,
          ),
        ],
      ),
    );
  }
}
