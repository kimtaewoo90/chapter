import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/paper_background.dart';
import 'book_order_screen.dart';

/// 책에 넣을 일기 — 월별 묶음 · 일별 선택
class BookEntrySelectScreen extends StatefulWidget {
  const BookEntrySelectScreen({super.key});

  @override
  State<BookEntrySelectScreen> createState() => _BookEntrySelectScreenState();
}

class _BookEntrySelectScreenState extends State<BookEntrySelectScreen> {
  final Set<String> _selectedIds = {};
  final _monthFmt = DateFormat('yyyy년 M월', 'ko_KR');
  final _weekdayFmt = DateFormat('E', 'ko_KR');

  Map<String, List<DailyEntry>> _groupByMonth(List<DailyEntry> entries) {
    final map = <String, List<DailyEntry>>{};
    for (final e in entries) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: map[k]!};
  }

  void _toggleMonth(List<DailyEntry> monthEntries, bool select) {
    setState(() {
      for (final e in monthEntries) {
        if (select) {
          _selectedIds.add(e.id);
        } else {
          _selectedIds.remove(e.id);
        }
      }
    });
  }

  bool _isMonthFullySelected(List<DailyEntry> monthEntries) =>
      monthEntries.every((e) => _selectedIds.contains(e.id));

  bool _isMonthPartiallySelected(List<DailyEntry> monthEntries) =>
      monthEntries.any((e) => _selectedIds.contains(e.id)) && !_isMonthFullySelected(monthEntries);

  void _proceed(List<DailyEntry> allEntries) {
    final selected = allEntries.where((e) => _selectedIds.contains(e.id)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('한 개 이상의 일기를 선택해 주세요.')),
      );
      return;
    }
    context.read<AnalyticsService>().logBookOrderStart(entryCount: selected.length);
    Navigator.push(
      context,
      analyticsPageRoute(
        name: 'book_order',
        builder: (_) => BookOrderScreen(selectedEntries: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().allEntries;
    final grouped = _groupByMonth(entries);
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('일기 선택'),
          actions: [
            if (_selectedIds.isNotEmpty)
              TextButton(
                onPressed: () => setState(_selectedIds.clear),
                child: Text('전체 해제', style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.9))),
              ),
          ],
        ),
        body: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '아직 기록이 없어요.\n일기를 쓴 뒤 책에 담을 수 있어요.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted, height: 1.5),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '책에 넣을 하루를 골라 주세요',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '월을 눌러 날짜별로 고르거나, 체크로 한 달 전체를 선택할 수 있어요.',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        for (final monthKey in grouped.keys)
                          _MonthSection(
                            title: _monthFmt.format(grouped[monthKey]!.first.date),
                            entries: grouped[monthKey]!,
                            selectedIds: _selectedIds,
                            weekdayLabel: (d) => _weekdayFmt.format(d),
                            fullySelected: _isMonthFullySelected(grouped[monthKey]!),
                            partiallySelected: _isMonthPartiallySelected(grouped[monthKey]!),
                            onToggleMonth: (select) => _toggleMonth(grouped[monthKey]!, select),
                            onToggleDay: (entry, selected) {
                              setState(() {
                                if (selected) {
                                  _selectedIds.add(entry.id);
                                } else {
                                  _selectedIds.remove(entry.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: entries.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton(
                    onPressed: () => _proceed(entries),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? '다음 — 일기를 선택해 주세요'
                          : '다음 (${_selectedIds.length}일 선택)',
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _MonthSection extends StatefulWidget {
  const _MonthSection({
    required this.title,
    required this.entries,
    required this.selectedIds,
    required this.weekdayLabel,
    required this.fullySelected,
    required this.partiallySelected,
    required this.onToggleMonth,
    required this.onToggleDay,
  });

  final String title;
  final List<DailyEntry> entries;
  final Set<String> selectedIds;
  final String Function(DateTime) weekdayLabel;
  final bool fullySelected;
  final bool partiallySelected;
  final ValueChanged<bool> onToggleMonth;
  final void Function(DailyEntry entry, bool selected) onToggleDay;

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  bool _expanded = false;

  int get _selectedCount => widget.entries.where((e) => widget.selectedIds.contains(e.id)).length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.65),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppTheme.paperDark.withValues(alpha: 0.7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Checkbox(
                        value: widget.fullySelected ? true : (widget.partiallySelected ? null : false),
                        tristate: true,
                        activeColor: AppTheme.accent,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) {
                          if (v == null) {
                            widget.onToggleMonth(false);
                          } else {
                            widget.onToggleMonth(v);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? '날짜를 골라 주세요'
                                : '${widget.entries.length}일 · 탭해서 펼치기',
                            style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedCount > 0
                            ? AppTheme.accent.withValues(alpha: 0.12)
                            : AppTheme.paperDark.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_selectedCount/${widget.entries.length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: _selectedCount > 0 ? AppTheme.accent : AppTheme.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.inkMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(
                    height: 1,
                    color: AppTheme.paperDark.withValues(alpha: 0.6),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.entries.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _DayEntryCard(
                            entry: widget.entries[i],
                            selected: widget.selectedIds.contains(widget.entries[i].id),
                            weekdayLabel: widget.weekdayLabel(widget.entries[i].date),
                            onToggle: (selected) => widget.onToggleDay(widget.entries[i], selected),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayEntryCard extends StatelessWidget {
  const _DayEntryCard({
    required this.entry,
    required this.selected,
    required this.weekdayLabel,
    required this.onToggle,
  });

  final DailyEntry entry;
  final bool selected;
  final String weekdayLabel;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preview = EntryDiaryAi.primaryDiaryText(entry);
    final photoUri = _firstPhotoUri(entry);

    return Material(
      color: selected ? AppTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.55),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppTheme.accent.withValues(alpha: 0.45) : AppTheme.paperDark.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onToggle(!selected),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(
                day: entry.date.day,
                weekday: weekdayLabel,
                selected: selected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (entry.moodEmoji != null) ...[
                          Text(entry.moodEmoji!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            entry.moodLabel ?? (entry.moodEmoji != null ? '오늘의 무드' : '기록'),
                            style: textTheme.labelMedium?.copyWith(
                              color: selected ? AppTheme.accent : AppTheme.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(preview),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.inkMuted,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (photoUri != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: photoUri.startsWith('http')
                        ? EntryPhoto(url: photoUri, height: 52, borderRadius: 8)
                        : EntryPhoto(file: File(photoUri), height: 52, borderRadius: 8),
                  ),
                )
              else if (entry.hasPhotos)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.paperDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_outlined, size: 22, color: AppTheme.inkMuted.withValues(alpha: 0.7)),
                ),
              const SizedBox(width: 6),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppTheme.accent : AppTheme.paperDark,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _firstPhotoUri(DailyEntry entry) {
    final uris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
    return uris.isEmpty ? null : uris.first;
  }

  String _subtitle(String? preview) {
    if (preview != null && preview.isNotEmpty) {
      return preview.length > 60 ? '${preview.substring(0, 60)}…' : preview;
    }
    if (entry.hasPhotos) return '사진 ${entry.photoCount}장';
    return '무드만 기록됨';
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.day,
    required this.weekday,
    required this.selected,
  });

  final int day;
  final String weekday;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.paper.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$day',
            style: textTheme.titleMedium?.copyWith(
              height: 1,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.accent : AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekday,
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.inkMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
