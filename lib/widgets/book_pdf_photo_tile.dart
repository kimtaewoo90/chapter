import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/book_layout/book_photo_style.dart';
import '../core/book_layout/book_pdf_photo_meta.dart';
import '../core/book_layout/book_pdf_style.dart';
import '../core/book_layout/book_sticker_collage.dart';

/// chapter_admin `drawChapterPhoto` — 슬롯 안에 비율 유지·가운데 정렬
class BookPdfPhotoTile extends StatelessWidget {
  const BookPdfPhotoTile({
    super.key,
    required this.uri,
    required this.meta,
    required this.slotW,
    required this.slotH,
  });

  final String uri;
  final BookImageMeta meta;
  final double slotW;
  final double slotH;

  @override
  Widget build(BuildContext context) {
    final fitted = fitPdfImageSize(
      imageWidth: meta.width,
      imageHeight: meta.height,
      maxW: slotW,
      maxH: slotH,
    );

    return SizedBox(
      width: slotW,
      height: slotH,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BookPhotoFrameStyle.radius),
          child: SizedBox(
            width: fitted.width,
            height: fitted.height,
            child: uri.isEmpty
                ? _placeholder(fitted.width, fitted.height)
                : _buildImage(fitted.width, fitted.height),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double w, double h) {
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: uri,
        width: w,
        height: h,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        fadeInDuration: Duration.zero,
        placeholder: (_, __) => _loadingBox(w, h),
        errorWidget: (_, __, ___) => _placeholder(w, h),
      );
    }

    final path = uri.startsWith('file://') ? uri.substring(7) : uri;
    return Image.file(
      File(path),
      width: w,
      height: h,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _placeholder(w, h),
    );
  }

  Widget _loadingBox(double w, double h) {
    return ColoredBox(
      color: BookEntryBoxStyle.photoBg,
      child: SizedBox(width: w, height: h),
    );
  }

  Widget _placeholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: BookEntryBoxStyle.photoBg,
      alignment: Alignment.center,
      child: const Text(
        '사진',
        style: TextStyle(fontSize: 9, color: BookPdfStyle.placeholder),
      ),
    );
  }
}
