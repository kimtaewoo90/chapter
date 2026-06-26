import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
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
  final _dayFmt = DateFormat('M월 d일 (E)', 'ko_KR');

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
    Navigator.push(
      context,
      MaterialPageRoute(
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
                          '월 단위로 모두 선택하거나, 날짜별로 고를 수 있어요.',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        for (final monthKey in grouped.keys) ...[
                          _MonthSection(
                            title: _monthFmt.format(grouped[monthKey]!.first.date),
                            entries: grouped[monthKey]!,
                            selectedIds: _selectedIds,
                            dayLabel: (d) => _dayFmt.format(d),
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

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.title,
    required this.entries,
    required this.selectedIds,
    required this.dayLabel,
    required this.fullySelected,
    required this.partiallySelected,
    required this.onToggleMonth,
    required this.onToggleDay,
  });

  final String title;
  final List<DailyEntry> entries;
  final Set<String> selectedIds;
  final String Function(DateTime) dayLabel;
  final bool fullySelected;
  final bool partiallySelected;
  final ValueChanged<bool> onToggleMonth;
  final void Function(DailyEntry entry, bool selected) onToggleDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.7)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(
                  '${entries.where((e) => selectedIds.contains(e.id)).length}/${entries.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
            leading: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: fullySelected ? true : (partiallySelected ? null : false),
                tristate: true,
                activeColor: AppTheme.accent,
                onChanged: (v) {
                  if (v == null) {
                    onToggleMonth(false);
                  } else {
                    onToggleMonth(v);
                  }
                },
              ),
            ),
            children: entries.map((entry) {
              final selected = selectedIds.contains(entry.id);
              final preview = EntryDiaryAi.primaryDiaryText(entry);
              return CheckboxListTile(
                value: selected,
                activeColor: AppTheme.accent,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(dayLabel(entry.date)),
                subtitle: Text(
                  [
                    if (entry.moodEmoji != null) entry.moodEmoji!,
                    if (preview != null && preview.isNotEmpty)
                      preview.length > 40 ? '${preview.substring(0, 40)}…' : preview
                    else if (entry.hasPhotos)
                      '사진 ${entry.photoCount}장'
                    else
                      '무드만',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: entry.hasPhotos
                    ? Icon(Icons.photo_outlined, size: 20, color: AppTheme.inkMuted.withValues(alpha: 0.7))
                    : null,
                onChanged: (v) => onToggleDay(entry, v ?? false),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
