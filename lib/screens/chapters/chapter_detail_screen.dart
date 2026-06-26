import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/chapter_cover.dart';
import '../../models/chapter_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/paper_background.dart';

class ChapterDetailScreen extends StatelessWidget {
  const ChapterDetailScreen({super.key, required this.chapter});

  final ChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final allEntries = context.watch<AppState>().allEntries;
    final entries = ChapterCover.entriesInChapter(chapter, allEntries);
    final cover = ChapterCover.coverUri(chapter: chapter, allEntries: allEntries);
    final moments = ChapterCover.momentUris(chapter: chapter, allEntries: allEntries, limit: 12);

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(chapter.title)),
        body: ListView(
          children: [
            if (cover != null)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: EntryPhoto(url: cover, height: 220, borderRadius: 0),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.narrative,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppTheme.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  Text('무드 타임라인', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(label: Text(e.moodEmoji ?? '😶')),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('대표 순간', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _statRow(Icons.calendar_today, '${chapter.entryCount}일 기록'),
                  _statRow(Icons.photo, '${chapter.photoCount}장의 사진'),
                  if (moments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: moments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: EntryPhoto(url: moments[i], height: 88, borderRadius: 10),
                          ),
                        ),
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

  Widget _statRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
