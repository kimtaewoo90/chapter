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

/// CHAPTER 온보딩 — 사진·일기 기록 → 실물 책
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _pageCount = 3;

  final String _weather = '비';
  final String _recordStyle = '사진';
  final String _chronotype = '밤';
  final String _colorTone = '뮤트';
  final List<String> _keywords = const ['기록'];

  @override
  void dispose() {
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
                  },
                  children: [
                    _introPage(textTheme),
                    _recordPage(textTheme),
                    _physicalBookPage(textTheme),
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
        0 => '어떻게 기록하나요?',
        1 => '실물 책은요?',
        _ => '시작하기',
      };

  Widget _introPage(TextTheme textTheme) {
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
            '당신의 하루를,\n한 권의 책으로.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppTheme.ink,
            ),
          ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 20),
          Text(
            '사진과 일기로 가볍게 남기고,\n나중에 손에 쥔 책으로 받아볼 수 있어요.',
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

  Widget _recordPage(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '하루가 한 페이지가 돼요',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '사진을 붙이고, 무드를 찍고 —\n펜만 대면 오늘이 책에 남아요.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
          ),
          const SizedBox(height: 20),
          const OnboardingRecordPreview(framed: false),
        ],
      ),
    );
  }

  Widget _physicalBookPage(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '쌓인 기록을\n실물 책으로 받아보세요',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '인쇄·제본·배송까지.\n집에서 펼쳐 보는 나만의 한 권이에요.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
          ),
          const SizedBox(height: 24),
          OnboardingPhysicalBookPreview(framed: false, active: _page == 2),
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
