import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/moods.dart';
import '../core/theme/app_theme.dart';
import '../services/mood_profile_service.dart';
import 'paper_background.dart';

/// 기록 화면 — 무드 선택 바텀시트
Future<void> showMoodSelectSheet(
  BuildContext context, {
  required List<MoodOption> moods,
  List<MoodOption> recentMoods = const [],
  List<MoodOption> aiSuggestedMoods = const [],
  bool loadingAiSuggestions = false,
  required String? selectedEmoji,
  required String? selectedLabel,
  required ValueChanged<MoodOption> onSelected,
  required Future<void> Function(MoodOption mood) onAddCustom,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => _MoodSelectSheetBody(
          scrollController: scrollController,
          moods: moods,
          recentMoods: recentMoods,
          aiSuggestedMoods: aiSuggestedMoods,
          loadingAiSuggestions: loadingAiSuggestions,
          selectedEmoji: selectedEmoji,
          selectedLabel: selectedLabel,
          onSelected: (m) {
            onSelected(m);
            Navigator.pop(ctx);
          },
          onAddCustom: onAddCustom,
        ),
      ),
    ),
  );
}

class _MoodSelectSheetBody extends StatelessWidget {
  const _MoodSelectSheetBody({
    required this.scrollController,
    required this.moods,
    required this.recentMoods,
    required this.aiSuggestedMoods,
    required this.loadingAiSuggestions,
    required this.selectedEmoji,
    required this.selectedLabel,
    required this.onSelected,
    required this.onAddCustom,
  });

  final ScrollController scrollController;
  final List<MoodOption> moods;
  final List<MoodOption> recentMoods;
  final List<MoodOption> aiSuggestedMoods;
  final bool loadingAiSuggestions;
  final String? selectedEmoji;
  final String? selectedLabel;
  final ValueChanged<MoodOption> onSelected;
  final Future<void> Function(MoodOption mood) onAddCustom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '오늘의 무드',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (selectedEmoji != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '$selectedEmoji ${selectedLabel ?? ''}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                MoodSelector(
                  moods: moods,
                  recentMoods: recentMoods,
                  aiSuggestedMoods: aiSuggestedMoods,
                  loadingAiSuggestions: loadingAiSuggestions,
                  selectedEmoji: selectedEmoji,
                  selectedLabel: selectedLabel,
                  onSelected: onSelected,
                  onAddCustom: onAddCustom,
                  bookPage: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.moods,
    this.recentMoods = const [],
    this.aiSuggestedMoods = const [],
    this.loadingAiSuggestions = false,
    required this.selectedEmoji,
    required this.selectedLabel,
    required this.onSelected,
    required this.onAddCustom,
    this.bookPage = false,
  });

  final List<MoodOption> moods;
  final List<MoodOption> recentMoods;
  final List<MoodOption> aiSuggestedMoods;
  final bool loadingAiSuggestions;
  final String? selectedEmoji;
  final String? selectedLabel;
  final ValueChanged<MoodOption> onSelected;
  final Future<void> Function(MoodOption mood) onAddCustom;
  final bool bookPage;

  String? get _selectedKey => selectedEmoji == null
      ? null
      : '$selectedEmoji|${selectedLabel ?? MoodProfileService.labelForEmoji(selectedEmoji!)}';

  @override
  Widget build(BuildContext context) {
    final recent = recentMoods;
    final recentKeys = recent.map((m) => m.key).toSet();
    final rest = moods.where((m) => !recentKeys.contains(m.key)).toList();
    final hasRecent = recent.isNotEmpty;
    final hPad = bookPage ? 0.0 : 20.0;
    final sectionGap = bookPage ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loadingAiSuggestions || aiSuggestedMoods.isNotEmpty) ...[
          _SectionLabel(
            padding: hPad,
            icon: Icons.auto_awesome_outlined,
            label: '사진 추천',
            accent: true,
            trailing: loadingAiSuggestions
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  )
                : null,
          ),
          if (loadingAiSuggestions && aiSuggestedMoods.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
              child: Text(
                '장면을 보고 무드를 고르는 중…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.inkMuted,
                      fontSize: 12,
                    ),
              ),
            )
          else
            _MoodRow(
              options: aiSuggestedMoods,
              selectedKey: _selectedKey,
              onSelected: onSelected,
              highlightAi: true,
              horizontalPadding: hPad,
            ),
          SizedBox(height: sectionGap),
        ],
        if (hasRecent) ...[
          _SectionLabel(padding: hPad, label: '최근'),
          const SizedBox(height: 8),
          _MoodRow(
            options: recent,
            selectedKey: _selectedKey,
            onSelected: onSelected,
            horizontalPadding: hPad,
          ),
          SizedBox(height: sectionGap),
        ],
        _SectionLabel(
          padding: hPad,
          label: hasRecent ? '전체 무드' : '무드 고르기',
        ),
        const SizedBox(height: 8),
        _MoodGrid(
          options: rest,
          selectedKey: _selectedKey,
          onSelected: onSelected,
          onAddCustom: () => _openAddMood(context),
          horizontalPadding: hPad,
        ),
      ],
    );
  }

  Future<void> _openAddMood(BuildContext context) async {
    final created = await showModalBottomSheet<MoodOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddMoodSheet(),
    );
    if (created == null) return;
    await onAddCustom(created);
    if (context.mounted) onSelected(created);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    this.padding = 0,
    this.icon,
    this.accent = false,
    this.trailing,
  });

  final String label;
  final double padding;
  final IconData? icon;
  final bool accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: accent ? AppTheme.accent : AppTheme.inkMuted,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent ? AppTheme.accent : AppTheme.inkMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
    this.highlightAi = false,
    this.horizontalPadding = 20,
  });

  final List<MoodOption> options;
  final String? selectedKey;
  final ValueChanged<MoodOption> onSelected;
  final bool highlightAi;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _MoodChip.kHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final mood = options[i];
          return _MoodChip(
            mood: mood,
            isSelected: mood.key == selectedKey,
            highlightAi: highlightAi,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(mood);
            },
          );
        },
      ),
    );
  }
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
    required this.onAddCustom,
    this.horizontalPadding = 0,
  });

  final List<MoodOption> options;
  final String? selectedKey;
  final ValueChanged<MoodOption> onSelected;
  final VoidCallback onAddCustom;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final mood in options)
            _MoodChip(
              mood: mood,
              isSelected: mood.key == selectedKey,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(mood);
              },
            ),
          _AddMoodChip(onTap: onAddCustom),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    this.highlightAi = false,
  });

  static const double kWidth = 68;
  static const double kHeight = 72;

  final MoodOption mood;
  final bool isSelected;
  final VoidCallback onTap;
  final bool highlightAi;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.accent
        : highlightAi
            ? AppTheme.accent.withValues(alpha: 0.3)
            : AppTheme.paperDark.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: kWidth,
          height: kHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.14)
                : highlightAi
                    ? AppTheme.accent.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 26, height: 1.1)),
              const SizedBox(height: 4),
              Text(
                mood.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.accent : AppTheme.inkMuted,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoodChip extends StatelessWidget {
  const _AddMoodChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: _MoodChip.kWidth,
          height: _MoodChip.kHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 24,
                color: AppTheme.accent.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 4),
              Text(
                '내 무드',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.accent.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoodSheet extends StatefulWidget {
  const _AddMoodSheet();

  @override
  State<_AddMoodSheet> createState() => _AddMoodSheetState();
}

class _AddMoodSheetState extends State<_AddMoodSheet> {
  String _emoji = kMoodEmojiPicker.first;
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('내 무드 만들기', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '나만의 단어로 적어요 (예: 육아텅, 카페집중)',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kMoodEmojiPicker)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _emoji == e
                          ? AppTheme.accent.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _emoji == e ? AppTheme.accent : AppTheme.paperDark.withValues(alpha: 0.5),
                        width: _emoji == e ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            maxLength: 8,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '무드 이름 (6자 권장)',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _labelController.text.trim().isEmpty
                ? null
                : () {
                    Navigator.pop(
                      context,
                      MoodOption(_emoji, _labelController.text.trim(), isCustom: true),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('추가하고 선택'),
          ),
        ],
      ),
    );
  }
}
