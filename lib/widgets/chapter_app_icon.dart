import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 앱 아이콘 — squircle 한 겹 (배경 + Chapter 글자)
class ChapterAppIcon extends StatelessWidget {
  const ChapterAppIcon({
    super.key,
    required this.size,
    this.shadow = false,
  });

  final double size;
  final bool shadow;

  static const _foregroundPath = 'assets/images/app_icon_foreground.png';

  /// iOS 앱 아이콘 corner radius ≈ 22.37%
  static double cornerRadiusFor(double size) => size * 0.2237;

  @override
  Widget build(BuildContext context) {
    final radius = cornerRadiusFor(size);

    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset(
          _foregroundPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );

    if (!shadow) return icon;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: icon,
    );
  }
}
