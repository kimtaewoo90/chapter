import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 3번째 온보딩 전용 미니 Lottie
class MiniAiSparkleLottie extends StatelessWidget {
  const MiniAiSparkleLottie({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Lottie.asset(
        'assets/animations/ai_sparkle.json',
        repeat: true,
        animate: true,
        fit: BoxFit.contain,
      ),
    );
  }
}
