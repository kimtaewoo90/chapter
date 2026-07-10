import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_diary_block.dart';
import '../core/book_layout/book_pdf_page_planner.dart';
import '../core/book_layout/book_pdf_photo_meta.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'book_diary_page_renderer.dart';

/// 단일 일기 — PDF 책 페이지와 동일한 레이아웃 미리보기 (Phase A)
class BookDiaryPagePreview extends StatefulWidget {
  const BookDiaryPagePreview({
    super.key,
    required this.entry,
    this.diaryFontId,
    this.showPageIndicator = true,
    this.caption,
  });

  final BookDiaryEntry entry;
  final AppFontId? diaryFontId;
  final bool showPageIndicator;
  final String? caption;

  factory BookDiaryPagePreview.fromDraft({
    Key? key,
    required DateTime date,
    String? note,
    List<String> photoUris = const [],
    String? moodEmoji,
    String? moodLabel,
    AppFontId? diaryFontId,
    bool showPageIndicator = true,
    String? caption,
  }) {
    return BookDiaryPagePreview(
      key: key,
      entry: BookPreviewEntryMapper.fromDraft(
        date: date,
        note: note,
        photoUris: photoUris,
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
      ),
      diaryFontId: diaryFontId,
      showPageIndicator: showPageIndicator,
      caption: caption,
    );
  }

  @override
  State<BookDiaryPagePreview> createState() => _BookDiaryPagePreviewState();
}

class _BookDiaryPagePreviewState extends State<BookDiaryPagePreview> {
  List<BookPdfPreviewPage> _pages = const [];
  bool _ready = false;
  int _pageIndex = 0;
  late PageController _controller;
  Timer? _reloadDebounce;
  Object _loadGeneration = Object();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _loadPages();
  }

  @override
  void didUpdateWidget(covariant BookDiaryPagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.diaryFontId != widget.diaryFontId) {
      _scheduleLoadPages();
    }
  }

  void _scheduleLoadPages() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 280), _loadPages);
  }

  Future<void> _loadPages() async {
    final generation = Object();
    _loadGeneration = generation;
    final uris = widget.entry.photoUris.where((u) => u.isNotEmpty);
    await BookPdfPhotoMeta.preload(uris);
    if (!mounted || !identical(_loadGeneration, generation)) return;

    final fontId = widget.diaryFontId ??
        context.read<AppState>().diaryFontId;

    setState(() {
      _pages = BookPdfPreviewPlanner.planSingleEntry(
        entry: widget.entry,
        diaryFontId: fontId,
      );
      _pageIndex = 0;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fontId = widget.diaryFontId ??
        context.watch<AppState>().diaryFontId;

    if (!_ready) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.caption != null) ...[
            Text(
              widget.caption!,
              style: textTheme.labelSmall?.copyWith(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          AspectRatio(
            aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.inkMuted.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      );
    }

    if (_pages.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.caption != null) ...[
            Text(
              widget.caption!,
              style: textTheme.labelSmall?.copyWith(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          AspectRatio(
            aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
            child: BookPdfPageFrame(
              child: BookPdfDiaryPageContent(
                blocks: [
                  BookDiaryHeaderBlock(widget.entry),
                ],
                topInset: 0,
                diaryFontId: fontId,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.caption != null) ...[
          Text(
            widget.caption!,
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AspectRatio(
          aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return BookPdfPageFrame(
                child: BookPdfDiaryPageContent(
                  blocks: page.diaryBlocks!,
                  topInset: page.topInset,
                  diaryFontId: fontId,
                ),
              );
            },
          ),
        ),
        if (widget.showPageIndicator && _pages.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                visualDensity: VisualDensity.compact,
                onPressed: _pageIndex > 0
                    ? () => _controller.previousPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        )
                    : null,
              ),
              Text(
                '${_pageIndex + 1} / ${_pages.length}',
                style: textTheme.labelMedium?.copyWith(color: AppTheme.inkMuted),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                visualDensity: VisualDensity.compact,
                onPressed: _pageIndex < _pages.length - 1
                    ? () => _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        )
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
