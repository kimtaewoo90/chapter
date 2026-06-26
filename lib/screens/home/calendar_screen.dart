import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
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
  static const _pageAnchor = 100000;

  late final DateTime _anchorMonth;
  late final PageController _monthPageController;
  DateTime _focused = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorMonth = DateTime(now.year, now.month);
    _focused = _anchorMonth;
    _monthPageController = PageController(initialPage: _pageAnchor);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final offset = page - _pageAnchor;
    return DateTime(_anchorMonth.year, _anchorMonth.month + offset);
  }

  void _goToPreviousMonth() {
    if (!_monthPageController.hasClients) return;
    _monthPageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNextMonth() {
    if (!_monthPageController.hasClients) return;
    _monthPageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

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

    final today = DateTime.now();
    final monthLabel = DateFormat('yyyy년 M월', 'ko_KR').format(_focused);
    final compact = widget.embedded;

    final monthPager = PageView.builder(
      controller: _monthPageController,
      onPageChanged: (page) {
        final month = _monthForPage(page);
        setState(() => _focused = month);
        context.read<AnalyticsService>().logCalendarMonthChange(
              year: month.year,
              month: month.month,
            );
      },
      itemBuilder: (context, page) {
        final month = _monthForPage(page);
        return _CalendarMonthBody(
          focused: month,
          byDay: byDay,
          today: today,
          compact: compact,
          embedded: widget.embedded,
              onDayTap: (date, entry) {
                if (entry != null) {
                  context.read<AnalyticsService>().logDiaryOpen(source: 'calendar');
                }
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
    );

    if (widget.embedded) {
      return PaperBackground(
        child: Padding(
          padding: EdgeInsets.only(bottom: ChapterBottomBar.spreadBottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthHeader(
                monthLabel: monthLabel,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
              ),
              const SizedBox(height: 4),
              Expanded(child: monthPager),
            ],
          ),
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
            onPressed: _goToPreviousMonth,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _goToNextMonth,
            ),
          ],
        ),
        body: monthPager,
      ),
    );
  }
}

class _CalendarMonthBody extends StatelessWidget {
  const _CalendarMonthBody({
    required this.focused,
    required this.byDay,
    required this.today,
    required this.compact,
    required this.embedded,
    required this.onDayTap,
  });

  final DateTime focused;
  final Map<String, DailyEntry> byDay;
  final DateTime today;
  final bool compact;
  final bool embedded;
  final void Function(DateTime date, DailyEntry? entry) onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(focused.year, focused.month, 1);
    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final rowCount = (startWeekday + daysInMonth + 6) ~/ 7;
    final bottomPad = embedded ? 0.0 : 16.0;
    final topPad = compact ? 16.0 : 8.0;
    final gridGap = compact ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 12, topPad, compact ? 8 : 12, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          SizedBox(height: compact ? 10 : 8),
          Expanded(
            child: _CalendarDayGrid(
              rowCount: rowCount,
              startWeekday: startWeekday,
              daysInMonth: daysInMonth,
              focused: focused,
              byDay: byDay,
              today: today,
              gap: gridGap,
              onDayTap: onDayTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayGrid extends StatelessWidget {
  const _CalendarDayGrid({
    required this.rowCount,
    required this.startWeekday,
    required this.daysInMonth,
    required this.focused,
    required this.byDay,
    required this.today,
    required this.gap,
    required this.onDayTap,
  });

  final int rowCount;
  final int startWeekday;
  final int daysInMonth;
  final DateTime focused;
  final Map<String, DailyEntry> byDay;
  final DateTime today;
  final double gap;
  final void Function(DateTime date, DailyEntry? entry) onDayTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rowCount, (row) {
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(7, (col) {
              final i = row * 7 + col;
              Widget cell;
              if (i < startWeekday || i >= startWeekday + daysInMonth) {
                cell = const SizedBox.shrink();
              } else {
                final day = i - startWeekday + 1;
                final date = DateTime(focused.year, focused.month, day);
                final key =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final entry = byDay[key];
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
                cell = _DayCell(
                  day: day,
                  entry: entry,
                  isToday: isToday,
                  isFuture: isFuture,
                  onTap: isFuture ? null : () => onDayTap(date, entry),
                );
              }
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: col < 6 ? gap : 0,
                    bottom: row < rowCount - 1 ? gap : 0,
                  ),
                  child: cell,
                ),
              );
            }),
          ),
        );
      }),
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
