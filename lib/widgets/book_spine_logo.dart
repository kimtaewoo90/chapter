import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'chapter_app_icon.dart';

/// 앱 아이콘 — 스플래시·버전 안내 등 공통 로고
class BookSpineLogo extends StatelessWidget {
  const BookSpineLogo({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final size = expanded ? 120.0 : 56.0;

    return ChapterAppIcon(size: size, shadow: expanded)
        .animate(target: expanded ? 1 : 0)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 500.ms);
  }
}
