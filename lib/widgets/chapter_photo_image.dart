import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 일기 사진 — 화면 크기 × DPR에 맞춰 디코딩 (과도한 축소 방지)
class ChapterPhotoImage extends StatelessWidget {
  const ChapterPhotoImage({
    super.key,
    this.file,
    this.uri,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fullResolution = false,
  });

  final File? file;
  final String? uri;
  final double width;
  final double height;
  final BoxFit fit;
  /// 확대 뷰어 등 — 원본에 가깝게 디코딩
  final bool fullResolution;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = fullResolution ? null : (width * dpr).round();
    final cacheH = fullResolution ? null : (height * dpr).round();
    const quality = FilterQuality.high;

    if (file != null) {
      return Image.file(
        file!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: quality,
        gaplessPlayback: true,
      );
    }

    final u = uri;
    if (u == null || u.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    if (u.startsWith('http://') || u.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: u,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        filterQuality: quality,
      );
    }

    final path = u.startsWith('file://') ? Uri.parse(u).toFilePath() : u;
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      filterQuality: quality,
      gaplessPlayback: true,
    );
  }
}
