import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'paper_background.dart';
import 'paper_journal_field.dart';

Future<void> showJournalWriteSheet(
  BuildContext context, {
  required TextEditingController controller,
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
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _JournalWriteSheetBody(
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class _JournalWriteSheetBody extends StatefulWidget {
  const _JournalWriteSheetBody({
    required this.controller,
    required this.scrollController,
  });

  final TextEditingController controller;
  final ScrollController scrollController;

  @override
  State<_JournalWriteSheetBody> createState() => _JournalWriteSheetBodyState();
}

class _JournalWriteSheetBodyState extends State<_JournalWriteSheetBody> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _requestFocusSoon();
  }

  void _requestFocusSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
                    '✍️ 오늘의 글',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                PaperJournalField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  embedded: true,
                  minLines: 18,
                  maxLength: 500,
                  hintText: '마음에 남는 것을 적어 보세요…',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
