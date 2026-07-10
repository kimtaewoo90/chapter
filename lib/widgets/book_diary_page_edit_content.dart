import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_engine.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_layout_metrics.dart';
import '../core/book_layout/book_pdf_style.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/constants/app_fonts.dart';
import 'book_diary_page_renderer.dart';
import 'book_pdf_editable_notebook_box.dart';

/// Phase B — PDF 레이아웃 위에서 직접 편집 (WYSIWYG)
class BookDiaryPageEditContent extends StatelessWidget {
  const BookDiaryPageEditContent({
    super.key,
    required this.entry,
    required this.noteController,
    required this.noteFocusNode,
    required this.diaryFontId,
    this.onMoodTap,
    this.onPhotosTap,
    this.topInset = 0,
    this.showTextField = true,
  });

  final BookDiaryEntry entry;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final AppFontId diaryFontId;
  final VoidCallback? onMoodTap;
  final VoidCallback? onPhotosTap;
  final double topInset;
  final bool showTextField;

  @override
  Widget build(BuildContext context) {
    final plan = BookLayoutEngine.decideLayout(entry);
    final compact = plan.pageMode == BookPageMode.compact;
    final showPhotos = plan.pageMode == BookPageMode.full && entry.photoCount > 0;

    return ColoredBox(
      color: BookPdfStyle.paper,
      child: Padding(
        padding: const EdgeInsets.all(BookPdfPageSpec.margin),
        child: SizedBox(
          height: BookPdfStyle.pageContentHeight,
          width: BookPdfPageSpec.contentWidth,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookPdfEditableEntryHeader(
                    entry: entry,
                    diaryFontId: diaryFontId,
                    onMoodTap: onMoodTap,
                  ),
                  if (showPhotos)
                    _TappablePhotoSection(
                      entry: entry,
                      onTap: onPhotosTap,
                    )
                  else if (onPhotosTap != null)
                    _EmptyPhotoSlot(onTap: onPhotosTap!),
                  if (showTextField)
                    Padding(
                      padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.boxGap),
                      child: BookPdfEditableNotebookBox(
                        controller: noteController,
                        focusNode: noteFocusNode,
                        plan: plan,
                        minLines: BookPdfLayoutMetrics.minLinesForPlan(
                          plan,
                          compact: compact,
                        ),
                        diaryFontId: diaryFontId,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookPdfEditableEntryHeader extends StatelessWidget {
  const BookPdfEditableEntryHeader({
    super.key,
    required this.entry,
    required this.diaryFontId,
    this.onMoodTap,
  });

  final BookDiaryEntry entry;
  final AppFontId diaryFontId;
  final VoidCallback? onMoodTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = entry.date.isNotEmpty
        ? BookPreviewEntryMapper.formatDateLabel(entry.date)
        : '';
    final moodLabel = BookPreviewEntryMapper.formatMoodDisplay(
      moodEmoji: entry.moodEmoji,
      moodLabel: entry.moodLabel,
    );

    Widget moodWidget;
    if (moodLabel != null) {
      moodWidget = Text(
        moodLabel,
        style: diaryFontStyle(
          diaryFontId,
          fontSize: BookPdfStyle.moodSize,
          height: 1.2,
          color: BookPdfStyle.muted,
        ),
      );
    } else {
      moodWidget = Text(
        '+ 무드',
        style: diaryFontStyle(
          diaryFontId,
          fontSize: BookPdfStyle.moodSize,
          height: 1.2,
          color: BookPdfStyle.muted.withValues(alpha: 0.7),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dateLabel.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: BookPdfStyle.dateSize,
                    height: 1.2,
                    color: BookPdfStyle.title,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMoodTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: moodWidget,
                  ),
                ),
              ),
            ],
          ),
        if (dateLabel.isNotEmpty) const SizedBox(height: BookPdfStyle.dateGap),
        Container(height: 0.5, color: BookPdfStyle.line),
        const SizedBox(height: BookPdfStyle.headerBottomGap),
      ],
    );
  }
}

class _TappablePhotoSection extends StatelessWidget {
  const _TappablePhotoSection({
    required this.entry,
    this.onTap,
  });

  final BookDiaryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
        child: Stack(
          children: [
            BookPdfPhotoSection(entry: entry),
            Positioned(
              right: 4,
              bottom: BookEntryBoxStyle.sectionGap + 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BookEntryBoxStyle.border),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '탭해서 편집',
                    style: TextStyle(fontSize: 9, color: BookPdfStyle.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  const _EmptyPhotoSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BookEntryBoxStyle.sectionGap),
      child: Material(
        color: BookEntryBoxStyle.photoBg,
        borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
          child: Container(
            width: BookPdfPageSpec.contentWidth,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BookEntryBoxStyle.radius),
              border: Border.all(color: BookEntryBoxStyle.border, width: 0.6),
            ),
            child: Text(
              '+ 사진 붙이기',
              style: TextStyle(
                fontSize: 13,
                color: BookPdfStyle.muted.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
