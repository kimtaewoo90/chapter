import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_photos.dart';
import '../../core/utils/monthly_review_entry_matcher.dart';
import '../../core/utils/monthly_review_period.dart';
import '../../models/daily_entry.dart';
import '../../models/monthly_review.dart';
import '../../models/monthly_review_digest.dart';
import '../../providers/app_state.dart';
import '../../screens/feed/entry_day_sheet.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/entry_photo_viewer.dart';
import '../../widgets/paper_background.dart';

/// 월간 리포트 상세
class MonthlyReviewDetailScreen extends StatefulWidget {
  const MonthlyReviewDetailScreen({super.key, required this.review});

  final MonthlyReview review;

  @override
  State<MonthlyReviewDetailScreen> createState() => _MonthlyReviewDetailScreenState();
}

class _MonthlyReviewDetailScreenState extends State<MonthlyReviewDetailScreen> {
  late MonthlyReview _review;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
  }

  List<DailyEntry> _monthEntries(AppState state) {
    final parts = _review.periodKey.split('-');
    if (parts.length != 2) return [];
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return [];
    return MonthlyReviewPeriod.entriesInMonth(
      state.allEntries,
      year: year,
      month: month,
    );
  }

  Future<void> _regenerate() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    try {
      final updated = await context.read<AppState>().regenerateMonthlyReview(_review.periodKey);
      if (updated != null && mounted) {
        setState(() => _review = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이번 달 리포트를 다시 정리했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  void _openEntriesSheet({
    required String title,
    required List<DailyEntry> entries,
  }) {
    if (entries.isEmpty) return;
    final dateFmt = DateFormat('M월 d일 · EEEE', 'ko_KR');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final snippet = entry.note?.trim();
                  return Material(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(ctx);
                        showEntryDaySheet(context, entry);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFmt.format(entry.date),
                                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                          color: AppTheme.inkMuted,
                                        ),
                                  ),
                                  if (entry.moodEmoji != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (entry.moodEmoji != null) entry.moodEmoji!,
                                        if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty)
                                          entry.moodLabel!,
                                      ].join(' '),
                                      style: Theme.of(ctx).textTheme.bodyMedium,
                                    ),
                                  ],
                                  if (snippet != null && snippet.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      snippet,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.inkMuted,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.inkMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digest = _review.digest;
    final stale = context.watch<AppState>().isMonthlyReviewStale(_review.periodKey);
    final monthEntries = _monthEntries(context.watch<AppState>());

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(_review.periodLabel)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (stale) ...[
              _StaleBanner(
                regenerating: _regenerating,
                onRegenerate: _regenerate,
              ),
              const SizedBox(height: 16),
            ],
            if (digest != null) ...[
              _StatsRow(digest: digest),
              const SizedBox(height: 16),
              _PhotoStrip(entries: monthEntries),
              if (digest.moods.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '무드',
                  icon: Icons.spa_outlined,
                  items: digest.moods,
                  tappable: true,
                  onTapItem: (item) => _openEntriesSheet(
                    title: item.label,
                    entries: MonthlyReviewEntryMatcher.entriesForMood(monthEntries, item),
                  ),
                ),
              ],
              if (digest.frequentWords.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '자주 쓴 단어',
                  icon: Icons.text_fields_outlined,
                  items: digest.frequentWords,
                  tappable: true,
                  onTapItem: (item) => _openEntriesSheet(
                    title: '「${item.label}」',
                    entries: MonthlyReviewEntryMatcher.entriesForWord(monthEntries, item),
                  ),
                ),
              ],
              if (digest.places.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '장소',
                  icon: Icons.place_outlined,
                  items: digest.places,
                ),
              ],
              if (digest.people.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '함께한 사람',
                  icon: Icons.favorite_outline,
                  items: digest.people,
                ),
              ],
              if (digest.emotions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FactSection(
                  title: '감정 톤',
                  icon: Icons.waves_outlined,
                  items: digest.emotions,
                ),
              ],
            ] else ...[
              _LegacyBody(review: _review),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.entries});

  final List<DailyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final highlights = <({DailyEntry entry, String uri})>[];
    for (final entry in entries) {
      final uris = EntryPhotos.displayUris(
        localPaths: entry.localPhotoPaths,
        remoteUrls: entry.remotePhotoUrls,
      );
      for (final uri in uris) {
        highlights.add((entry: entry, uri: uri));
        if (highlights.length >= 24) break;
      }
      if (highlights.length >= 24) break;
    }

    if (highlights.isEmpty) return const SizedBox.shrink();

    const height = 108.0;

    return _Section(
      title: '사진',
      icon: Icons.photo_outlined,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: highlights.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = highlights[index];
            final allUris = highlights.map((h) => h.uri).toList();
            return GestureDetector(
              onTap: () => showEntryPhotoViewer(
                context,
                uris: allUris,
                initialIndex: index,
              ),
              onLongPress: () => showEntryDaySheet(context, item.entry),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: height * 0.82,
                  height: height,
                  child: EntryPhoto(url: item.uri, height: height, borderRadius: 10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({
    required this.regenerating,
    required this.onRegenerate,
  });

  final bool regenerating;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 달 기록이 바뀌었어요',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '리포트는 만들 당시 그대로 보관 중이에요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: regenerating ? null : onRegenerate,
            child: regenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('다시 정리하기'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.digest});

  final MonthlyReviewDigest digest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(value: '${digest.recordedDays}', label: '기록한 날', textTheme: textTheme),
          _StatChip(value: '${digest.totalPhotos}', label: '사진', textTheme: textTheme),
          _StatChip(value: '${digest.noteDays}', label: '글 쓴 날', textTheme: textTheme),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.textTheme,
  });

  final String value;
  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: textTheme.titleLarge?.copyWith(color: AppTheme.accent)),
        Text(label, style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted)),
      ],
    );
  }
}

class _FactSection extends StatelessWidget {
  const _FactSection({
    required this.title,
    required this.icon,
    required this.items,
    this.tappable = false,
    this.onTapItem,
  });

  final String title;
  final IconData icon;
  final List<MonthlyFactItem> items;
  final bool tappable;
  final ValueChanged<MonthlyFactItem>? onTapItem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _FactRow(
              item: items[i],
              rank: i + 1,
              textTheme: textTheme,
              tappable: tappable,
              onTap: onTapItem == null ? null : () => onTapItem!(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.item,
    required this.rank,
    required this.textTheme,
    this.tappable = false,
    this.onTap,
  });

  final MonthlyFactItem item;
  final int rank;
  final TextTheme textTheme;
  final bool tappable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bar = (item.count / 10).clamp(0.12, 1.0);

    final row = Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: textTheme.labelMedium?.copyWith(color: AppTheme.inkMuted),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.label, style: textTheme.bodyMedium),
                  ),
                  Text(
                    '${item.count}번',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                  if (tappable) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: AppTheme.inkMuted.withValues(alpha: 0.7)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: bar,
                  minHeight: 5,
                  backgroundColor: AppTheme.paperDark,
                  color: AppTheme.accent.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!tappable || onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}

class _LegacyBody extends StatelessWidget {
  const _LegacyBody({required this.review});

  final MonthlyReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (review.topTopics.isNotEmpty)
          _Section(
            title: '주요 주제',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.topTopics
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppTheme.accent),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
