import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/book_entry_snapshot.dart';
import '../models/book_order.dart';
import '../models/daily_entry.dart';

class BookOrderException implements Exception {
  BookOrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// orders/{orderId} — 주문 + 일기 스냅샷
class BookOrderService {
  BookOrderService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  static const hardcoverPrice = 29000;
  static const softcoverPrice = 19000;

  List<BookEntrySnapshot> buildSnapshots(List<DailyEntry> entries) {
    final sorted = List<DailyEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map(BookEntrySnapshot.fromEntry).toList();
  }

  /// 선택 일기 → 스냅샷 → orders 문서 (status: pending_payment)
  Future<BookOrder> createOrder({
    required String userId,
    required List<DailyEntry> entries,
    required String bookTitle,
    required String shippingAddress,
    required String phoneNumber,
    required String recipientName,
    required bool hardcover,
    String? cover,
    String? style,
  }) async {
    if (entries.isEmpty) {
      throw BookOrderException('책에 넣을 일기를 한 개 이상 선택해 주세요.');
    }
    if (shippingAddress.trim().isEmpty) {
      throw BookOrderException('배송 주소를 입력해 주세요.');
    }
    if (phoneNumber.trim().isEmpty) {
      throw BookOrderException('연락처를 입력해 주세요.');
    }
    if (recipientName.trim().isEmpty) {
      throw BookOrderException('받는 분 이름을 입력해 주세요.');
    }

    final snapshots = buildSnapshots(entries);
    final orderId = _uuid.v4();
    final bookId = 'book_${DateTime.now().millisecondsSinceEpoch}';
    final amount = hardcover ? hardcoverPrice : softcoverPrice;

    final order = BookOrder(
      id: orderId,
      userId: userId,
      bookId: bookId,
      bookTitle: bookTitle.trim().isEmpty ? '${DateTime.now().year} 나의 챕터' : bookTitle.trim(),
      amount: amount,
      status: BookOrderStatus.pendingPayment,
      shippingAddress: shippingAddress.trim(),
      phoneNumber: phoneNumber.trim(),
      recipientName: recipientName.trim(),
      snapshots: snapshots,
      cover: cover,
      style: style,
      hardcover: hardcover,
    );

    await _orders.doc(orderId).set(order.toFirestoreCreateMap());
    final saved = await _orders.doc(orderId).get();
    return BookOrder.fromDoc(saved);
  }

  Stream<List<BookOrder>> watchOrdersForUser(String authUid) {
    return _orders
        .where('userId', isEqualTo: authUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookOrder.fromDoc).toList());
  }
}
