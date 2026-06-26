import 'package:flutter/material.dart';

import '../constants/app_fonts.dart';

class AppTheme {
  static const paper = Color(0xFFF5F0E8);
  static const paperDark = Color(0xFFE8E0D4);
  static const ink = Color(0xFF2C2824);
  static const inkMuted = Color(0xFF6B6560);
  static const accent = Color(0xFF8B7355);
  static const accentLight = Color(0xFFC4A882);
  static const warmShadow = Color(0x1A2C2824);

  static ThemeData light([AppFontId fontId = kDefaultFontId]) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: paper,
        onSurface: ink,
      ),
    );

    return base.copyWith(
      textTheme: appFontTextTheme(fontId, base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appFontStyle(fontId, fontSize: 17, fontWeight: FontWeight.w500, color: ink),
        iconTheme: const IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: paper,
        selectedItemColor: accent,
        unselectedItemColor: inkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: appFontStyle(fontId, fontSize: 14, color: inkMuted),
      ),
    );
  }
}
