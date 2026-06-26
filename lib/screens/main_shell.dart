import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/chapter_bottom_bar.dart';
import '../widgets/chapter_reveal_overlay.dart';
import 'chapters/chapter_detail_screen.dart';
import 'home/home_tab_screen.dart';
import 'more/more_screen.dart';
import 'record/record_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// 0 홈(캘린더/크게보기) · 1 기록 · 2 더보기
  int _index = 0;
  DateTime _recordDate = DateTime.now();

  DateTime get _normalizedRecordDate {
    return DateTime(_recordDate.year, _recordDate.month, _recordDate.day);
  }

  void _goToHomeTab() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_index == 0) return;
    setState(() {
      _index = 0;
      _recordDate = DateTime.now();
    });
  }

  void _goToRecordForDate(DateTime date) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _recordDate = DateTime(date.year, date.month, date.day);
      _index = 1;
    });
    context.read<AppState>().refreshTodayWeatherIfNeeded(
          force: context.read<AppState>().isToday(_recordDate),
        );
  }

  void _goToRecordToday() => _goToRecordForDate(DateTime.now());

  void _selectTab(int i) {
    setState(() => _index = i);
    if (i == 0 || i == 1) {
      context.read<AppState>().refreshTodayWeatherIfNeeded();
    }
  }

  void _onViewRevealedChapter() {
    final state = context.read<AppState>();
    final chapter = state.pendingChapterReveal?.chapter;
    state.clearChapterReveal();
    if (chapter != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChapterDetailScreen(chapter: chapter)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshTodayWeatherIfNeeded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reveal = context.watch<AppState>().pendingChapterReveal;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _index,
            children: [
              HomeTabScreen(
                onGoToRecord: _goToRecordToday,
                onGoToRecordForDate: _goToRecordForDate,
              ),
              RecordScreen(
                key: ValueKey(_normalizedRecordDate),
                targetDate: _normalizedRecordDate,
                isActive: _index == 1,
                onSavedSuccessfully: _goToHomeTab,
              ),
              const MoreScreen(),
            ],
          ),
          if (reveal != null)
            Positioned.fill(
              child: ChapterRevealOverlay(
                payload: reveal,
                onDismiss: () => context.read<AppState>().clearChapterReveal(),
                onViewChapter: _onViewRevealedChapter,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Material(
        type: MaterialType.transparency,
        child: ChapterBottomBar(
          currentIndex: _index,
          onSelect: _selectTab,
          onRecord: _goToRecordToday,
          recordSelected: _index == 1,
        ),
      ),
    );
  }
}
