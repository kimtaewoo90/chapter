import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 빈 영역 탭 시 키보드를 내립니다.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  /// 포커스 해제 + OS 키보드 숨김 (저장·탭 전환 등)
  static void unfocus(BuildContext context) {
    final scope = FocusScope.of(context);
    if (scope.hasFocus) {
      scope.unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocus(context),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
