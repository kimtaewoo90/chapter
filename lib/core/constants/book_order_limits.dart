/// 실물 책 주문 — 최소 일기 수
class BookOrderLimits {
  BookOrderLimits._();

  /// TestFlight: 0 — 출시 시 30으로 변경
  static const minDaysToOrder = 0;

  static bool canOrder(int dayCount) => dayCount >= minDaysToOrder;

  static int daysUntilUnlock(int currentDays) =>
      (minDaysToOrder - currentDays).clamp(0, minDaysToOrder);

  static String unlockHint(int currentDays) {
    if (canOrder(currentDays)) return '';
    final remain = daysUntilUnlock(currentDays);
    return '실물 책은 일기 $minDaysToOrder일 이상부터 만들 수 있어요. '
        '($remain일 더 기록해 주세요 · 현재 $currentDays일)';
  }

  static String selectionHint(int selectedCount) =>
      '책에 넣을 일기는 최소 $minDaysToOrder일 이상 선택해 주세요. (현재 $selectedCount일)';
}
