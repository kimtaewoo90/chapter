import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_route.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../core/layout/shell_insets.dart';
import '../../widgets/paper_background.dart';
import '../book/book_screen.dart';
import '../chapters/chapters_screen.dart';
import 'account_link_screen.dart';
import 'font_settings_screen.dart';
import 'monthly_review_screen.dart';
import 'notification_settings_screen.dart';

/// 더보기 — 계정·설정·탐색
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final moods = state.moodDistribution;
    final total = moods.values.fold<int>(0, (a, b) => a + b);
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('더보기')),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + ShellInsets.bottom(context),
          ),
          children: [
            _StatsCard(
              days: state.totalDays,
              photos: state.totalPhotos,
              texts: state.allEntries.where((e) => e.note != null && e.note!.isNotEmpty).length,
              bookProgress: (state.bookProgress * 100).round(),
              chapterCount: state.allChapters.length,
            ),
            const SizedBox(height: 28),
            _SectionLabel('나의 이야기'),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.auto_stories_outlined,
              title: '완성된 챕터',
              subtitle: state.allChapters.isEmpty
                  ? '아직 열린 챕터가 없어요'
                  : '${state.allChapters.length}개의 이야기',
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'chapters',
                  builder: (_) => ChaptersScreen(onGoToRecord: () => Navigator.pop(context)),
                ),
              ),
            ),
            _MoreTile(
              icon: Icons.menu_book_outlined,
              title: '내 책',
              subtitle: '한 해를 책으로 · ${(state.bookProgress * 100).round()}%',
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'book',
                  builder: (_) => const BookScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('탐색'),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.insights_outlined,
              title: '월간 리포트',
              subtitle: _monthlyReviewSubtitle(state),
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'monthly_review',
                  builder: (_) => const MonthlyReviewScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('계정'),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.cloud_upload_outlined,
              title: '백업 · 다른 기기',
              subtitle: state.linkedProviders.isNotEmpty
                  ? '연결됨 · ${state.linkedProviders.join(', ')}'
                  : state.cloudSyncEnabled
                      ? '연결 · Google로 불러오기'
                      : 'Firebase 로그인 확인 필요',
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'account_link',
                  builder: (_) => const AccountLinkScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('AI'),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Gemini',
              subtitle: state.geminiStatusMessage ?? '키 미설정 · 로컬 규칙만 사용',
              onTap: () async {
                await context.read<AppState>().checkGeminiConnection();
                if (!context.mounted) return;
                context.read<AnalyticsService>().logGeminiCheck(
                      connected: context.read<AppState>().geminiConnected,
                    );
              },
            ),
            const SizedBox(height: 28),
            _SectionLabel('설정'),
            const SizedBox(height: 10),
            _MoreTile(
              icon: Icons.text_fields_outlined,
              title: '글꼴',
              subtitle:
                  '앱 ${appFontOption(state.fontId).label} · 일기 ${appFontOption(state.diaryFontId).label}',
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'font_settings',
                  builder: (_) => const FontSettingsScreen(),
                ),
              ),
            ),
            _MoreTile(
              icon: Icons.notifications_outlined,
              title: '알림',
              subtitle: state.dailyReminderEnabled
                  ? '매일 ${state.dailyReminderTimeLabel}'
                  : '꺼짐',
              onTap: () => Navigator.push(
                context,
                analyticsPageRoute(
                  name: 'notification_settings',
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                state.appBuildLabel.isEmpty ? 'CHAPTER' : 'CHAPTER ${state.appBuildLabel}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.inkMuted.withValues(alpha: 0.55),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 28),
              _SectionLabel('감정 분포'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: moods.entries.map((e) {
                    final pct = (e.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.value / total,
                                minHeight: 8,
                                backgroundColor: AppTheme.paperDark,
                                color: AppTheme.accent.withValues(alpha: 0.6 + (pct / 200)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$pct%', style: textTheme.bodySmall),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accent, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.inkMuted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.days,
    required this.photos,
    required this.texts,
    required this.bookProgress,
    required this.chapterCount,
  });

  final int days;
  final int photos;
  final int texts;
  final int bookProgress;
  final int chapterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${DateTime.now().year} 한눈에', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(context, '$days', '기록한 날'),
              _statItem(context, '$photos', '사진'),
              _statItem(context, '$texts', '글'),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.paperDark.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '책 $bookProgress%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
              ),
              Text(
                '챕터 $chapterCount개',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.accent)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted)),
      ],
    );
  }
}

String _monthlyReviewSubtitle(AppState state) {
  if (state.pendingMonthlyReveal != null) {
    return '새 리포트가 도착했어요';
  }
  final count = state.revealedMonthlyReviews.length;
  if (count > 0) {
    return '지난 리포트 $count개';
  }
  return '말일에 이번 달 이야기가 열려요';
}
