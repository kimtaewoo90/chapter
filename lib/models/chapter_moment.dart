import 'chapter_model.dart';

/// 피드에 아련하게 보여줄 「쓰여지는 중」 힌트
class ChapterWhisper {
  const ChapterWhisper({
    required this.arcId,
    required this.title,
    required this.message,
  });

  final String arcId;
  final String title;
  final String message;
}

/// 챕터 완성 순간 — 풀스크린 리veal용
class ChapterRevealPayload {
  const ChapterRevealPayload({
    required this.storyArcId,
    required this.title,
    required this.narrative,
    required this.entryCount,
    required this.startDate,
    required this.endDate,
    this.chapter,
  });

  final String storyArcId;
  final String title;
  final String narrative;
  final int entryCount;
  final DateTime startDate;
  final DateTime endDate;
  final ChapterModel? chapter;

  ChapterRevealPayload copyWith({ChapterModel? chapter}) => ChapterRevealPayload(
        storyArcId: storyArcId,
        title: title,
        narrative: narrative,
        entryCount: entryCount,
        startDate: startDate,
        endDate: endDate,
        chapter: chapter ?? this.chapter,
      );
}
