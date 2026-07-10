import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/diary_limits.dart';
import '../../core/constants/moods.dart';
import '../../core/theme/app_theme.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../widgets/book_diary_page_preview.dart';
import '../../widgets/book_page_shell.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/paper_journal_field.dart';
import '../../widgets/today_photo_section.dart';
import '../../widgets/today_weather_line.dart';

/// Phase A — 상단 PDF 미리보기 + 하단 「편집」 분리 UI
/// `kRecordBookPageComposer == false` 일 때만 사용 (되돌리기용)
class RecordScreenPhaseABody extends StatelessWidget {
  const RecordScreenPhaseABody({
    super.key,
    required this.day,
    required this.entry,
    required this.isToday,
    required this.displayUris,
    required this.newPhotoFiles,
    required this.noteController,
    required this.noteFocusNode,
    required this.moodEmoji,
    required this.moodLabel,
    required this.aiSuggestedMoods,
    required this.loadingAiMoodSuggestions,
    required this.isPickingPhotos,
    required this.savedAnim,
    required this.onMoodSelected,
    required this.onAddCustomMood,
    required this.onPickMultiple,
    required this.onPickCamera,
    required this.onRemoveDisplay,
    required this.onRemoveNew,
    required this.onReorderCombined,
    required this.onOpenJournalSheet,
  });

  final DateTime day;
  final DailyEntry? entry;
  final bool isToday;
  final List<String> displayUris;
  final List<File> newPhotoFiles;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final String? moodEmoji;
  final String? moodLabel;
  final List<MoodOption> aiSuggestedMoods;
  final bool loadingAiMoodSuggestions;
  final bool isPickingPhotos;
  final bool savedAnim;
  final ValueChanged<MoodOption> onMoodSelected;
  final Future<void> Function(MoodOption mood) onAddCustomMood;
  final VoidCallback onPickMultiple;
  final VoidCallback onPickCamera;
  final ValueChanged<String> onRemoveDisplay;
  final ValueChanged<int> onRemoveNew;
  final void Function(List<String> reorderedDisplay, List<File> reorderedNew)
      onReorderCombined;
  final Future<void> Function() onOpenJournalSheet;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dateFmt = DateFormat('yyyy년 M월 d일 · EEEE', 'ko_KR');
    final pageLabel = isToday
        ? '오늘의 한 페이지'
        : DateFormat('M월 d일 기록', 'ko_KR').format(day);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: noteController,
          builder: (context, noteValue, _) {
            return BookDiaryPagePreview.fromDraft(
              date: day,
              note: noteValue.text,
              photoUris: displayUris,
              moodEmoji: moodEmoji,
              moodLabel: moodLabel,
              caption: '책에 이렇게 담겨요',
            );
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '편집',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.inkMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
          ),
        ),
        const SizedBox(height: 10),
        BookPageShell(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.format(day),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.inkMuted,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pageLabel,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (moodEmoji != null)
                    MoodStampBadge(
                      emoji: moodEmoji!,
                      label: moodLabel ?? '',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              MoodSelector(
                moods: appState.personalizedMoods,
                recentMoods: appState.recentMoods,
                aiSuggestedMoods: aiSuggestedMoods,
                loadingAiSuggestions: loadingAiMoodSuggestions,
                selectedEmoji: moodEmoji,
                selectedLabel: moodLabel,
                bookPage: true,
                onSelected: onMoodSelected,
                onAddCustom: onAddCustomMood,
              ),
              const SizedBox(height: 14),
              Text(
                '📷 사진 붙이기',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TodayPhotoSection(
                displayUris: displayUris,
                newPhotoFiles: newPhotoFiles,
                maxPhotos: DiaryLimits.maxPhotosPerEntry,
                isPickingPhotos: isPickingPhotos,
                bookStyle: true,
                onPickMultiple: onPickMultiple,
                onPickCamera: onPickCamera,
                onRemoveDisplay: onRemoveDisplay,
                onRemoveNew: onRemoveNew,
                onReorderCombined: onReorderCombined,
              ).animate(target: savedAnim ? 1 : 0).shimmer(duration: 600.ms),
              const SizedBox(height: 18),
              Text(
                '✍️ 오늘의 글',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              PaperJournalField(
                controller: noteController,
                focusNode: noteFocusNode,
                embedded: true,
                readOnly: true,
                minLines: 5,
                maxLength: 500,
                hintText: '마음에 남는 것을 적어 보세요…',
                onTap: () => onOpenJournalSheet(),
              ),
              if (isToday) ...[
                const SizedBox(height: 10),
                TodayWeatherLine(
                  weather: appState.todayWeather,
                  loading: appState.loadingTodayWeather,
                ),
              ] else if (entry?.weatherDisplayLine != null) ...[
                const SizedBox(height: 10),
                Text(
                  entry!.weatherDisplayLine!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.inkMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
