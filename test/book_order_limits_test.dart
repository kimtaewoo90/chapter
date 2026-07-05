import 'package:chapter/core/constants/book_order_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TestFlight: 0일부터 주문 가능', () {
    expect(BookOrderLimits.canOrder(0), isTrue);
    expect(BookOrderLimits.canOrder(1), isTrue);
    expect(BookOrderLimits.daysUntilUnlock(0), 0);
  });
}
