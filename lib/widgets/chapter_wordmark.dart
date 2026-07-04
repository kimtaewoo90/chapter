import 'package:flutter/material.dart';

/// 홈·브랜딩용 Chapter 워드마크 — 아이콘과 동일한 손글씨 PNG (가로 확장)
class ChapterWordmark extends StatelessWidget {
  const ChapterWordmark({
    super.key,
    this.height = 42,
    this.horizontalScale = 1.45,
    this.centered = false,
  });

  final double height;

  /// 1.0 = 원본 비율, 1.45 ≈ 헤더용 살짝 넓게
  final double horizontalScale;

  /// true면 가운데 정렬 (표지 등), false면 왼쪽 정렬 (홈 헤더)
  final bool centered;

  static const _assetPath = 'assets/images/app_icon_foreground.png';

  /// foreground PNG 안 Chapter 글자 대략 가로/세로
  static const textAspect = 737 / 324;

  @override
  Widget build(BuildContext context) {
    final baseWidth = height * textAspect;
    final displayWidth = baseWidth * horizontalScale;
    final align = centered ? Alignment.center : Alignment.centerLeft;

    return SizedBox(
      width: displayWidth,
      height: height,
      child: ClipRect(
        child: Transform(
          alignment: align,
          transform: Matrix4.diagonal3Values(horizontalScale, 1, 1),
          child: Image.asset(
            _assetPath,
            height: height,
            fit: BoxFit.fitHeight,
            alignment: align,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
