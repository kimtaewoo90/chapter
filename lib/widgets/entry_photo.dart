import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EntryPhoto extends StatelessWidget {
  const EntryPhoto({
    super.key,
    this.url,
    this.file,
    this.height = 220,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.naturalWidth = false,
  });

  final String? url;
  final File? file;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  /// 가로 너비에 맞추고 세로는 비율대로 (회색 여백 없음)
  final bool naturalWidth;

  @override
  Widget build(BuildContext context) {
    if (naturalWidth) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildNaturalWidthImage(context),
      );
    }
    if (!height.isFinite) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final resolved = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : 400.0;
          return _buildClipped(context, resolved);
        },
      );
    }
    return _buildClipped(context, height);
  }

  Widget _buildClipped(BuildContext context, double resolvedHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(context, resolvedHeight),
    );
  }

  Widget _buildImage(BuildContext context, double resolvedHeight) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = _cacheDimension(resolvedHeight * 0.85, dpr);
    final cacheH = _cacheDimension(resolvedHeight, dpr);

    Widget child;
    if (file != null) {
      child = Image.file(
        file!,
        fit: fit,
        width: double.infinity,
        height: resolvedHeight,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _placeholder(resolvedHeight),
      );
    } else if (url != null && url!.isNotEmpty) {
      if (_isLocalPath(url!)) {
        child = Image.file(
          File(url!),
          fit: fit,
          width: double.infinity,
          height: resolvedHeight,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _placeholder(resolvedHeight),
        );
      } else {
        child = CachedNetworkImage(
          imageUrl: url!,
          fit: fit,
          width: double.infinity,
          height: resolvedHeight,
          memCacheWidth: cacheW,
          memCacheHeight: cacheH,
          filterQuality: FilterQuality.high,
          placeholder: (_, __) => _placeholder(resolvedHeight),
          errorWidget: (_, __, ___) => _placeholder(resolvedHeight),
        );
      }
    } else {
      child = _placeholder(resolvedHeight);
    }

    if (fit == BoxFit.contain) {
      return Container(
        width: double.infinity,
        height: resolvedHeight,
        color: AppTheme.paperDark.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: child,
      );
    }

    return child;
  }

  Widget _buildNaturalWidthImage(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final cacheW = _cacheDimension(screenW, dpr);

    if (file != null) {
      return Image.file(
        file!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        cacheWidth: cacheW,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _placeholder(180),
      );
    }
    if (url != null && url!.isNotEmpty) {
      if (_isLocalPath(url!)) {
        return Image.file(
          File(url!),
          width: double.infinity,
          fit: BoxFit.fitWidth,
          cacheWidth: cacheW,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _placeholder(180),
        );
      }
      return CachedNetworkImage(
        imageUrl: url!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        memCacheWidth: cacheW,
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => _placeholder(180),
        errorWidget: (_, __, ___) => _placeholder(180),
      );
    }
    return _placeholder(180);
  }

  int? _cacheDimension(double logicalPx, double dpr) {
    if (!logicalPx.isFinite || logicalPx <= 0 || !dpr.isFinite || dpr <= 0) {
      return null;
    }
    final scaled = logicalPx * dpr;
    if (!scaled.isFinite || scaled <= 0) return null;
    return scaled.round();
  }

  bool _isLocalPath(String path) => path.startsWith('/') || path.startsWith('file://');

  Widget _placeholder([double? resolvedHeight]) {
    final h = resolvedHeight ?? (height.isFinite ? height : 220.0);
    final compact = h < 100;

    return Container(
      height: h,
      width: double.infinity,
      color: AppTheme.paperDark,
      alignment: Alignment.center,
      child: compact
          ? Icon(
              Icons.photo_outlined,
              size: (h * 0.42).clamp(18.0, 40.0),
              color: AppTheme.inkMuted,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_outlined, size: 48, color: AppTheme.inkMuted),
                const SizedBox(height: 8),
                Text(
                  '오늘의 장면',
                  style: TextStyle(
                    color: AppTheme.inkMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}
