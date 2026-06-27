import 'package:flutter/material.dart';

import 'package:chapter/core/constants/app_fonts.dart';
import 'package:chapter/core/theme/app_theme.dart';

/// App Store 6.7" — 1290×2796 px (프리미엄 마케팅 프레임)
class StoreScreenshotFrame extends StatelessWidget {
  const StoreScreenshotFrame({
    super.key,
    required this.headline,
    required this.subheadline,
    required this.body,
    this.dark = false,
  });

  final String headline;
  final String subheadline;
  final Widget body;
  final bool dark;

  static const width = 1290.0;
  static const height = 2796.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: dark ? _buildDark() : _buildLight(),
    );
  }

  Widget _buildLight() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBF8F3), Color(0xFFF3EDE4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 96),
          _BrandRow(dark: false),
          SizedBox(
            height: 420,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(80, 40, 80, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: appFontStyle(
                      kDefaultFontId,
                      fontSize: 68,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ).copyWith(height: 1.18, letterSpacing: -1.2),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    subheadline,
                    style: appFontStyle(
                      kDefaultFontId,
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.inkMuted,
                    ).copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 56, 0),
              child: _DeviceFrame(
                child: body,
              ),
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Widget _buildDark() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141210), Color(0xFF1E1B18)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 96),
          const _BrandRow(dark: true),
          SizedBox(
            height: 420,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(80, 40, 80, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: appFontStyle(
                      kDefaultFontId,
                      fontSize: 68,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ).copyWith(height: 1.18, letterSpacing: -1.2),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    subheadline,
                    style: appFontStyle(
                      kDefaultFontId,
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.72),
                    ).copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 56, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: body,
              ),
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '챕터',
            style: appFontStyle(
              kDefaultFontId,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : AppTheme.accent,
            ),
          ),
          const Spacer(),
          Text(
            'Chapter',
            style: appFontStyle(
              kDefaultFontId,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: dark ? Colors.white38 : AppTheme.inkMuted.withValues(alpha: 0.55),
            ).copyWith(letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(58),
        color: const Color(0xFF101010),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.22),
            blurRadius: 80,
            offset: const Offset(0, 40),
          ),
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.08),
            blurRadius: 120,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(46),
          child: ColoredBox(
            color: AppTheme.paper,
            child: Column(
              children: [
                const _StatusBar(),
                const _DynamicIsland(),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Center(
        child: Container(
          width: 126,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 14, 36, 0),
        child: Row(
          children: [
            Text(
              '9:41',
              style: appFontStyle(
                kDefaultFontId,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt, size: 24, color: AppTheme.ink.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Icon(Icons.wifi, size: 24, color: AppTheme.ink.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Icon(Icons.battery_full_rounded, size: 26, color: AppTheme.ink.withValues(alpha: 0.85)),
          ],
        ),
      ),
    );
  }
}
