import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/entry_diary_ai.dart';
import '../models/daily_entry.dart';
import '../providers/app_state.dart';

/// 사진 없는 날 — 무드·글 중심 카드 (피드 타입 A)
class FeedMoodCard extends StatelessWidget {
  const FeedMoodCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final DailyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diaryFontId = context.watch<AppState>().diaryFontId;
    final caption = EntryDiaryAi.primaryDiaryText(entry);
    final isAi = EntryDiaryAi.shouldShowAiLine(entry);
    final emoji = entry.moodEmoji ?? '✍️';
    final palette = _MoodPalette.forEmoji(emoji);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -16,
              child: Text(
                emoji,
                style: TextStyle(fontSize: 88, color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 44, height: 1)),
                  if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.moodLabel!,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                  if (caption != null) ...[
                    const SizedBox(height: 14),
                    if (isAi)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Chapter',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      caption,
                      style: diaryFontStyle(
                        diaryFontId,
                        fontSize: 16,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        fontStyle: isAi ? FontStyle.italic : FontStyle.normal,
                        color: isAi ? AppTheme.accent : kDiaryInkColor,
                      ),
                    ),
                  ] else if (entry.moodLabel == null || entry.moodLabel!.isEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '오늘의 무드',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.inkMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (entry.weatherDisplayLine != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      entry.weatherDisplayLine!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.inkMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPalette {
  static List<Color> forEmoji(String emoji) {
    return switch (emoji) {
      '☀️' || '🌸' || '🙂' || '🎉' => [
          const Color(0xFFF8EED8),
          const Color(0xFFF0DFC4),
        ],
      '🌧️' || '☔' || '🌊' => [
          const Color(0xFFE4E8EF),
          const Color(0xFFD5DCE8),
        ],
      '🌙' || '😴' || '🫥' => [
          const Color(0xFFE8E4F0),
          const Color(0xFFD8D2E4),
        ],
      '☕' || '🍂' => [
          const Color(0xFFEDE4D8),
          const Color(0xFFE0D4C4),
        ],
      '😤' || '😵' || '💭' => [
          const Color(0xFFEAE6E2),
          const Color(0xFFDDD6CE),
        ],
      _ => [
          AppTheme.paper,
          AppTheme.paperDark.withValues(alpha: 0.85),
        ],
    };
  }
}
