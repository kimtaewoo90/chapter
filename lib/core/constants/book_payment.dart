/// 실물 책 주문 — 계좌이체 안내 (운영 시 이 파일만 수정)
class BookPaymentInfo {
  BookPaymentInfo._();

  static const bankName = '신한은행';
  static const accountNumber = '110455485341';
  static const accountHolder = '김보미';

  static String accountLabel() => '$bankName $accountNumber';
}
