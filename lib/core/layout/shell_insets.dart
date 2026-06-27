import 'package:flutter/material.dart';

/// 홈 셸 레이아웃 여백 (하단 탭 없음)
abstract final class ShellInsets {
  static double bottom(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 24;
  }

  static double spreadBottom(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 12;
  }
}
