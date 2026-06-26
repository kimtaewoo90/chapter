import '../../models/daily_entry.dart';

/// 오늘 일기 — AI가 **글(본문)** 을 쓸지, UI에 무엇을 보여줄지
class EntryDiaryAi {
  EntryDiaryAi._();

  /// **글 없이 사진만** 있을 때만 AI가 사진을 보고 일기 본문 작성
  static bool shouldGenerateAiDiary({
    required String? note,
    required bool hasPhotos,
  }) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty && hasPhotos;
  }

  static bool shouldGenerateAiDiaryForEntry(DailyEntry entry) {
    return shouldGenerateAiDiary(
      note: entry.note,
      hasPhotos: entry.hasPhotos,
    );
  }

  /// AI 한 줄 표시: 사진만 기록 + aiLine 있음 (글 있으면 숨김)
  static bool shouldShowAiLine(DailyEntry entry) {
    final ai = entry.aiLine?.trim();
    if (ai == null || ai.isEmpty) return false;
    if ((entry.note?.trim().isNotEmpty ?? false)) return false;
    return entry.hasPhotos;
  }

  /// 카드·시트·모아보기 본문 — 사용자 글이 있으면 note, 없으면 AI 일기
  static String? primaryDiaryText(DailyEntry entry) {
    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    if (shouldShowAiLine(entry)) {
      return entry.aiLine!.trim();
    }
    return null;
  }
}
