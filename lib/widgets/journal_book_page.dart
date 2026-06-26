import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/entry_diary_ai.dart';
import '../core/utils/entry_photos.dart';
import '../models/daily_entry.dart';
import '../providers/app_state.dart';
import 'entry_photo.dart';

/// 피드 — 하루가 한 장의 책 페이지
class JournalBookPage extends StatelessWidget {
  const JournalBookPage({
    super.key,
    required this.entry,
    required this.pageNumber,
    required this.totalPages,
    this.onTap,
    this.scrollable = false,
  });

  final DailyEntry entry;
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onTap;
  /// 펼쳐보기 — 페이지 안에서 위아래 스크롤
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return _ScrollableBookPage(
        entry: entry,
        pageNumber: pageNumber,
        totalPages: totalPages,
        onTap: onTap,
      );
    }
    return _FixedBookPage(
      entry: entry,
      pageNumber: pageNumber,
      totalPages: totalPages,
      onTap: onTap,
    );
  }
}

class _ScrollableBookPage extends StatelessWidget {
  const _ScrollableBookPage({
    required this.entry,
    required this.pageNumber,
    required this.totalPages,
    this.onTap,
  });

  final DailyEntry entry;
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diaryFontId = context.watch<AppState>().diaryFontId;
    final uris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
    final caption = EntryDiaryAi.primaryDiaryText(entry);
    final dateFmt = DateFormat('yyyy년 M월 d일 · EEEE', 'ko_KR');
    final handwriting = diaryFontStyle(diaryFontId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = constraints.maxHeight;

        return Container(
          margin: const EdgeInsets.only(top: 2),
          height: viewportH,
          decoration: _bookDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _LinedPaperPainter())),
                _BookSpine(),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 22, 20, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewportH - 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DateRow(
                          dateLabel: dateFmt.format(entry.date),
                          moodEmoji: entry.moodEmoji,
                          onTap: onTap,
                        ),
                        if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.moodLabel!,
                            style: handwriting.copyWith(fontSize: 16, color: AppTheme.accent),
                          ),
                        ],
                        if (uris.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          if (uris.length == 1)
                            EntryPhoto(
                              url: uris.first,
                              borderRadius: 4,
                              naturalWidth: true,
                            )
                          else
                            ...uris.map(
                              (uri) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: EntryPhoto(
                                  url: uri,
                                  borderRadius: 4,
                                  naturalWidth: true,
                                ),
                              ),
                            ),
                          if (uris.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '사진 ${uris.length}장',
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                              ),
                            ),
                        ],
                        if (caption != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            caption,
                            style: handwriting.copyWith(fontSize: 17, height: 1.55),
                          ),
                        ] else if (uris.isEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            '무드만 남긴 하루',
                            style: handwriting.copyWith(color: AppTheme.inkMuted),
                          ),
                        ],
                        if (entry.weatherDisplayLine != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            entry.weatherDisplayLine!,
                            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$pageNumber / $totalPages',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppTheme.inkMuted.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FixedBookPage extends StatelessWidget {
  const _FixedBookPage({
    required this.entry,
    required this.pageNumber,
    required this.totalPages,
    this.onTap,
  });

  final DailyEntry entry;
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diaryFontId = context.watch<AppState>().diaryFontId;
    final uris = EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
    final caption = EntryDiaryAi.primaryDiaryText(entry);
    final dateFmt = DateFormat('yyyy년 M월 d일 · EEEE', 'ko_KR');
    final handwriting = diaryFontStyle(diaryFontId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: _bookDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _LinedPaperPainter())),
              _BookSpine(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateRow(
                      dateLabel: dateFmt.format(entry.date),
                      moodEmoji: entry.moodEmoji,
                    ),
                    if (entry.moodLabel != null && entry.moodLabel!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.moodLabel!,
                        style: handwriting.copyWith(fontSize: 16, color: AppTheme.accent),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (uris.isNotEmpty)
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: uris.length == 1
                              ? EntryPhoto(url: uris.first, height: double.infinity, borderRadius: 4)
                              : PageView.builder(
                                  itemCount: uris.length,
                                  itemBuilder: (_, i) =>
                                      EntryPhoto(url: uris[i], height: double.infinity, borderRadius: 4),
                                ),
                        ),
                      )
                    else
                      const Spacer(flex: 1),
                    if (caption != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        caption,
                        style: handwriting,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (uris.isEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        '무드만 남긴 하루',
                        style: handwriting.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                    if (entry.weatherDisplayLine != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.weatherDisplayLine!,
                        style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                    const Spacer(flex: 1),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$pageNumber / $totalPages',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.inkMuted.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.dateLabel,
    this.moodEmoji,
    this.onTap,
  });

  final String dateLabel;
  final String? moodEmoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            dateLabel,
            style: textTheme.labelMedium?.copyWith(
              color: AppTheme.inkMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (moodEmoji != null)
          Text(moodEmoji!, style: const TextStyle(fontSize: 22)),
      ],
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      ),
    );
  }
}

const _bookDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(6)),
  boxShadow: [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 22,
      offset: Offset(4, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 6,
      offset: Offset(1, 2),
    ),
  ],
);

class _BookSpine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.ink.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
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
    const lineGap = 28.0;
    for (var y = 56.0; y < size.height - 24; y += lineGap) {
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
