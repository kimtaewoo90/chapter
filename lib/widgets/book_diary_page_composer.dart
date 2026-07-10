import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_page_planner.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/constants/diary_limits.dart';
import '../core/constants/moods.dart';
import '../core/theme/app_theme.dart';
import '../models/today_weather.dart';
import '../providers/app_state.dart';
import 'book_diary_page_edit_content.dart';
import 'book_diary_page_renderer.dart';
import 'mood_selector.dart';
import 'record_photo_picker_sheet.dart';
import 'today_photo_section.dart';
import 'today_weather_line.dart';

/// Phase B·C — 책 한 페이지에서 WYSIWYG 편집
class BookDiaryPageComposer extends StatefulWidget {
  const BookDiaryPageComposer({
    super.key,
    required this.date,
    required this.noteController,
    required this.noteFocusNode,
    required this.displayUris,
    required this.newPhotoFiles,
    required this.moodEmoji,
    required this.moodLabel,
    required this.isToday,
    required this.onMoodSelected,
    required this.onAddCustomMood,
    required this.onPickMultiple,
    required this.onPickCamera,
    required this.onRemoveDisplay,
    required this.onRemoveNew,
    required this.onReorderCombined,
    this.aiSuggestedMoods = const [],
    this.loadingAiSuggestions = false,
    this.isPickingPhotos = false,
    this.weather,
    this.loadingWeather = false,
    this.personalizedMoods = const [],
    this.recentMoods = const [],
  });

  final DateTime date;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final List<String> displayUris;
  final List<File> newPhotoFiles;
  final String? moodEmoji;
  final String? moodLabel;
  final bool isToday;
  final ValueChanged<MoodOption> onMoodSelected;
  final Future<void> Function(MoodOption mood) onAddCustomMood;
  final VoidCallback onPickMultiple;
  final VoidCallback onPickCamera;
  final ValueChanged<String> onRemoveDisplay;
  final ValueChanged<int> onRemoveNew;
  final void Function(List<String> reorderedDisplay, List<File> reorderedNew)
      onReorderCombined;
  final List<MoodOption> aiSuggestedMoods;
  final bool loadingAiSuggestions;
  final bool isPickingPhotos;
  final TodayWeather? weather;
  final bool loadingWeather;
  final List<MoodOption> personalizedMoods;
  final List<MoodOption> recentMoods;

  @override
  State<BookDiaryPageComposer> createState() => _BookDiaryPageComposerState();
}

class _BookDiaryPageComposerState extends State<BookDiaryPageComposer> {
  double _topInset = 0;
  Timer? _layoutDebounce;

  BookDiaryEntry get _draft => BookPreviewEntryMapper.fromDraft(
        date: widget.date,
        note: widget.noteController.text,
        photoUris: widget.displayUris,
        moodEmoji: widget.moodEmoji,
        moodLabel: widget.moodLabel,
      );

  @override
  void initState() {
    super.initState();
    widget.noteController.addListener(_scheduleLayoutRecalc);
    _recalcTopInset();
  }

  @override
  void didUpdateWidget(covariant BookDiaryPageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayUris != widget.displayUris ||
        oldWidget.moodEmoji != widget.moodEmoji ||
        oldWidget.moodLabel != widget.moodLabel) {
      _recalcTopInset();
    }
  }

  @override
  void dispose() {
    _layoutDebounce?.cancel();
    widget.noteController.removeListener(_scheduleLayoutRecalc);
    super.dispose();
  }

  void _scheduleLayoutRecalc() {
    _layoutDebounce?.cancel();
    _layoutDebounce = Timer(const Duration(milliseconds: 200), _recalcTopInset);
  }

  void _recalcTopInset() {
    if (!mounted) return;
    final fontId = context.read<AppState>().diaryFontId;
    final pages = BookPdfPreviewPlanner.planSingleEntry(
      entry: _draft,
      diaryFontId: fontId,
      centerOnPage: true,
    );
    final topInset = pages.isNotEmpty ? pages.first.topInset : 0.0;
    if (topInset != _topInset) {
      setState(() => _topInset = topInset);
    }
  }

  void _openMoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: MoodSelector(
            moods: widget.personalizedMoods,
            recentMoods: widget.recentMoods,
            aiSuggestedMoods: widget.aiSuggestedMoods,
            loadingAiSuggestions: widget.loadingAiSuggestions,
            selectedEmoji: widget.moodEmoji,
            selectedLabel: widget.moodLabel,
            bookPage: true,
            onSelected: (m) {
              widget.onMoodSelected(m);
              Navigator.pop(ctx);
            },
            onAddCustom: widget.onAddCustomMood,
          ),
        ),
      ),
    );
  }

  void _openPhotoSource() {
    showRecordPhotoSourceSheet(
      context,
      onGallery: widget.onPickMultiple,
      onCamera: widget.onPickCamera,
    );
  }

  void _openPhotoGallery() {
    if (widget.displayUris.isEmpty && widget.newPhotoFiles.isEmpty) {
      _openPhotoSource();
      return;
    }
    showRecordPhotoGallerySheet(
      context,
      displayUris: widget.displayUris,
      newPhotoFiles: widget.newPhotoFiles,
      maxPhotos: DiaryLimits.maxPhotosPerEntry,
      onPickMultiple: widget.onPickMultiple,
      onPickCamera: widget.onPickCamera,
      onRemoveDisplay: widget.onRemoveDisplay,
      onRemoveNew: widget.onRemoveNew,
      onReorderCombined: widget.onReorderCombined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontId = context.watch<AppState>().diaryFontId;
    final photoCount = widget.displayUris.length;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '책에 담기는 한 페이지',
          style: textTheme.labelSmall?.copyWith(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
          child: BookPdfPageFrame(
            child: BookDiaryPageEditContent(
              entry: _draft,
              noteController: widget.noteController,
              noteFocusNode: widget.noteFocusNode,
              diaryFontId: fontId,
              topInset: _topInset,
              onMoodTap: _openMoodSheet,
              onPhotosTap: _openPhotoGallery,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _ComposerChip(
              icon: Icons.emoji_emotions_outlined,
              label: widget.moodEmoji != null ? '무드' : '무드 선택',
              onTap: _openMoodSheet,
            ),
            _ComposerChip(
              icon: Icons.photo_outlined,
              label: '사진 $photoCount/${DiaryLimits.maxPhotosPerEntry}',
              onTap: widget.displayUris.isEmpty && widget.newPhotoFiles.isEmpty
                  ? _openPhotoSource
                  : _openPhotoGallery,
            ),
          ],
        ),
        if (widget.isToday) ...[
          const SizedBox(height: 8),
          TodayWeatherLine(
            weather: widget.weather,
            loading: widget.loadingWeather,
          ),
        ],
        if (widget.isPickingPhotos) ...[
          const SizedBox(height: 8),
          Text(
            '사진 불러오는 중…',
            style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ],
      ],
    );
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.accent),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall,
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      side: BorderSide(color: AppTheme.paperDark.withValues(alpha: 0.9)),
      onPressed: onTap,
    );
  }
}
