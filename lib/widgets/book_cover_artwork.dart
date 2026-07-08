import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/book_cover_type.dart';
import '../core/theme/app_theme.dart';
import 'chapter_photo_image.dart';
import 'chapter_app_icon.dart';
import 'chapter_wordmark.dart';
import 'entry_photo.dart';

/// 실물 책 표지 미리보기 — 가운데 Chapter 또는 사진 + (선택) 제목 + 하단 기간
class BookCoverArtwork extends StatelessWidget {
  const BookCoverArtwork({
    super.key,
    required this.coverType,
    required this.dateRangeLabel,
    this.photoUri,
    this.coverTitle,
    this.coverYear,
    this.compact = false,
    this.showDate = true,
    this.fillPage = false,
  });

  final String coverType;
  final String dateRangeLabel;
  final String? photoUri;
  final String? coverTitle;
  /// 표지 하단 연도 (챕터 아이콘 표지). null이면 올해.
  final int? coverYear;
  final bool compact;
  final bool showDate;
  /// PDF 미리보기 등 — 페이지 전체를 크림색으로 채움
  final bool fillPage;

  static const _wordmarkAspect = ChapterWordmark.textAspect;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 6.0 : 28.0;
    final dateSize = compact ? 10.0 : 11.0;
    final titleSize = compact ? 11.0 : 15.0;
    final dateGap = compact ? 0.0 : 10.0;
    final titleGap = compact ? 0.0 : 12.0;
    final bottomPad = compact ? 0.0 : 6.0;

    final titleText = coverTitle?.trim();
    final hasTitle = titleText != null && titleText.isNotEmpty;
    final isChapterIcon = coverType == BookCoverType.chapterIcon;
    final isPhoto = coverType == BookCoverType.customPhoto && photoUri != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(fillPage ? 0 : (compact ? 8 : 12)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.paper,
          border: fillPage ? null : Border.all(color: AppTheme.paperDark),
          boxShadow: compact || fillPage
              ? null
              : const [
                  BoxShadow(
                    color: AppTheme.warmShadow,
                    blurRadius: 18,
                    offset: Offset(4, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isChapterIcon) {
                return _chapterIconCoverLayout(
                  constraints: constraints,
                  titleText: hasTitle ? titleText! : '나의책',
                  year: coverYear ?? DateTime.now().year,
                  compact: compact,
                  titleSize: titleSize,
                  dateSize: dateSize,
                  titleGap: titleGap,
                  dateGap: dateGap,
                  bottomPad: bottomPad,
                );
              }

              final showDateLabel =
                  showDate && !compact && dateRangeLabel.isNotEmpty;
              final innerW = constraints.maxWidth;
              final innerH = constraints.maxHeight;

              final horizontalScale = compact ? 1.0 : 1.25;

              final titleBlockHeight =
                  hasTitle ? titleGap + titleSize * 1.35 : 0.0;
              final dateBlockHeight = showDateLabel
                  ? dateGap + dateSize * 1.35 + bottomPad
                  : 0.0;
              final maxCenterH =
                  (innerH - titleBlockHeight - dateBlockHeight)
                      .clamp(0.0, double.infinity);
              final maxCenterW = innerW;

              final wordmarkHeight = _fitWordmarkHeight(
                maxWidth: maxCenterW,
                maxHeight: maxCenterH,
                horizontalScale: horizontalScale,
                compact: compact,
                hasTitle: hasTitle,
              );
              final photoSize = _fitPhotoSize(
                maxWidth: maxCenterW,
                maxHeight: maxCenterH,
                compact: compact,
                hasTitle: hasTitle,
              );

              final centerChild = isPhoto
                  ? _CoverPhoto(uri: photoUri!, size: photoSize)
                  : ChapterWordmark(
                      height: wordmarkHeight,
                      horizontalScale: horizontalScale,
                      centered: true,
                    );

              return Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: hasTitle
                          ? const Alignment(0, -0.18)
                          : Alignment.center,
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRect(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: centerChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasTitle) ...[
                    SizedBox(height: titleGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        titleText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                  if (showDateLabel) ...[
                    SizedBox(height: dateGap),
                    Text(
                      dateRangeLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dateSize,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        height: 1.15,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    SizedBox(height: bottomPad),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chapterIconCoverLayout({
    required BoxConstraints constraints,
    required String titleText,
    required int year,
    required bool compact,
    required double titleSize,
    required double dateSize,
    required double titleGap,
    required double dateGap,
    required double bottomPad,
  }) {
    final innerW = constraints.maxWidth;
    final innerH = constraints.maxHeight;
    final titleBlockHeight = titleGap + titleSize * 1.35;
    final yearBlockHeight = dateGap + dateSize * 1.35 + bottomPad;
    final maxIconH = (innerH - titleBlockHeight - yearBlockHeight).clamp(0.0, double.infinity);
    final iconSize = math.min(innerW * (compact ? 0.42 : 0.38), maxIconH * (compact ? 0.92 : 0.88))
        .clamp(compact ? 28.0 : 72.0, compact ? 72.0 : 128.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: ChapterAppIcon(
              size: iconSize,
              shadow: !compact,
            ),
          ),
        ),
        SizedBox(height: titleGap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            titleText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: AppTheme.ink,
            ),
          ),
        ),
        SizedBox(height: dateGap),
        Text(
          '$year',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? dateSize + 2 : dateSize + 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
            height: 1.1,
            color: AppTheme.inkMuted,
          ),
        ),
        SizedBox(height: bottomPad),
      ],
    );
  }

  static double _fitWordmarkHeight({
    required double maxWidth,
    required double maxHeight,
    required double horizontalScale,
    required bool compact,
    required bool hasTitle,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) return compact ? 20 : 56;

    final heightRatio = compact ? 0.9 : (hasTitle ? 0.56 : 0.62);
    final maxCap = hasTitle ? 100.0 : 112.0;
    final heightCap = compact
        ? maxHeight * 0.9
        : math.min(maxHeight * heightRatio, maxCap);
    final widthCap = maxWidth / (_wordmarkAspect * horizontalScale);
    return math.min(heightCap, widthCap).clamp(compact ? 16.0 : 48.0, 128.0);
  }

  static double _fitPhotoSize({
    required double maxWidth,
    required double maxHeight,
    required bool compact,
    required bool hasTitle,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) return compact ? 24 : 100;
    final cap = math.min(maxWidth, maxHeight);
    if (compact) return cap * 0.92;
    final ratio = hasTitle ? 0.42 : 0.48;
    final maxPx = hasTitle ? 132.0 : 148.0;
    return math.min(cap * ratio, maxPx).clamp(68.0, maxPx);
  }
}

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.uri, required this.size});

  final String uri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.1;
    if (uri.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: EntryPhoto(url: uri, height: size, borderRadius: 0),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ChapterPhotoImage(
        file: File(uri),
        uri: uri,
        width: size,
        height: size,
      ),
    );
  }
}
