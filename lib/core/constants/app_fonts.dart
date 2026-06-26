import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFontId {
  gaegu,
  jua,
  gowunDodum,
  poorStory,
  hiMelody,
  dongle,
  notoSansKr,
  gowunBatang,
}

class AppFontOption {
  const AppFontOption({
    required this.id,
    required this.label,
    required this.description,
  });

  final AppFontId id;
  final String label;
  final String description;
}

const kDefaultFontId = AppFontId.jua;
const kDefaultDiaryFontId = AppFontId.gaegu;

/// 일기 본문·필기창 연필색
const kDiaryInkColor = Color(0xFF3D3A50);

const kAppFontOptions = [
  AppFontOption(
    id: AppFontId.gaegu,
    label: '가게우',
    description: '아기자기 손글씨',
  ),
  AppFontOption(
    id: AppFontId.jua,
    label: '주아',
    description: '동글동글 귀여운 · 기본',
  ),
  AppFontOption(
    id: AppFontId.gowunDodum,
    label: '고운돋움',
    description: '부드럽고 따뜻한',
  ),
  AppFontOption(
    id: AppFontId.poorStory,
    label: '푸어스토리',
    description: '감성 일기체',
  ),
  AppFontOption(
    id: AppFontId.hiMelody,
    label: '하이멜로디',
    description: '발랄하고 가벼운',
  ),
  AppFontOption(
    id: AppFontId.dongle,
    label: '동글',
    description: '요즘 많이 쓰는 라운드',
  ),
  AppFontOption(
    id: AppFontId.notoSansKr,
    label: '노토 산스',
    description: '깔끔 모던',
  ),
  AppFontOption(
    id: AppFontId.gowunBatang,
    label: '고운바탕',
    description: '책 같은 세리프',
  ),
];

AppFontId appFontIdFromKey(String? key, {AppFontId fallback = kDefaultFontId}) {
  if (key == null) return fallback;
  return AppFontId.values.firstWhere(
    (id) => id.name == key,
    orElse: () => fallback,
  );
}

TextStyle appFontStyle(AppFontId id, {double? fontSize, FontWeight? fontWeight, Color? color}) {
  final size = fontSize ?? 14.0;
  final weight = fontWeight ?? FontWeight.w400;
  switch (id) {
    case AppFontId.gaegu:
      return GoogleFonts.gaegu(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.jua:
      return GoogleFonts.jua(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.gowunDodum:
      return GoogleFonts.gowunDodum(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.poorStory:
      return GoogleFonts.poorStory(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.hiMelody:
      return GoogleFonts.hiMelody(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.dongle:
      return GoogleFonts.dongle(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.notoSansKr:
      return GoogleFonts.notoSansKr(fontSize: size, fontWeight: weight, color: color);
    case AppFontId.gowunBatang:
      return GoogleFonts.gowunBatang(fontSize: size, fontWeight: weight, color: color);
  }
}

TextTheme appFontTextTheme(AppFontId id, TextTheme base) {
  switch (id) {
    case AppFontId.gaegu:
      return GoogleFonts.gaeguTextTheme(base);
    case AppFontId.jua:
      return GoogleFonts.juaTextTheme(base);
    case AppFontId.gowunDodum:
      return GoogleFonts.gowunDodumTextTheme(base);
    case AppFontId.poorStory:
      return GoogleFonts.poorStoryTextTheme(base);
    case AppFontId.hiMelody:
      return GoogleFonts.hiMelodyTextTheme(base);
    case AppFontId.dongle:
      return GoogleFonts.dongleTextTheme(base);
    case AppFontId.notoSansKr:
      return GoogleFonts.notoSansKrTextTheme(base);
    case AppFontId.gowunBatang:
      return GoogleFonts.gowunBatangTextTheme(base);
  }
}

AppFontOption appFontOption(AppFontId id) =>
    kAppFontOptions.firstWhere((o) => o.id == id);

/// 기록·피드·책 일기 본문용
TextStyle diaryFontStyle(
  AppFontId id, {
  double fontSize = 18,
  double height = 1.65,
  Color? color,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
}) {
  return appFontStyle(
    id,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? kDiaryInkColor,
  ).copyWith(height: height, fontStyle: fontStyle);
}
