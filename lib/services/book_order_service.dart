import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/book_order_limits.dart';
import '../models/book_entry_snapshot.dart';
import '../models/book_order.dart';
import '../models/daily_entry.dart';
import '../services/photo_storage_service.dart';

class BookOrderException implements Exception {
  BookOrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// orders/{orderId} — 주문 + 일기 스냅샷
class BookOrderService {
  BookOrderService({
    FirebaseFirestore? db,
    PhotoStorageService? photos,
  })  : _db = db ?? FirebaseFirestore.instance,
        _photos = photos ?? PhotoStorageService();

  final FirebaseFirestore _db;
  final PhotoStorageService _photos;
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

  /// 로컬 사진만 있고 Storage URL이 없으면 업로드 후 스냅샷 생성
  Future<List<DailyEntry>> ensurePrintablePhotoEntries({
    required String userId,
    required List<DailyEntry> entries,
  }) async {
    final out = <DailyEntry>[];

    for (final entry in entries) {
      if (entry.localPhotoPaths.isEmpty) {
        out.add(entry);
        continue;
      }

      final remotes = List<String>.from(entry.remotePhotoUrls);
      while (remotes.length < entry.localPhotoPaths.length) {
        remotes.add('');
      }

      var changed = false;
      for (var i = 0; i < entry.localPhotoPaths.length; i++) {
        final existing = i < remotes.length ? remotes[i] : '';
        if (existing.startsWith('http://') || existing.startsWith('https://')) {
          continue;
        }

        final path = entry.localPhotoPaths[i];
        if (path.startsWith('http://') || path.startsWith('https://')) {
          remotes[i] = path;
          changed = true;
          continue;
        }

        final file = File(path);
        if (!await file.exists()) continue;

        final url = await _photos.uploadLocalPhoto(
          file: file,
          userId: userId,
          date: entry.date,
        );
        if (url != null) {
          remotes[i] = url;
          changed = true;
        }
      }

      out.add(changed ? entry.copyWith(remotePhotoUrls: remotes) : entry);
    }

    return out;
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
    String? coverPhotoUrl,
    String? coverTitle,
    String? style,
    String? diaryFontId,
  }) async {
    if (entries.length < BookOrderLimits.minDaysToOrder) {
      throw BookOrderException(
        '실물 책은 일기 ${BookOrderLimits.minDaysToOrder}일 이상 선택해야 해요.',
      );
    }
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

    final printableEntries = await ensurePrintablePhotoEntries(
      userId: userId,
      entries: entries,
    );
    final snapshots = buildSnapshots(printableEntries);
    final orderId = _uuid.v4();
    final bookId = 'book_${DateTime.now().millisecondsSinceEpoch}';
    final amount = hardcover ? hardcoverPrice : softcoverPrice;

    final order = BookOrder(
      id: orderId,
      userId: userId,
      bookId: bookId,
      bookTitle: bookTitle.trim(),
      amount: amount,
      status: BookOrderStatus.pendingPayment,
      shippingAddress: shippingAddress.trim(),
      phoneNumber: phoneNumber.trim(),
      recipientName: recipientName.trim(),
      snapshots: snapshots,
      cover: cover,
      coverPhotoUrl: coverPhotoUrl,
      coverTitle: coverTitle?.trim().isEmpty == true ? null : coverTitle?.trim(),
      style: style,
      hardcover: hardcover,
      diaryFontId: diaryFontId,
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
