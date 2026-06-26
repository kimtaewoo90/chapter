import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_entry_snapshot.dart';

/// 실물 책 주문 상태
enum BookOrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  processing('processing'),
  printed('printed'),
  shipped('shipped'),
  cancelled('cancelled');

  const BookOrderStatus(this.value);
  final String value;

  static BookOrderStatus fromString(String? raw) {
    return BookOrderStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => BookOrderStatus.pendingPayment,
    );
  }

  String get label => switch (this) {
        BookOrderStatus.pendingPayment => '입금 대기',
        BookOrderStatus.paid => '입금 확인',
        BookOrderStatus.processing => '제작 중',
        BookOrderStatus.printed => '인쇄 완료',
        BookOrderStatus.shipped => '배송 중',
        BookOrderStatus.cancelled => '취소됨',
      };
}

class BookOrder {
  const BookOrder({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.amount,
    required this.status,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.snapshots,
    this.createdAt,
    this.cover,
    this.style,
    this.hardcover = true,
    this.pdfStoragePath,
  });

  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final int amount;
  final BookOrderStatus status;
  final String shippingAddress;
  final String phoneNumber;
  final List<BookEntrySnapshot> snapshots;
  final DateTime? createdAt;
  final String? cover;
  final String? style;
  final bool hardcover;
  final String? pdfStoragePath;

  int get pageCount => snapshots.length;

  Map<String, dynamic> toFirestoreCreateMap() => {
        'userId': userId,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'amount': amount,
        'status': status.value,
        'shippingAddress': shippingAddress,
        '전화번호': phoneNumber,
        'snapshots': snapshots.map((s) => s.toFirestoreMap()).toList(),
        'cover': cover,
        'style': style,
        'hardcover': hardcover,
        'pageCount': snapshots.length,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory BookOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawSnapshots = d['snapshots'] as List<dynamic>?;
    final snapshots = rawSnapshots
            ?.map((e) => BookEntrySnapshot.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        _legacySingleSnapshot(d);

    return BookOrder(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      bookId: d['bookId'] as String? ?? '',
      bookTitle: d['bookTitle'] as String? ?? '',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      status: BookOrderStatus.fromString(d['status'] as String?),
      shippingAddress: d['shippingAddress'] as String? ?? '',
      phoneNumber: (d['전화번호'] ?? d['phoneNumber'])?.toString() ?? '',
      snapshots: snapshots,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      cover: d['cover'] as String?,
      style: d['style'] as String?,
      hardcover: d['hardcover'] as bool? ?? true,
      pdfStoragePath: d['pdfStoragePath'] as String?,
    );
  }

  /// 예전 테스트 문서 — snapshot 단일 맵 호환
  static List<BookEntrySnapshot> _legacySingleSnapshot(Map<String, dynamic> d) {
    final single = d['snapshot'];
    if (single is! Map) return const [];
    return [BookEntrySnapshot.fromMap(Map<String, dynamic>.from(single))];
  }
}
