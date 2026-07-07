import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/delete_entry_dialog.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../widgets/entry_photo_grid.dart';
import '../../widgets/paper_background.dart';

Future<void> showEntryDaySheet(
  BuildContext context,
  DailyEntry entry, {
  VoidCallback? onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => _EntryDaySheetBody(
        entry: entry,
        scrollController: scrollController,
        onEdit: onEdit,
      ),
    ),
  );
}

class _EntryDaySheetBody extends StatelessWidget {
  const _EntryDaySheetBody({
    required this.entry,
    required this.scrollController,
    this.onEdit,
  });

  final DailyEntry entry;
  final ScrollController scrollController;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diaryFontId = context.watch<AppState>().diaryFontId;
    final dateFmt = DateFormat('yyyy년 M월 d일 · EEEE', 'ko_KR');
    final uris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );

    return PaperBackground(
      child: Stack(
        children: [
          ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
            children: [
              Text(dateFmt.format(entry.date), style: textTheme.titleLarge),
              if (entry.moodEmoji != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(entry.moodEmoji!, style: const TextStyle(fontSize: 28)),
                    if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(entry.moodLabel!, style: textTheme.titleSmall?.copyWith(color: AppTheme.inkMuted)),
                    ],
                  ],
                ),
              ],
              if (entry.weatherDisplayLine != null) ...[
                const SizedBox(height: 8),
                Text(entry.weatherDisplayLine!, style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted)),
              ],
              if (uris.isNotEmpty) ...[
                const SizedBox(height: 16),
                EntryPhotoGrid(localPaths: uris, height: 200),
              ],
              if (EntryDiaryAi.primaryDiaryText(entry) != null) ...[
                const SizedBox(height: 20),
                if (EntryDiaryAi.shouldShowAiLine(entry))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      EntryDiaryAi.primaryDiaryText(entry)!,
                      style: diaryFontStyle(
                        diaryFontId,
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accent,
                      ),
                    ),
                  )
                else
                  Text(
                    EntryDiaryAi.primaryDiaryText(entry)!,
                    style: diaryFontStyle(diaryFontId, fontSize: 16, height: 1.6),
                  ),
              ],
            ],
          ),
          Positioned(
            left: 20,
            right: onEdit != null ? 80 : 20,
            bottom: 32,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _confirmAndDelete(context),
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                  label: Text(
                    '이 날 기록 삭제',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const Spacer(),
                if (onEdit != null) _EditDayFab(onPressed: onEdit!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final ok = await confirmDeleteDiaryEntry(context, entry.date);
    if (!ok || !context.mounted) return;

    try {
      await context.read<AppState>().deleteEntry(entry.date);
      if (!context.mounted) return;
      final label = DateFormat('M월 d일', 'ko_KR').format(entry.date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 기록을 삭제했어요.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }
}

class _EditDayFab extends StatelessWidget {
  const _EditDayFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '수정',
      child: Semantics(
        button: true,
        label: '수정',
        child: Material(
          color: AppTheme.accent,
          elevation: 3,
          shadowColor: AppTheme.ink.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Text('✏️', style: TextStyle(fontSize: 21, height: 1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
