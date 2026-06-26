import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_preferences.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/onboarding_book_lottie.dart';
import '../../widgets/onboarding_previews.dart';
import '../../widgets/paper_background.dart';

/// CHAPTER 온보딩 — 말로 설명하지 않고, 책·기억·쌓임으로 락인
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;
  static const _pageCount = 4;

  late final AnimationController _stackController;

  final String _weather = '비';
  final String _recordStyle = '사진';
  final String _chronotype = '밤';
  final String _colorTone = '뮤트';
  final List<String> _keywords = const ['기록'];

  @override
  void initState() {
    super.initState();
    _stackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final p = _pageController.page?.round() ?? 0;
    if (p == 1 && !_stackController.isAnimating && _stackController.value == 0) {
      _stackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _stackController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    context.read<AnalyticsService>().logOnboardingStep(i);
                    if (i == 1) _stackController.forward(from: 0);
                  },
                  children: [
                    _openingPage(textTheme),
                    _stackingPage(textTheme),
                    _recordPreviewPage(textTheme),
                    _diaryListPreviewPage(textTheme),
                  ],
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                count: _pageCount,
                effect: WormEffect(
                  dotHeight: 5,
                  dotWidth: 5,
                  spacing: 6,
                  activeDotColor: AppTheme.accent,
                  dotColor: AppTheme.inkMuted.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(_ctaLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _ctaLabel => switch (_page) {
        0 => '펼쳐보기',
        1 => '다음',
        2 => '다음',
        _ => '시작하기',
      };

  Widget _openingPage(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          SizedBox(
            width: MediaQuery.sizeOf(context).width - 64,
            height: 200,
            child: const OnboardingBookLottie(),
          ),
          const SizedBox(height: 40),
          Text(
            '당신의 이야기를,\n한 권의 책으로.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppTheme.ink,
            ),
          ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 20),
          Text(
            '사진·무드·한 줄 — 가볍게 쌓이면\n조용히 한 권이 완성됩니다.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.65,
              color: AppTheme.inkMuted,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _stackingPage(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            '일기를 쓰다 보면,\n챕터가 됩니다',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppTheme.ink,
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 12),
          Text(
            '어떤 이야기든 괜찮아요.\n쌓이면 내용에 맞춰 챕터로 나뉘고, 한 권이 됩니다.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: AppTheme.inkMuted,
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 500.ms),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _stackController,
            builder: (context, _) => _ChapterFlowVisual(progress: _stackController.value),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _recordPreviewPage(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Text(
            '이렇게 기록해요',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '사진 · 무드 · 한 줄 — AI가 오늘을 풀어줘요',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          const OnboardingRecordPreview(),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _diaryListPreviewPage(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Text(
            '이렇게 챕터가 돼요',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '기록이 모이면 분위기별로 챕터가 만들어집니다',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: const OnboardingChaptersPreview(),
          ),
          const SizedBox(height: 12),
          Text(
            '챕터가 모이면 한 권의 책이 됩니다',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  void _onCta() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final prefs = UserPreferences(
      weather: _weather,
      recordStyle: _recordStyle,
      chronotype: _chronotype,
      colorTone: _colorTone,
      keywords: _keywords,
    );
    context.read<AnalyticsService>().logOnboardingComplete(prefs);
    context.read<AppState>().completeOnboarding(prefs);
  }
}

/// 기록 → 내용에 맞춰 챕터 구분 → 한 권 완성
class _ChapterFlowVisual extends StatelessWidget {
  const _ChapterFlowVisual({required this.progress});

  final double progress;

  static const _steps = [
    ('기록', '어떤 이야기든'),
    ('챕터', '내용에 맞춰'),
    ('한 권', '손에 쥐어'),
  ];

  double _emphasis(int step) {
    final centers = [0.15, 0.5, 0.85];
    final dist = (progress - centers[step]).abs();
    return (1 - dist / 0.38).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FlowStepLabel(
                index: 1,
                title: _steps[0].$1,
                subtitle: _steps[0].$2,
                emphasis: _emphasis(0),
              ),
            ),
            Expanded(child: _FlowConnector(filled: progress > 0.3)),
            Expanded(
              child: _FlowStepLabel(
                index: 2,
                title: _steps[1].$1,
                subtitle: _steps[1].$2,
                emphasis: _emphasis(1),
              ),
            ),
            Expanded(child: _FlowConnector(filled: progress > 0.6)),
            Expanded(
              child: _FlowStepLabel(
                index: 3,
                title: _steps[2].$1,
                subtitle: _steps[2].$2,
                emphasis: _emphasis(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FlowStepPanel(
                  emphasis: _emphasis(0),
                  child: _FlowDiaryTopics(progress: progress),
                ),
              ),
              _FlowArrow(active: progress > 0.28),
              Expanded(
                child: _FlowStepPanel(
                  emphasis: _emphasis(1),
                  child: _FlowNaturalChapters(progress: progress),
                ),
              ),
              _FlowArrow(active: progress > 0.58),
              Expanded(
                child: _FlowStepPanel(
                  emphasis: _emphasis(2),
                  child: _FlowFinishedBook(emphasis: _emphasis(2), progress: progress),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowStepLabel extends StatelessWidget {
  const _FlowStepLabel({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.emphasis,
  });

  final int index;
  final String title;
  final String subtitle;
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    final active = emphasis > 0.45;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : AppTheme.paperDark,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppTheme.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppTheme.ink : AppTheme.inkMuted,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.inkMuted.withValues(alpha: active ? 0.85 : 0.5),
          ),
        ),
      ],
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: filled ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.paperDark,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: active ? AppTheme.accent : AppTheme.paperDark,
      ),
    );
  }
}

class _FlowStepPanel extends StatelessWidget {
  const _FlowStepPanel({required this.emphasis, required this.child});

  final double emphasis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35 + emphasis * 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color.lerp(AppTheme.paperDark, AppTheme.accent, emphasis)!,
          width: 1 + emphasis,
        ),
      ),
      child: child,
    );
  }
}

class _FlowDiaryTopics extends StatelessWidget {
  const _FlowDiaryTopics({required this.progress});

  final double progress;

  static const _topics = [
    ('기록', '📝'),
    ('사진', '📷'),
    ('한줄', '✍️'),
    ('하루', '☕'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < _topics.length; i++)
          Opacity(
            opacity: ((progress * 4) - i * 0.7).clamp(0.0, 1.0),
            child: _topicChip(_topics[i].$1, _topics[i].$2),
          ),
      ],
    );
  }
}

class _FlowNaturalChapters extends StatelessWidget {
  const _FlowNaturalChapters({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final showCh1 = progress > 0.28;
    final showCh2 = progress > 0.48;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _diaryLine('3.12', '☕', opacity: ((progress * 5)).clamp(0.0, 1.0)),
        _diaryLine('3.18', '🌧️', opacity: ((progress * 5) - 0.8).clamp(0.0, 1.0)),
        if (showCh1)
          _chapterDivider('Chapter 01', '봄의 시작', ((progress - 0.28) / 0.2).clamp(0.0, 1.0)),
        _diaryLine('4.02', '🌙', opacity: ((progress * 5) - 1.6).clamp(0.0, 1.0)),
        if (showCh2)
          _chapterDivider('Chapter 02', '여름의 조각', ((progress - 0.48) / 0.2).clamp(0.0, 1.0)),
      ],
    );
  }
}

class _FlowFinishedBook extends StatelessWidget {
  const _FlowFinishedBook({required this.emphasis, required this.progress});

  final double emphasis;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.4 + emphasis * 0.6,
          child: Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [Color(0xFF6E5F52), Color(0xFF9A8268)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warmShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_stories_rounded, color: Colors.white70, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: ((progress - 0.55) / 0.3).clamp(0.0, 1.0),
          child: Text(
            '한 권 완성',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent.withValues(alpha: 0.45 + emphasis * 0.55),
            ),
          ),
        ),
        Text(
          '책장에 꽂는 날',
          style: TextStyle(fontSize: 9, color: AppTheme.inkMuted.withValues(alpha: 0.5 + emphasis * 0.5)),
        ),
      ],
    );
  }
}

Widget _topicChip(String label, String emoji) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 62;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.paperDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            if (!compact) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

Widget _diaryLine(String date, String emoji, {required double opacity}) {
  if (opacity <= 0) return const SizedBox.shrink();
  return Opacity(
    opacity: opacity,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(date, style: const TextStyle(fontSize: 9, color: AppTheme.inkMuted)),
          const SizedBox(width: 6),
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.inkMuted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _chapterDivider(String chapter, String title, double opacity) {
  return Opacity(
    opacity: opacity,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.accent),
                ),
                Text(title, style: const TextStyle(fontSize: 8, color: AppTheme.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
