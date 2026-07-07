import 'package:flutter/material.dart';

import 'package:chapter/core/constants/app_fonts.dart';
import 'package:chapter/core/theme/app_theme.dart';
import 'package:chapter/widgets/onboarding_previews.dart';
import 'package:chapter/widgets/paper_background.dart';

import 'shell.dart';

class StoreScreenshotScene {
  const StoreScreenshotScene({
    required this.fileName,
    required this.widget,
  });

  final String fileName;
  final Widget widget;
}

class StoreScreenshotScenes {
  static List<StoreScreenshotScene> get all => [
        StoreScreenshotScene(
          fileName: '01_hero.png',
          widget: const StoreScreenshotFrame(
            headline: '당신의 이야기를,\n한 권의 챕터로',
            subheadline: '사진·무드·한 줄 — 가볍게 쌓이면\n조용히 한 권이 완성됩니다',
            body: _FeedScreenBody(),
          ),
        ),
        StoreScreenshotScene(
          fileName: '02_record.png',
          widget: const StoreScreenshotFrame(
            headline: '하루 한 페이지',
            subheadline: '사진, 무드, 날씨까지\n오늘을 한 장면으로 남겨요',
            body: _RecordScreenBody(),
          ),
        ),
        StoreScreenshotScene(
          fileName: '03_journal.png',
          widget: const StoreScreenshotFrame(
            headline: '책장을 넘기듯',
            subheadline: '기록한 하루가\n종이 페이지가 됩니다',
            body: _FeedScreenBody(focusPage: true),
          ),
        ),
        StoreScreenshotScene(
          fileName: '04_chapter.png',
          widget: const StoreScreenshotFrame(
            headline: '한 달을 돌아보며',
            subheadline: '월간 리포트로\n무드·장소·단어를 정리해요',
            dark: true,
            body: _InsightScreenBody(),
          ),
        ),
        StoreScreenshotScene(
          fileName: '05_book.png',
          widget: const StoreScreenshotFrame(
            headline: '한 해, 한 권',
            subheadline: '진행률 · PDF · 완성된 챕터\n올해의 이야기를 책으로',
            body: _BookScreenBody(),
          ),
        ),
        StoreScreenshotScene(
          fileName: '06_insight.png',
          widget: const StoreScreenshotFrame(
            headline: '돌아보는 인사이트',
            subheadline: '월간 리포트 · 캘린더 · 무드 통계\n기록이 쌓일수록 선명해져요',
            body: _InsightScreenBody(),
          ),
        ),
      ];
}

class _FeedScreenBody extends StatelessWidget {
  const _FeedScreenBody({this.focusPage = false});

  final bool focusPage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PaperBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('나의 책', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '옆으로 넘기며 읽어요',
                        style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '3 / 12',
                  style: textTheme.labelMedium?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!focusPage) const SizedBox(height: 12),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: focusPage ? 12 : 24),
              child: _JournalPageCard(emphasized: focusPage),
            ),
          ),
          if (!focusPage)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
              child: Text(
                '← 옆으로 넘겨 이전 날을 읽어요',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }
}

class _JournalPageCard extends StatelessWidget {
  const _JournalPageCard({this.emphasized = false});

  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final handwriting = diaryFontStyle(kDefaultDiaryFontId, fontSize: emphasized ? 30 : 26, height: 1.55);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.16),
            blurRadius: emphasized ? 32 : 22,
            offset: Offset(emphasized ? 6 : 4, emphasized ? 12 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _LinedPaperPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2026년 3월 15일 · 토요일',
                        style: textTheme.labelMedium?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ),
                    const Text('☕', style: TextStyle(fontSize: 28)),
                  ],
                ),
                Text('여유', style: handwriting.copyWith(fontSize: 20, color: AppTheme.accent)),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4CCC0),
                            AppTheme.accentLight.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_cafe_rounded,
                          size: emphasized ? 88 : 72,
                          color: AppTheme.ink.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '창가 커피 한 모금, 비 오는 오후의\n느린 호흡.',
                  style: handwriting,
                ),
                const SizedBox(height: 8),
                Text(
                  '흐림 · 18°C',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '3 / 12',
                    style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted.withValues(alpha: 0.65)),
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

class _RecordScreenBody extends StatelessWidget {
  const _RecordScreenBody();

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: OnboardingRecordPreview(compact: false),
      ),
    );
  }
}

class _BookScreenBody extends StatelessWidget {
  const _BookScreenBody();

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Text(
            '내 책',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '2026 · 한 해를 책으로',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 28),
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF5C5048), Color(0xFF8B7355), Color(0xFF4A3F36)],
              ),
              boxShadow: const [
                BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: Offset(8, 14)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHAPTER',
                        style: appFontStyle(
                          kDefaultFontId,
                          fontSize: 32,
                          color: Colors.white.withValues(alpha: 0.92),
                        ).copyWith(letterSpacing: 10),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '2026',
                        style: appFontStyle(
                          kDefaultFontId,
                          fontSize: 22,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '올해 진행률 68%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.accent),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.68,
                minHeight: 10,
                backgroundColor: AppTheme.paperDark,
                color: AppTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const OnboardingChaptersPreview(),
        ],
      ),
    );
  }
}

class _InsightScreenBody extends StatelessWidget {
  const _InsightScreenBody();

  static const _marked = {3, 5, 8, 12, 15, 18, 22, 24, 27};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PaperBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '2026년 3월',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '이번 달 9일 기록',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Weekday('일'),
                _Weekday('월'),
                _Weekday('화'),
                _Weekday('수'),
                _Weekday('목'),
                _Weekday('금'),
                _Weekday('토'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemCount: 35,
                itemBuilder: (context, i) {
                  if (i < 6) return const SizedBox.shrink();
                  final day = i - 5;
                  if (day > 31) return const SizedBox.shrink();
                  final marked = _marked.contains(day);
                  final isToday = day == 15;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: marked
                          ? AppTheme.accent.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.5),
                      border: isToday ? Border.all(color: AppTheme.accent, width: 2) : null,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        if (marked)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFD8D0C4),
                                      AppTheme.accentLight.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    day.isEven ? '🙂' : '☕',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights_outlined, size: 22, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text('월간 리포트', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Story Arc 4개 · ☕ 여유 38% · ☀️ 활기 24%',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.inkMuted,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  static const _paper = Color(0xFFFAF6EE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);

    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var y = 56.0; y < size.height - 24; y += 28) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 12, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0xFFE8B4B4).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
