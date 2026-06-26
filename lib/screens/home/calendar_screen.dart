import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/paper_background.dart';
import '../feed/entry_day_sheet.dart';
import '../../widgets/chapter_bottom_bar.dart';

/// 기록한 날 — 사진 썸네일(없으면 무드), 탭하면 보기·수정
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.embedded = false,
    this.onDateSelected,
  });

  final bool embedded;
  final void Function(DateTime date, DailyEntry? entry)? onDateSelected;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();

  void _handleDayTap(DateTime date, DailyEntry? entry) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date, entry);
      return;
    }
    if (entry != null) {
      showEntryDaySheet(
        context,
        entry,
        onEdit: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().allEntries;
    final byDay = <String, DailyEntry>{};
    for (final e in entries) {
      byDay[e.dateKey] = e;
    }

    final first = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final today = DateTime.now();
    final monthLabel = DateFormat('yyyy년 M월', 'ko_KR').format(_focused);
    final daysInMonthWithEntry = List.generate(daysInMonth, (i) {
      final day = i + 1;
      final key =
          '${_focused.year}-${_focused.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      return byDay.containsKey(key);
    }).where((v) => v).length;

    final bottomPad = widget.embedded ? ChapterBottomBar.listBottomPadding(context) : 16.0;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            daysInMonthWithEntry > 0
                ? '이번 달 $daysInMonthWithEntry일 기록 · 탭해서 보거나 쓰기'
                : '날짜를 탭해 첫 기록을 남겨 보세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('일'),
              _WeekdayLabel('월'),
              _WeekdayLabel('화'),
              _WeekdayLabel('수'),
              _WeekdayLabel('목'),
              _WeekdayLabel('금'),
              _WeekdayLabel('토'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.72,
              ),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (context, i) {
                if (i < startWeekday) return const SizedBox.shrink();
                final day = i - startWeekday + 1;
                final date = DateTime(_focused.year, _focused.month, day);
                final key = date.year == _focused.year &&
                        date.month == _focused.month &&
                        date.day == day
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : '';
                final entry = byDay[key];
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
                return _DayCell(
                  day: day,
                  entry: entry,
                  isToday: isToday,
                  isFuture: isFuture,
                  onTap: isFuture
                      ? null
                      : () {
                          if (widget.onDateSelected != null && entry == null) {
                            widget.onDateSelected!(date, null);
                          } else if (widget.onDateSelected != null && entry != null) {
                            showEntryDaySheet(
                              context,
                              entry,
                              onEdit: () {
                                Navigator.pop(context);
                                widget.onDateSelected!(date, entry);
                              },
                            );
                          } else {
                            _handleDayTap(date, entry);
                          }
                        },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.accent.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text('기록', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
              const SizedBox(width: 16),
              const Icon(Icons.photo_outlined, size: 14, color: AppTheme.inkMuted),
              const SizedBox(width: 4),
              Text('사진', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
              const SizedBox(width: 16),
              const Text('😌', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('무드', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
            ],
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return PaperBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonthHeader(
              monthLabel: monthLabel,
              onPrevious: () => setState(
                () => _focused = DateTime(_focused.year, _focused.month - 1),
              ),
              onNext: () => setState(
                () => _focused = DateTime(_focused.year, _focused.month + 1),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(monthLabel),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1)),
            ),
          ],
        ),
        body: body,
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.entry,
    required this.isToday,
    this.isFuture = false,
    this.onTap,
  });

  final int day;
  final DailyEntry? entry;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasEntry = entry != null;
    final uris = hasEntry
        ? EntryPhotos.displayUris(
            localPaths: entry!.localPhotoPaths,
            remoteUrls: entry!.remotePhotoUrls,
          )
        : <String>[];
    final coverUri = uris.isNotEmpty ? uris.first : null;
    final showPhoto = coverUri != null && coverUri.isNotEmpty;
    final mood = entry?.moodEmoji;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: hasEntry
                ? Colors.white.withValues(alpha: 0.88)
                : isFuture
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? AppTheme.accent
                  : hasEntry
                      ? AppTheme.accent.withValues(alpha: 0.35)
                      : AppTheme.paperDark.withValues(alpha: 0.5),
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isFuture
                          ? AppTheme.inkMuted.withValues(alpha: 0.35)
                          : hasEntry
                              ? AppTheme.ink
                              : AppTheme.inkMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: showPhoto
                        ? SizedBox(
                            width: 40,
                            height: 40,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: EntryPhoto(
                                url: coverUri,
                                height: 40,
                                borderRadius: 8,
                              ),
                            ),
                          )
                        : mood != null
                            ? Text(mood, style: const TextStyle(fontSize: 22))
                            : hasEntry
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : isFuture
                                    ? const SizedBox.shrink()
                                    : Icon(
                                        Icons.add,
                                        size: 16,
                                        color: AppTheme.inkMuted.withValues(alpha: 0.45),
                                      ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
