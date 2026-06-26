import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';

class BookSpineLogo extends StatelessWidget {
  const BookSpineLogo({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      width: expanded ? 120 : 28,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5B4F), Color(0xFF8B7355), Color(0xFF6B5B4F)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmShadow,
            blurRadius: 16,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: expanded
          ? Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'CHAPTER',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 4,
                      ),
                ),
              ),
            )
          : null,
    ).animate(target: expanded ? 1 : 0).shimmer(duration: 2.seconds, delay: 400.ms);
  }
}
