import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/analytics/analytics_route.dart';
import '../providers/app_state.dart';
import '../services/analytics_service.dart';
import '../widgets/monthly_review_reveal_overlay.dart';
import '../widgets/paper_background.dart';
import 'home/home_tab_screen.dart';
import 'more/monthly_review_detail_screen.dart';
import 'more/more_screen.dart';
import 'record/record_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void _openRecord(DateTime date) {
    FocusManager.instance.primaryFocus?.unfocus();
    final day = DateTime(date.year, date.month, date.day);
    final appState = context.read<AppState>();
    context.read<AnalyticsService>().logTabSelect('record');
    appState.refreshTodayWeatherIfNeeded(force: appState.isToday(day));

    Navigator.of(context).push(
      analyticsPageRoute(
        name: 'record',
        builder: (ctx) => RecordScreen(
          targetDate: day,
          isActive: true,
          onSavedSuccessfully: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _openMore() {
    context.read<AnalyticsService>().logTabSelect('more');
    context.read<AnalyticsService>().logScreenView(screenName: 'more');
    Navigator.of(context).push(
      analyticsPageRoute(
        name: 'more',
        builder: (_) => const MoreScreen(),
      ),
    );
  }

  void _onViewRevealedMonthlyReview() async {
    final state = context.read<AppState>();
    final review = state.pendingMonthlyReveal;
    if (review == null) return;
    await state.dismissMonthlyReveal();
    if (!mounted) return;
    Navigator.of(context).push(
      analyticsPageRoute(
        name: 'monthly_review_detail',
        builder: (_) => MonthlyReviewDetailScreen(review: review),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshTodayWeatherIfNeeded();
        context.read<AnalyticsService>().logTabSelect('home');
        context.read<AnalyticsService>().logScreenView(screenName: 'home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthlyReveal = state.pendingMonthlyReveal;

    return Scaffold(
      backgroundColor: PaperBackground.surfaceBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HomeTabScreen(
            onGoToRecord: () => _openRecord(DateTime.now()),
            onGoToRecordForDate: _openRecord,
            onOpenMore: _openMore,
          ),
          if (monthlyReveal != null)
            Positioned.fill(
              child: MonthlyReviewRevealOverlay(
                review: monthlyReveal,
                onDismiss: () => context.read<AppState>().dismissMonthlyReveal(),
                onViewReview: _onViewRevealedMonthlyReview,
              ),
            ),
        ],
      ),
    );
  }
}
