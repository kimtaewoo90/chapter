import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/daily_entry.dart';

/// 월간 리포트 스냅샷 시점의 일기 fingerprint — 이후 일기 수정 감지용
class MonthlyReviewSourceHash {
  MonthlyReviewSourceHash._();

  static String compute(List<DailyEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final lines = sorted.map(_entryFingerprint).join('\n');
    return sha256.convert(utf8.encode(lines)).toString();
  }

  static String _entryFingerprint(DailyEntry e) {
    return [
      e.id,
      e.dateKey,
      e.note ?? '',
      e.aiLine ?? '',
      e.moodEmoji ?? '',
      e.moodLabel ?? '',
      e.location ?? '',
      e.emotion ?? '',
      e.photoCount.toString(),
      e.localPhotoPaths.join(','),
      e.remotePhotoUrls.join(','),
      e.topics.join(','),
    ].join('|');
  }
}
