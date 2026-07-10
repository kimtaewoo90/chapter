import 'package:flutter/material.dart';

import '../core/constants/app_fonts.dart';
import '../core/constants/book_cover_type.dart';
import '../core/constants/dev_flags.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/theme/app_theme.dart';
import 'book_cover_artwork.dart';

/// 온보딩 — 책 한 페이지에 사진·무드·글을 붙이는 쇼케이스
class OnboardingRecordPreview extends StatefulWidget {
  const OnboardingRecordPreview({
    super.key,
    this.compact = true,
    this.framed = true,
  });

  final bool compact;
  final bool framed;

  @override
  State<OnboardingRecordPreview> createState() => _OnboardingRecordPreviewState();
}

class _OnboardingRecordPreviewState extends State<OnboardingRecordPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _lines = [
    '창가 커피 한 모금.',
    '오랜만에 친구랑 수다 떨었다.',
    '카페 음악이 잔잔하게 흘렀다.',
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double start, double end) {
    final t = _c.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  Widget _buildShowcasePage({
    required double pageHeight,
    required TextStyle handwriting,
    required double photosIn,
    required double moodIn,
    required List<double> lineOpacities,
    required double chipsIn,
    required TextTheme textTheme,
    bool usePdfFrame = false,
  }) {
    final page = Container(
      height: usePdfFrame ? null : pageHeight,
      constraints: usePdfFrame
          ? const BoxConstraints.expand()
          : null,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x302C2824),
            blurRadius: 28,
            offset: Offset(6, 14),
          ),
          BoxShadow(
            color: Color(0x142C2824),
            blurRadius: 8,
            offset: Offset(1, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ShowcasePaperPainter()),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.ink.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3월 8일 · 토요일',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppTheme.inkMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '오늘의 한 페이지',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: moodIn,
                        child: Opacity(
                          opacity: moodIn,
                          child: Transform.rotate(
                            angle: 0.08,
                            child: _MoodStamp(
                              emoji: '☕',
                              label: '여유',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.88 + photosIn * 0.12,
                          child: Opacity(
                            opacity: photosIn.clamp(0.0, 1.0),
                            child: const _ShowcasePolaroidCluster(),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: Opacity(
                            opacity: moodIn,
                            child: Transform.translate(
                              offset: Offset((1 - moodIn) * 12, 0),
                              child: _AiMoodTag(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(_lines.length, (i) {
                    return Opacity(
                      opacity: lineOpacities[i],
                      child: Transform.translate(
                        offset: Offset(0, (1 - lineOpacities[i]) * 10),
                        child: Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                          child: Text(
                            _lines[i],
                            style: handwriting,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: chipsIn,
                      child: Text(
                        'p. 24',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.inkMuted.withValues(alpha: 0.65),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!usePdfFrame) return page;

    return AspectRatio(
      aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
      child: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageHeight = widget.framed
        ? (kOnboardingUsesBookPagePreview ? null : 360.0)
        : (kOnboardingUsesBookPagePreview ? null : 400.0);
    final handwriting = diaryFontStyle(kDefaultDiaryFontId, fontSize: 18, height: 1.55);

    final body = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pageIn = Curves.easeOutCubic.transform(_interval(0, 0.28));
        final photosIn = Curves.easeOutBack.transform(_interval(0.12, 0.42));
        final moodIn = Curves.easeOutCubic.transform(_interval(0.32, 0.52));
        final line1 = Curves.easeOut.transform(_interval(0.44, 0.58));
        final line2 = Curves.easeOut.transform(_interval(0.52, 0.66));
        final line3 = Curves.easeOut.transform(_interval(0.60, 0.74));
        final chipsIn = Curves.easeOut.transform(_interval(0.72, 0.9));
        final lineOpacities = [line1, line2, line3];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, (1 - pageIn) * 28),
              child: Opacity(
                opacity: pageIn,
                child: Transform.rotate(
                  angle: -0.012,
                  child: _buildShowcasePage(
                    pageHeight: pageHeight ?? 360,
                    handwriting: handwriting,
                    photosIn: photosIn,
                    moodIn: moodIn,
                    lineOpacities: lineOpacities,
                    chipsIn: chipsIn,
                    textTheme: textTheme,
                    usePdfFrame: kOnboardingUsesBookPagePreview,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: chipsIn,
              child: Transform.translate(
                offset: Offset(0, (1 - chipsIn) * 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FlowChip(emoji: '📷', label: '사진 붙이기'),
                    SizedBox(width: 8),
                    _FlowChip(emoji: '☕', label: '무드 찍기'),
                    SizedBox(width: 8),
                    _FlowChip(emoji: '✍️', label: '일기 쓰기'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!widget.framed) return body;

    return Container(
      constraints: widget.compact ? const BoxConstraints(maxHeight: 520) : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class _ShowcasePolaroidCluster extends StatelessWidget {
  const _ShowcasePolaroidCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      width: 240,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: const [
          _PolaroidMock(
            offset: Offset(-38, 10),
            rotation: -0.14,
            color: Color(0xFFD4C4B0),
            width: 88,
            height: 108,
          ),
          _PolaroidMock(
            offset: Offset(36, 6),
            rotation: 0.11,
            color: Color(0xFFB8C4D4),
            width: 84,
            height: 104,
          ),
          _PolaroidMock(
            offset: Offset.zero,
            rotation: -0.02,
            color: Color(0xFFC9B8A8),
            width: 96,
            height: 118,
          ),
        ],
      ),
    );
  }
}

class _MoodStamp extends StatelessWidget {
  const _MoodStamp({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMoodTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentLight),
          SizedBox(width: 5),
          Text(
            '사진이 말해요 → ☕',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.paperDark),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcasePaperPainter extends CustomPainter {
  static const _paper = Color(0xFFFAF6EE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);

    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const lineGap = 28.0;
    for (var y = 72.0; y < size.height - 20; y += lineGap) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 12, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0xFFE8B4B4).withValues(alpha: 0.38)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 온보딩 — 피드(나의 책) 미리보기(정적)
class OnboardingChaptersPreview extends StatelessWidget {
  const OnboardingChaptersPreview({super.key});

  static const _pages = [
    ('3월 15일', '☕ 여유', '카페 창가, 오후 햇살'),
    ('3월 14일', '🌿 산책', '동네 공원 한 바퀴'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Center(
            child: Text('나의 책', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ),
        ...List.generate(_pages.length, (i) {
          final p = _pages[i];
          return Padding(
            padding: EdgeInsets.fromLTRB(16, i == 0 ? 0 : 0, 16, i == _pages.length - 1 ? 0 : 12),
            child: _JournalPageMock(
              dateLabel: p.$1,
              mood: p.$2,
              snippet: p.$3,
            ),
          );
        }),
      ],
    );
  }
}

/// 하위 호환 — 스토어 스크린샷 등
typedef OnboardingDiaryListPreview = OnboardingChaptersPreview;

/// 온보딩 — 실물 책 주문 쇼케이스 (애니메이션)
class OnboardingPhysicalBookPreview extends StatefulWidget {
  const OnboardingPhysicalBookPreview({
    super.key,
    this.framed = true,
    this.active = true,
  });

  final bool framed;
  /// 온보딩에서 이 페이지가 보일 때 애니메이션 재생
  final bool active;

  @override
  State<OnboardingPhysicalBookPreview> createState() => _OnboardingPhysicalBookPreviewState();
}

class _OnboardingPhysicalBookPreviewState extends State<OnboardingPhysicalBookPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _steps = [
    (Icons.edit_note_outlined, '기록 모음'),
    (Icons.picture_as_pdf_outlined, '책 미리보기'),
    (Icons.local_shipping_outlined, '집까지 배송'),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(OnboardingPhysicalBookPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double start, double end) {
    final t = _c.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _clampOpacity(double value) => value.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final year = DateTime.now().year;
    final coverHeight = widget.framed ? 200.0 : 240.0;

    final body = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final stackIn = Curves.easeOutCubic.transform(_interval(0, 0.22));
        final bookInRaw = Curves.easeOutBack.transform(_interval(0.16, 0.46));
        final bookIn = _clampOpacity(bookInRaw);
        final bookGlow = Curves.easeInOut.transform(_interval(0.44, 0.58));
        final step1 = _clampOpacity(Curves.easeOutBack.transform(_interval(0.38, 0.54)));
        final step2 = _clampOpacity(Curves.easeOutBack.transform(_interval(0.48, 0.64)));
        final step3 = _clampOpacity(Curves.easeOutBack.transform(_interval(0.58, 0.74)));
        final line1 = Curves.easeOut.transform(_interval(0.46, 0.58));
        final line2 = Curves.easeOut.transform(_interval(0.56, 0.68));
        final captionIn = _clampOpacity(Curves.easeOut.transform(_interval(0.68, 0.84)));
        final cardIn = _clampOpacity(Curves.easeOutCubic.transform(_interval(0.74, 0.92)));
        final chipsIn = _clampOpacity(Curves.easeOut.transform(_interval(0.82, 0.98)));
        final stepValues = [step1, step2, step3];
        final lineValues = [line1, line2];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: widget.framed ? 20 : 4),
            SizedBox(
              height: coverHeight + 36,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      bottom: 12 + i * 5.0,
                      child: Opacity(
                        opacity: _clampOpacity(stackIn * (1 - bookIn * 0.85)),
                        child: Transform.translate(
                          offset: Offset((i - 1) * 14 * (1 - stackIn), (1 - stackIn) * 24),
                          child: Transform.rotate(
                            angle: (i - 1) * 0.06,
                            child: _ThinPageLayer(width: coverHeight * 0.72),
                          ),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, (1 - bookInRaw.clamp(0.0, 1.0)) * 40),
                    child: Transform.scale(
                      scale: 0.78 + bookInRaw.clamp(0.0, 1.0) * 0.22,
                      child: Opacity(
                        opacity: bookIn,
                        child: _OnboardingCoverPreview(
                          year: year,
                          height: coverHeight,
                          glow: bookGlow,
                        ),
                      ),
                    ),
                  ),
                  if (bookIn > 0.5)
                    Positioned(
                      top: 0,
                      child: Opacity(
                        opacity: _clampOpacity((bookIn - 0.5) * 2 * bookGlow),
                        child: const _DeliverySparkle(),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: widget.framed ? 20 : 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.only(bottom: 28),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: constraints.maxWidth * lineValues[i - 1],
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Opacity(
                        opacity: stepValues[i],
                        child: Transform.scale(
                          scale: 0.7 + stepValues[i] * 0.3,
                          child: _DeliveryStep(
                            icon: _steps[i].$1,
                            label: _steps[i].$2,
                            highlighted: i == 2 && step3 > 0.85,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: captionIn,
              child: Transform.translate(
                offset: Offset(0, (1 - captionIn) * 12),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, widget.framed ? 20 : 8),
                  child: Text(
                    '한 달치 기록이 쌓이면 주문할 수 있어요.\n날짜순으로 정리된 나만의 책이 도착합니다.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.5),
                  ),
                ),
              ),
            ),
            if (!widget.framed) ...[
              Opacity(
                opacity: cardIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - cardIn) * 16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.paperDark),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.08 * cardIn),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CHAPTER',
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 4,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('실물 책 주문', style: textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '미리보기 확인 → 입금 → 제작·배송',
                            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: chipsIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - chipsIn) * 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FlowChip(emoji: '📅', label: '기록 쌓기'),
                      SizedBox(width: 8),
                      _FlowChip(emoji: '📖', label: '미리보기'),
                      SizedBox(width: 8),
                      _FlowChip(emoji: '📦', label: '집까지 배송'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );

    if (!widget.framed) return body;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class _ThinPageLayer extends StatelessWidget {
  const _ThinPageLayer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.62,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: CustomPaint(painter: _ShowcasePaperPainter()),
    );
  }
}

class _DeliverySparkle extends StatelessWidget {
  const _DeliverySparkle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Text(
          '나만의 한 권이 완성돼요',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _OnboardingCoverPreview extends StatelessWidget {
  const _OnboardingCoverPreview({
    required this.year,
    required this.height,
    this.glow = 0,
  });

  final int year;
  final double height;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: Offset(8, 14)),
          if (glow > 0)
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.22 * glow),
              blurRadius: 28,
              spreadRadius: 2 * glow,
            ),
        ],
      ),
      child: SizedBox(
        width: height * 0.75,
        height: height,
        child: BookCoverArtwork(
          coverType: BookCoverType.chapterIcon,
          dateRangeLabel: '',
          coverYear: year,
        ),
      ),
    );
  }
}

class _DeliveryStep extends StatelessWidget {
  const _DeliveryStep({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: highlighted
                ? AppTheme.accent.withValues(alpha: 0.18)
                : AppTheme.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: highlighted ? Border.all(color: AppTheme.accent.withValues(alpha: 0.45)) : null,
          ),
          child: Icon(icon, size: 22, color: AppTheme.accent),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
        ),
      ],
    );
  }
}

class _PolaroidMock extends StatelessWidget {
  const _PolaroidMock({
    required this.offset,
    required this.rotation,
    required this.color,
    this.width = 72,
    this.height = 88,
  });

  final Offset offset;
  final double rotation;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.fromLTRB(width * 0.08, width * 0.08, width * 0.08, height * 0.16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalPageMock extends StatelessWidget {
  const _JournalPageMock({
    required this.dateLabel,
    required this.mood,
    required this.snippet,
  });

  final String dateLabel;
  final String mood;
  final String snippet;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
            const SizedBox(height: 6),
            Text(mood, style: textTheme.titleSmall?.copyWith(color: AppTheme.accent)),
            const SizedBox(height: 6),
            Text(
              snippet,
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
