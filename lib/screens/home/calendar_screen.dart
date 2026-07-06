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

  int _pageForMonth(DateTime month) {
    final offset = (month.year - _anchorMonth.year) * 12 + (month.month - _anchorMonth.month);
    return _pageAnchor + offset;
  }

  bool _isViewingCurrentMonth() {
    final now = DateTime.now();
    return _focused.year == now.year && _focused.month == now.month;
  }

  void _goToCurrentMonth() {
    if (!_monthPageController.hasClients || _isViewingCurrentMonth()) return;
    final now = DateTime.now();
    _monthPageController.animateToPage(
      _pageForMonth(DateTime(now.year, now.month)),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
    final showCurrentMonthButton = !_isViewingCurrentMonth();

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthHeader(
            monthLabel: monthLabel,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),
          _CurrentMonthButton(
            visible: showCurrentMonthButton,
            onTap: _goToCurrentMonth,
          ),
          const SizedBox(height: 12),
          Expanded(child: monthPager),
        ],
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
        body: Column(
          children: [
            _CurrentMonthButton(
              visible: showCurrentMonthButton,
              onTap: _goToCurrentMonth,
            ),
            Expanded(child: monthPager),
          ],
        ),
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
    final bottomPad = embedded ? 8.0 : 16.0;
    final topPad = compact ? 8.0 : 8.0;
    final gridGap = compact ? 5.0 : 6.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 0 : 12, topPad, compact ? 0 : 12, bottomPad),
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
          SizedBox(height: compact ? 12 : 8),
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

/// 캘린더 셀 사진 영역 — 일기 사진과 동일한 3:4 세로 비율
const _kCalendarPhotoAspectRatio = 3 / 4;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        const dateRowHeight = 14.0;
        const innerPad = 8.0;
        final cellWidth = (constraints.maxWidth - gap * 6) / 7;
        final photoHeight = cellWidth / _kCalendarPhotoAspectRatio;
        final cellHeight = dateRowHeight + photoHeight + innerPad;
        final naturalGridHeight = cellHeight * rowCount + gap * (rowCount - 1);
        final scale = constraints.maxHeight > 0 && naturalGridHeight > 0
            ? constraints.maxHeight / naturalGridHeight
            : 1.0;
        final rowHeight = cellHeight * scale;

        return Column(
          children: List.generate(rowCount, (row) {
            return SizedBox(
              height: rowHeight,
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
      },
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
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
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

/// 다른 달을 보고 있을 때만 표시 — 탭하면 이번 달로 이동
class _CurrentMonthButton extends StatelessWidget {
  const _CurrentMonthButton({
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: visible
          ? Padding(
              key: const ValueKey('current-month-btn'),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.center,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  elevation: 0,
                  shadowColor: AppTheme.warmShadow,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today_outlined,
                            size: 16,
                            color: AppTheme.accent.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '이번 달',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('current-month-hidden')),
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
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: AspectRatio(
                      aspectRatio: _kCalendarPhotoAspectRatio,
                      child: showPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: EntryPhoto(
                                url: coverUri,
                                height: double.infinity,
                                borderRadius: 6,
                              ),
                            )
                          : Center(
                              child: mood != null
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
