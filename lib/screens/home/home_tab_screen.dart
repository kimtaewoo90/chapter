import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../feed/feed_screen.dart';
import 'calendar_screen.dart';

enum HomeViewMode { calendar, bookSpread }

/// 메인 탭 — 캘린더(기본) ↔ 크게 보기(나의 책) 전환
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({
    super.key,
    required this.onGoToRecord,
    required this.onGoToRecordForDate,
  });

  final VoidCallback onGoToRecord;
  final void Function(DateTime date) onGoToRecordForDate;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  HomeViewMode _mode = HomeViewMode.calendar;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('home_view_mode');
    if (!mounted) return;
    if (saved == 'book') {
      setState(() => _mode = HomeViewMode.bookSpread);
    }
  }

  Future<void> _setMode(HomeViewMode mode) async {
    setState(() => _mode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'home_view_mode',
      mode == HomeViewMode.bookSpread ? 'book' : 'calendar',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: _ViewModeToggle(
              mode: _mode,
              onChanged: _setMode,
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _mode == HomeViewMode.calendar
                ? CalendarScreen(
                    key: const ValueKey('calendar'),
                    embedded: true,
                    onDateSelected: (date, _) => widget.onGoToRecordForDate(date),
                  )
                : FeedScreen(
                    key: const ValueKey('book'),
                    onGoToRecord: widget.onGoToRecord,
                    showHeader: false,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final HomeViewMode mode;
  final ValueChanged<HomeViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('홈', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              _ModeChip(
                label: '캘린더',
                icon: Icons.calendar_month_outlined,
                selected: mode == HomeViewMode.calendar,
                onTap: () => onChanged(HomeViewMode.calendar),
              ),
              _ModeChip(
                label: '크게 보기',
                icon: Icons.auto_stories_outlined,
                selected: mode == HomeViewMode.bookSpread,
                onTap: () => onChanged(HomeViewMode.bookSpread),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppTheme.accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppTheme.accent : AppTheme.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppTheme.accent : AppTheme.inkMuted,
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
