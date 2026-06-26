import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/theme/app_theme.dart';
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
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
          if (onEdit != null) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('이 날 수정하기'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
