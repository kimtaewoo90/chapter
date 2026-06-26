import 'dart:io';

import 'package:flutter/material.dart';

import '../core/book_layout/book_layout_engine.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_photo_style.dart';
import '../core/book_layout/book_preview_entry_mapper.dart';
import '../core/book_layout/book_sticker_collage.dart';
import '../core/theme/app_theme.dart';
import '../models/book_entry_snapshot.dart';
import '../models/daily_entry.dart';
import 'entry_photo.dart';

/// chapter_admin PDF generator와 동일 레이아웃의 책 미리보기
class BookPdfPreview extends StatefulWidget {
  const BookPdfPreview({
    super.key,
    required this.diaryEntries,
    required this.bookTitle,
  });

  final List<BookDiaryEntry> diaryEntries;
  final String bookTitle;

  factory BookPdfPreview.fromDailyEntries({
    Key? key,
    required List<DailyEntry> entries,
    required String bookTitle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromDailyEntries(entries),
      bookTitle: bookTitle,
    );
  }

  factory BookPdfPreview.fromSnapshots({
    Key? key,
    required List<BookEntrySnapshot> snapshots,
    required String bookTitle,
  }) {
    return BookPdfPreview(
      key: key,
      diaryEntries: BookPreviewEntryMapper.fromSnapshots(snapshots),
      bookTitle: bookTitle,
    );
  }

  @override
  State<BookPdfPreview> createState() => _BookPdfPreviewState();
}

class _BookPdfPreviewState extends State<BookPdfPreview> {
  late final PageController _controller;
  int _pageIndex = 0;

  List<BookPagePlan> get _pagePlans => BookLayoutEngine.planBookPages(widget.diaryEntries);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _totalPages => 1 + _pagePlans.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: BookPdfPageSpec.width / BookPdfPageSpec.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _totalPages,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BookPdfPageShell(
                  child: _BookPdfCoverPage(title: widget.bookTitle),
                );
              }
              return _BookPdfPageShell(
                child: _BookPdfContentPage(plan: _pagePlans[index - 1]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _pageIndex > 0
                  ? () => _controller.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      )
                  : null,
            ),
            Text(
              _pageIndex == 0
                  ? '표지 · $_totalPages페이지'
                  : '${_pageIndex + 1} / $_totalPages',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkMuted,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _pageIndex < _totalPages - 1
                  ? () => _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '좌우로 넘기면 실제 인쇄 PDF와 같은 배치로 볼 수 있어요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.inkMuted,
              ),
        ),
      ],
    );
  }
}

class _BookPdfPageShell extends StatelessWidget {
  const _BookPdfPageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmShadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: BookPdfPageSpec.width,
              height: BookPdfPageSpec.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// chapter_admin `pdf/generator.js` COLORS
class _BookPdfColors {
  static const title = Color(0xFF1A1A1A);
  static const subtitle = Color(0xFF6B6B6B);
  static const body = Color(0xFF2D2D2D);
  static const muted = Color(0xFF999999);
  static const line = Color(0xFFE8E8E8);
  static const placeholder = Color(0xFFCCCCCC);
}

class _BookPdfCoverPage extends StatelessWidget {
  const _BookPdfCoverPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const centerY = BookPdfPageSpec.height * 0.38;
    const margin = BookPdfPageSpec.margin;
    const contentWidth = BookPdfPageSpec.contentWidth;

    return Stack(
      children: [
        Positioned(
          left: margin + 40,
          right: margin + 40,
          top: centerY + 50,
          child: Container(height: 0.5, color: _BookPdfColors.line),
        ),
        Positioned(
          left: margin,
          top: centerY - 20,
          width: contentWidth,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _BookPdfColors.title,
              height: 1.25,
            ),
          ),
        ),
        Positioned(
          left: margin,
          top: centerY + 64,
          width: contentWidth,
          child: const Text(
            'Chapter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: _BookPdfColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookPdfContentPage extends StatelessWidget {
  const _BookPdfContentPage({required this.plan});

  final BookPagePlan plan;

  static const _entryGap = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BookPdfPageSpec.margin),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: BookPdfPageSpec.contentWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < plan.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: _entryGap),
                  if (plan.items[i].kind == BookPageItemKind.full)
                    _BookPdfFullEntry(layout: plan.items[i].layout)
                  else
                    _BookPdfCompactEntry(entry: plan.items[i].layout.entry),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPdfEntryHeader extends StatelessWidget {
  const _BookPdfEntryHeader({required this.entry});

  final BookDiaryEntry entry;

  static const dateGap = 8.0;
  static const titleGap = 16.0;
  static const dividerGap = 14.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.date.isNotEmpty)
          Text(
            entry.date,
            style: const TextStyle(
              fontSize: 10,
              color: _BookPdfColors.muted,
            ),
          ),
        if (entry.date.isNotEmpty) const SizedBox(height: dateGap),
        Text(
          entry.title.isNotEmpty ? entry.title : entry.date,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _BookPdfColors.title,
            height: 1.2,
          ),
        ),
        const SizedBox(height: titleGap),
        Container(height: 0.5, color: _BookPdfColors.line),
        const SizedBox(height: dividerGap),
      ],
    );
  }
}

class _BookPdfFullEntry extends StatelessWidget {
  const _BookPdfFullEntry({required this.layout});

  final BookEntryLayout layout;

  @override
  Widget build(BuildContext context) {
    final entry = layout.entry;
    final plan = layout.plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookPdfEntryHeader(entry: entry),
        if (entry.photoCount > 0) ...[
          _BookPdfPhotoSection(entry: entry),
          const SizedBox(height: 16),
        ],
        if (entry.body.isNotEmpty)
          Text(
            entry.body,
            textAlign: plan.textStyle == BookTextStyle.caption
                ? TextAlign.center
                : TextAlign.left,
            style: TextStyle(
              fontSize: plan.textStyle == BookTextStyle.caption ? 10 : 11,
              color: _BookPdfColors.body,
              height: plan.textStyle == BookTextStyle.fullStyle ? 1.55 : 1.35,
            ),
          ),
      ],
    );
  }
}

class _BookPdfCompactEntry extends StatelessWidget {
  const _BookPdfCompactEntry({required this.entry});

  final BookDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookPdfEntryHeader(entry: entry),
        if (entry.body.isNotEmpty)
          Text(
            entry.body,
            style: const TextStyle(
              fontSize: 11,
              color: _BookPdfColors.body,
              height: 1.45,
            ),
          ),
      ],
    );
  }
}

class _BookPdfPhotoSection extends StatelessWidget {
  const _BookPdfPhotoSection({required this.entry});

  final BookDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final photoCount = entry.photoCount;
    final maxLong = photoCount == 1
        ? BookPhotoFrameStyle.maxLongSingle
        : BookPhotoFrameStyle.maxLongMulti;

    final stickerItems = List.generate(
      photoCount,
      (i) => BookStickerItem(
        index: i,
        meta: const BookImageMeta(width: 1600, height: 1200),
      ),
    );

    final collage = BookStickerCollage.layoutStickerCollage(
      stickerItems,
      BookPdfPageSpec.contentWidth,
      options: BookStickerCollageOptions(maxLongEdge: maxLong),
    );

    return SizedBox(
      width: BookPdfPageSpec.contentWidth,
      height: collage.totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final placement in collage.placements)
            Positioned(
              left: placement.x,
              top: placement.y,
              width: placement.frameW,
              height: placement.frameH,
              child: _BookPdfPhotoTile(
                uri: entry.photoUris[placement.index],
                width: placement.frameW,
                height: placement.frameH,
              ),
            ),
        ],
      ),
    );
  }
}

class _BookPdfPhotoTile extends StatelessWidget {
  const _BookPdfPhotoTile({
    required this.uri,
    required this.width,
    required this.height,
  });

  final String uri;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (uri.isEmpty) {
      return _photoPlaceholder(width, height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(BookPhotoFrameStyle.radius),
      child: SizedBox(
        width: width,
        height: height,
        child: uri.startsWith('http')
            ? EntryPhoto(url: uri, height: height, borderRadius: 0, fit: BoxFit.contain)
            : EntryPhoto(
                file: File(uri),
                height: height,
                borderRadius: 0,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _photoPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BookPhotoFrameStyle.radius),
        border: Border.all(color: _BookPdfColors.line),
      ),
      alignment: Alignment.center,
      child: const Text(
        '사진',
        style: TextStyle(fontSize: 9, color: _BookPdfColors.placeholder),
      ),
    );
  }
}
