import 'package:flutter/material.dart';

import '../core/constants/moods.dart';
import '../core/theme/app_theme.dart';

/// 온보딩 — 실제 기록 화면과 동일한 레이아웃(정적)
class OnboardingRecordPreview extends StatelessWidget {
  const OnboardingRecordPreview({super.key, this.compact = true});

  /// `false` — App Store 스크린샷 등 풀 높이
  final bool compact;

  static const _aiMoods = [
    MoodOption('☕', '여유'),
    MoodOption('🌧️', '촉촉'),
    MoodOption('😌', '편안'),
  ];

  static const _recentMoods = [
    MoodOption('🙂', '괜찮'),
    MoodOption('🔥', '몰입'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: compact ? const BoxConstraints(maxHeight: 520) : null,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.warmShadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '오늘 기록',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('오늘의 사진', style: textTheme.titleSmall),
                        Text(
                          '겹쳐 보이는 장면을 탭하면 전체를 볼 수 있어요',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 10),
                        const _OnboardingPhotoStack(),
                      ],
                    ),
                  ),
                  const _OnboardingMoodSection(
                    title: '사진으로 추천',
                    showAiIcon: true,
                    moods: _aiMoods,
                    selectedKey: '☕|여유',
                    highlightAi: true,
                  ),
                  const _OnboardingMoodSection(
                    title: '최근 쓴 무드',
                    moods: _recentMoods,
                  ),
                  _OnboardingMoodSection(
                    title: '오늘의 무드',
                    moods: [kDefaultMoods[0], kDefaultMoods[2], kDefaultMoods[7]],
                    showAddMood: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '창가 커피 한 모금, 비 오는 오후…',
                        style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_outlined, size: 18, color: AppTheme.inkMuted.withValues(alpha: 0.85)),
                        const SizedBox(width: 8),
                        Text(
                          '흐림 · 18°C',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '오늘 저장하기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

/// 하위 호환 — 온보딩 4페이지에서 사용
typedef OnboardingDiaryListPreview = OnboardingChaptersPreview;

class _OnboardingPhotoStack extends StatelessWidget {
  const _OnboardingPhotoStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.paperDark),
              ),
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 118,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: const [
                      _PolaroidMock(offset: Offset(-14, 6), rotation: -0.07, color: Color(0xFFE0D5C8)),
                      _PolaroidMock(offset: Offset(10, -4), rotation: 0.05, color: Color(0xFFC8D0DC)),
                      _PolaroidMock(offset: Offset.zero, rotation: 0, color: Color(0xFFD8D8D8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '3장 · 탭해서 보기',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: AppTheme.accent,
              shape: const CircleBorder(),
              elevation: 2,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolaroidMock extends StatelessWidget {
  const _PolaroidMock({
    required this.offset,
    required this.rotation,
    required this.color,
  });

  final Offset offset;
  final double rotation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 72,
          height: 88,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
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

class _OnboardingMoodSection extends StatelessWidget {
  const _OnboardingMoodSection({
    required this.title,
    required this.moods,
    this.showAiIcon = false,
    this.highlightAi = false,
    this.selectedKey,
    this.showAddMood = false,
  });

  final String title;
  final List<MoodOption> moods;
  final bool showAiIcon;
  final bool highlightAi;
  final String? selectedKey;
  final bool showAddMood;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: [
              if (showAiIcon) ...[
                Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(
                  color: showAiIcon ? AppTheme.accent : AppTheme.inkMuted,
                  fontWeight: showAiIcon ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: moods.length + (showAddMood ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (showAddMood && i == moods.length) {
                return Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45), width: 1.2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 22, color: AppTheme.accent),
                      SizedBox(height: 2),
                      Text('내 무드', style: TextStyle(fontSize: 9, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }
              final m = moods[i];
              final selected = m.key == selectedKey;
              return _MoodChipMock(mood: m, isSelected: selected, highlightAi: highlightAi);
            },
          ),
        ),
      ],
    );
  }
}

class _MoodChipMock extends StatelessWidget {
  const _MoodChipMock({
    required this.mood,
    required this.isSelected,
    this.highlightAi = false,
  });

  final MoodOption mood;
  final bool isSelected;
  final bool highlightAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accent.withValues(alpha: 0.2)
            : highlightAi
                ? AppTheme.accent.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.accent
              : highlightAi
                  ? AppTheme.accent.withValues(alpha: 0.35)
                  : AppTheme.paperDark.withValues(alpha: 0.6),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 3),
          Text(
            mood.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.accent : AppTheme.inkMuted,
            ),
          ),
        ],
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
