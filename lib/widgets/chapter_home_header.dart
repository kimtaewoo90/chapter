import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 홈 상단 — [로고] Chapter · 더보기(⋯)
class ChapterHomeHeader extends StatelessWidget {
  const ChapterHomeHeader({
    super.key,
    required this.onOpenMore,
  });

  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 4, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Chapter',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: AppTheme.ink,
            ),
          ),
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
