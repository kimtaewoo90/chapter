import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/moods.dart';
import '../core/theme/app_theme.dart';
import '../services/mood_profile_service.dart';

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

  String? get _selectedKey =>
      selectedEmoji == null ? null : '$selectedEmoji|${selectedLabel ?? MoodProfileService.labelForEmoji(selectedEmoji!)}';

  @override
  Widget build(BuildContext context) {
    final recent = recentMoods;
    final recentKeys = recent.map((m) => m.key).toSet();
    final rest = moods.where((m) => !recentKeys.contains(m.key)).toList();
    final hasRecent = recent.isNotEmpty;
    final hPad = bookPage ? 0.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loadingAiSuggestions || aiSuggestedMoods.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 6),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Text(
                  bookPage ? '사진이 말해요' : '사진으로 추천',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (loadingAiSuggestions) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  ),
                ],
              ],
            ),
          ),
          if (loadingAiSuggestions && aiSuggestedMoods.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
              child: const Text('장면을 보고 무드를 고르는 중…', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
            )
          else
            _MoodRow(
              options: aiSuggestedMoods,
              selectedKey: _selectedKey,
              onSelected: onSelected,
              onAddCustom: null,
              highlightAi: true,
              horizontalPadding: hPad,
            ),
          SizedBox(height: bookPage ? 8 : 10),
        ],
        if (hasRecent) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 6),
            child: Text(
              bookPage ? '최근 무드' : '최근 쓴 무드',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
            ),
          ),
          _MoodRow(
            options: recent,
            selectedKey: _selectedKey,
            onSelected: onSelected,
            onAddCustom: null,
            horizontalPadding: hPad,
          ),
          SizedBox(height: bookPage ? 8 : 10),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 6),
          child: Text(
            bookPage
                ? '무드 골라요'
                : (hasRecent ? '오늘의 무드' : '오늘의 무드 · 내 말로 골라요'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ),
        _MoodRow(
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

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
    required this.onAddCustom,
    this.highlightAi = false,
    this.horizontalPadding = 20,
  });

  final List<MoodOption> options;
  final String? selectedKey;
  final ValueChanged<MoodOption> onSelected;
  final VoidCallback? onAddCustom;
  final bool highlightAi;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final count = options.length + (onAddCustom != null ? 1 : 0);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (onAddCustom != null && i == count - 1) {
            return _AddMoodChip(onTap: onAddCustom!);
          }
          final mood = options[i];
          final isSelected = mood.key == selectedKey;
          return _MoodChip(
            mood: mood,
            isSelected: isSelected,
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

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    this.highlightAi = false,
  });

  final MoodOption mood;
  final bool isSelected;
  final VoidCallback onTap;
  final bool highlightAi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: mood.isCustom ? 62 : 56,
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
      ),
    );
  }
}

class _AddMoodChip extends StatelessWidget {
  const _AddMoodChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('내 무드 만들기', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '나만의 단어로 적어요 (예: 육아텅, 카페집중)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kMoodEmojiPicker)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _emoji == e ? AppTheme.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _emoji == e ? AppTheme.accent : AppTheme.paperDark,
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
