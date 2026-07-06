import '../core/utils/monthly_review_period.dart';
import 'monthly_review_digest.dart';

/// 캘린더 월 단위 월간 리포트
class MonthlyReview {
  const MonthlyReview({
    required this.periodKey,
    required this.periodLabel,
    required this.generatedAt,
    required this.topTopics,
    required this.summary,
    required this.growth,
    this.revealedAt,
    this.emotionTrend = '',
    this.chapterChanges = const [],
    this.digest,
    this.sourceEntryHash,
  });

  final String periodKey;
  final String periodLabel;
  final DateTime generatedAt;
  final DateTime? revealedAt;
  final List<String> topTopics;
  final String summary;
  final String growth;
  final String emotionTrend;
  final List<String> chapterChanges;
  final MonthlyReviewDigest? digest;
  /// 생성 시점 일기 fingerprint — 이후 수정 감지용
  final String? sourceEntryHash;

  bool get wasRevealed => revealedAt != null;

  /// 리스트·reveal 미리보기용 한 줄
  String get previewLine {
    if (digest != null && digest!.factSummary.isNotEmpty) return digest!.factSummary;
    return summary;
  }

  MonthlyReview copyWith({
    String? periodKey,
    String? periodLabel,
    DateTime? generatedAt,
    DateTime? revealedAt,
    List<String>? topTopics,
    String? summary,
    String? growth,
    String? emotionTrend,
    List<String>? chapterChanges,
    MonthlyReviewDigest? digest,
    String? sourceEntryHash,
  }) =>
      MonthlyReview(
        periodKey: periodKey ?? this.periodKey,
        periodLabel: periodLabel ?? this.periodLabel,
        generatedAt: generatedAt ?? this.generatedAt,
        revealedAt: revealedAt ?? this.revealedAt,
        topTopics: topTopics ?? this.topTopics,
        summary: summary ?? this.summary,
        growth: growth ?? this.growth,
        emotionTrend: emotionTrend ?? this.emotionTrend,
        chapterChanges: chapterChanges ?? this.chapterChanges,
        digest: digest ?? this.digest,
        sourceEntryHash: sourceEntryHash ?? this.sourceEntryHash,
      );

  Map<String, dynamic> toJson() => {
        'periodKey': periodKey,
        'periodLabel': periodLabel,
        'generatedAt': generatedAt.toIso8601String(),
        'revealedAt': revealedAt?.toIso8601String(),
        'topTopics': topTopics,
        'summary': summary,
        'growth': growth,
        'emotionTrend': emotionTrend,
        'chapterChanges': chapterChanges,
        if (digest != null) 'digest': digest!.toJson(),
        if (sourceEntryHash != null && sourceEntryHash!.isNotEmpty)
          'sourceEntryHash': sourceEntryHash,
      };

  factory MonthlyReview.fromJson(Map<String, dynamic> json) {
    final generatedAt =
        DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now();
    var periodKey = json['periodKey'] as String? ?? '';
    var periodLabel = json['periodLabel'] as String? ?? '';

    if (periodKey.isEmpty) {
      periodKey = MonthlyReviewPeriod.periodKeyFromDate(generatedAt);
    }
    if (periodLabel.isEmpty) {
      periodLabel = MonthlyReviewPeriod.periodLabelFromDate(generatedAt);
    }

    MonthlyReviewDigest? digest;
    final digestRaw = json['digest'];
    if (digestRaw is Map) {
      digest = MonthlyReviewDigest.fromJson(Map<String, dynamic>.from(digestRaw));
    }

    return MonthlyReview(
      periodKey: periodKey,
      periodLabel: periodLabel,
      generatedAt: generatedAt,
      revealedAt: json['revealedAt'] != null
          ? DateTime.tryParse(json['revealedAt'] as String)
          : null,
      topTopics: _parseStringList(json['topTopics']),
      summary: json['summary'] as String? ?? '',
      growth: json['growth'] as String? ?? '',
      emotionTrend: json['emotionTrend'] as String? ?? '',
      chapterChanges: _parseStringList(json['chapterChanges']),
      digest: digest,
      sourceEntryHash: json['sourceEntryHash'] as String?,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
