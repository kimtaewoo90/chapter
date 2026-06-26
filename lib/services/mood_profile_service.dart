import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/moods.dart';
import '../models/daily_entry.dart';

/// 최근 사용 + 내 무드 + 기본 목록으로 개인화
class MoodProfileService {
  static const _customKey = 'custom_moods_v1';
  static const _maxCustom = 8;

  static Future<List<MoodOption>> loadCustomMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            MoodOption(
              item['emoji'] as String? ?? '🙂',
              item['label'] as String? ?? '무드',
              isCustom: true,
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomMood(MoodOption mood) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomMoods();
    final next = [
      mood.copyWith(isCustom: true),
      ...current.where((m) => m.key != mood.key),
    ].take(_maxCustom).toList();
    await prefs.setString(
      _customKey,
      jsonEncode([
        for (final m in next) {'emoji': m.emoji, 'label': m.label},
      ]),
    );
  }

  /// 최근 일기에서 쓴 무드 (최대 4)
  static List<MoodOption> recentFromEntries(List<DailyEntry> entries, {int max = 4}) {
    final out = <MoodOption>[];
    final seen = <String>{};
    for (final e in entries.reversed) {
      final emoji = e.moodEmoji;
      if (emoji == null || emoji.isEmpty) continue;
      final label = e.moodLabel ?? labelForEmoji(emoji);
      final m = MoodOption(emoji, label);
      if (seen.add(m.key)) out.add(m);
      if (out.length >= max) break;
    }
    return out;
  }

  /// 기록 화면에 보여줄 순서: 최근 → 내 무드 → 기본
  static List<MoodOption> personalized({
    required List<DailyEntry> entries,
    required List<MoodOption> customMoods,
  }) {
    final out = <MoodOption>[];
    final seen = <String>{};

    void add(MoodOption m) {
      if (seen.add(m.key)) out.add(m);
    }

    for (final e in entries.reversed) {
      final emoji = e.moodEmoji;
      if (emoji == null || emoji.isEmpty) continue;
      final label = e.moodLabel ?? labelForEmoji(emoji, customMoods: customMoods);
      add(MoodOption(emoji, label));
      if (out.length >= 4) break;
    }

    for (final m in customMoods) {
      add(m);
    }

    for (final m in kDefaultMoods) {
      add(m);
      if (out.length >= 16) break;
    }

    return out;
  }

  static String labelForEmoji(
    String emoji, {
    List<MoodOption> customMoods = const [],
  }) {
    for (final m in customMoods) {
      if (m.emoji == emoji) return m.label;
    }
    for (final m in kDefaultMoods) {
      if (m.emoji == emoji) return m.label;
    }
    return '무드';
  }

  static MoodOption? matchSelection({
    required String? emoji,
    required String? label,
    required List<MoodOption> catalog,
  }) {
    if (emoji == null) return null;
    final l = label ?? labelForEmoji(emoji);
    for (final m in catalog) {
      if (m.key == '$emoji|$l') return m;
    }
    return MoodOption(emoji, l);
  }
}
