import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/book_cover_date_range.dart';
import 'book_entry_snapshot.dart';

/// Firestore `orders.status` 값
enum BookOrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  pdfReady('pdf_ready'),
  shipping('shipping'),
  /// 레거시 — 제작중으로 표시
  processing('processing'),
  printed('printed'),
  shipped('shipped'),
  cancelled('cancelled');

  const BookOrderStatus(this.value);
  final String value;

  static BookOrderStatus fromString(String? raw) {
    if (raw == null || raw.isEmpty) return BookOrderStatus.pendingPayment;
    return BookOrderStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => BookOrderStatus.pendingPayment,
    );
  }

  /// 앱에 보여줄 단계 (5단계)
  String get label => switch (displayStep) {
        0 => '입금 대기',
        1 => '입금 완료',
        2 => '제작중',
        3 => '배송중',
        4 => '배송완료',
        _ => '취소됨',
      };

  /// 0~4: 진행 단계, -1: 취소
  int get displayStep => switch (this) {
        BookOrderStatus.pendingPayment => 0,
        BookOrderStatus.paid => 1,
        BookOrderStatus.pdfReady ||
        BookOrderStatus.processing ||
        BookOrderStatus.printed =>
          2,
        BookOrderStatus.shipping => 3,
        BookOrderStatus.shipped => 4,
        BookOrderStatus.cancelled => -1,
      };

  /// 내 책 목록에 표시 (배송완료·취소 제외)
  bool get showInBookList =>
      this != BookOrderStatus.shipped && this != BookOrderStatus.cancelled;

  bool get isDelivered => this == BookOrderStatus.shipped;
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
    required this.recipientName,
    required this.snapshots,
    this.createdAt,
    this.cover,
    this.coverPhotoUrl,
    this.coverTitle,
    this.style,
    this.hardcover = true,
    this.pdfStoragePath,
    this.diaryFontId,
  });

  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final int amount;
  final BookOrderStatus status;
  final String shippingAddress;
  final String phoneNumber;
  final String recipientName;
  final List<BookEntrySnapshot> snapshots;
  final DateTime? createdAt;
  final String? cover;
  final String? coverPhotoUrl;
  final String? coverTitle;
  final String? style;
  final bool hardcover;
  final String? pdfStoragePath;
  /// 주문 시점 일기 본문 폰트 (`AppFontId.name`)
  final String? diaryFontId;

  int get pageCount => snapshots.length;

  /// 목록·앱바용 — 표지 제목 없으면 일기 기간(yyyy.MM - yyyy.MM)
  String get displayTitle {
    final cover = coverTitle?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    final book = bookTitle.trim();
    if (book.isNotEmpty) return book;
    final range = bookCoverDateRangeFromSnapshots(snapshots);
    if (range.isNotEmpty) return range;
    return '내 책';
  }

  /// Firestore에 저장된 status 문자열
  String get statusValue => status.value;

  Map<String, dynamic> toFirestoreCreateMap() => {
        'userId': userId,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'amount': amount,
        'status': status.value,
        'shippingAddress': shippingAddress,
        'recipientName': recipientName,
        '전화번호': phoneNumber,
        'snapshots': snapshots.map((s) => s.toFirestoreMap()).toList(),
        'cover': cover,
        'coverPhotoUrl': coverPhotoUrl,
        'coverTitle': coverTitle,
        'style': style,
        'hardcover': hardcover,
        'diaryFontId': diaryFontId,
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
      recipientName: (d['recipientName'] ?? d['receiverName'])?.toString() ?? '',
      snapshots: snapshots,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      cover: d['cover'] as String?,
      coverPhotoUrl: d['coverPhotoUrl'] as String?,
      coverTitle: d['coverTitle'] as String?,
      style: d['style'] as String?,
      hardcover: d['hardcover'] as bool? ?? true,
      pdfStoragePath: d['pdfStoragePath'] as String?,
      diaryFontId: d['diaryFontId'] as String?,
    );
  }

  static List<BookEntrySnapshot> _legacySingleSnapshot(Map<String, dynamic> d) {
    final single = d['snapshot'];
    if (single is! Map) return const [];
    return [BookEntrySnapshot.fromMap(Map<String, dynamic>.from(single))];
  }
}
