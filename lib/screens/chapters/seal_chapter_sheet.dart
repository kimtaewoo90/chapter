import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ai_narrative.dart';
import '../../core/utils/chapter_segmenter.dart';
import '../../providers/app_state.dart';

Future<void> showSealChapterSheet(BuildContext context, ChapterSegment segment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SealChapterSheet(segment: segment),
  );
}

class _SealChapterSheet extends StatefulWidget {
  const _SealChapterSheet({required this.segment});

  final ChapterSegment segment;

  @override
  State<_SealChapterSheet> createState() => _SealChapterSheetState();
}

class _SealChapterSheetState extends State<_SealChapterSheet> {
  late final TextEditingController _titleController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: AiNarrative.suggestChapterTitle(widget.segment.entries),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final error = await context.read<AppState>().sealOpenChapterManually(
          title: _titleController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('챕터가 완성됐어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = widget.segment.entries;
    final periodFmt = DateFormat('M월 d일', 'ko_KR');
    final start = periodFmt.format(entries.first.date);
    final end = periodFmt.format(entries.last.date);
    final canSeal = entries.length >= ChapterSegmenter.minEntriesToSeal;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('챕터 마무리', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            canSeal
                ? '$start — $end · ${entries.length}일의 기록을 하나의 챕터로 묶습니다.'
                : '기록 ${ChapterSegmenter.minEntriesToSeal}일 이상 쌓인 뒤 마무리할 수 있어요. (현재 ${entries.length}일)',
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            enabled: canSeal && !_saving,
            decoration: InputDecoration(
              labelText: '챕터 제목',
              hintText: '이 구간을 어떻게 부를까요?',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: canSeal && !_saving ? _confirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('이 챕터 완성하기'),
          ),
        ],
      ),
    );
  }
}
