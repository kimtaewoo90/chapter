import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/book_spine_logo.dart';
import '../../widgets/paper_background.dart';

/// 앱 최초 로딩 화면.
/// 디버그에서는 [kPreviewSplashOnEveryRestart]로 Hot restart마다 다시 표시됩니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _expanded = true);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BookSpineLogo(expanded: _expanded),
              const SizedBox(height: 32),
              Text(
                'CHAPTER',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              Text(
                '삶은 날짜보다 분위기로 기억됩니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.inkMuted,
                      height: 1.6,
                    ),
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
