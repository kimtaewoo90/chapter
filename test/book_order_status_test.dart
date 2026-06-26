import 'package:chapter/models/book_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore status → 표시 단계', () {
    expect(BookOrderStatus.pendingPayment.label, '입금 대기');
    expect(BookOrderStatus.paid.label, '입금 완료');
    expect(BookOrderStatus.fromString('pdf_ready').label, '제작중');
    expect(BookOrderStatus.fromString('shipping').label, '배송중');
    expect(BookOrderStatus.shipped.label, '배송완료');
  });

  test('pdf_ready value 노출', () {
    expect(BookOrderStatus.pdfReady.value, 'pdf_ready');
  });

  test('배송완료·취소는 목록에서 숨김', () {
    expect(BookOrderStatus.shipped.showInBookList, isFalse);
    expect(BookOrderStatus.cancelled.showInBookList, isFalse);
    expect(BookOrderStatus.pdfReady.showInBookList, isTrue);
  });
}
