import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_entry.dart';

/// Firestore: users/{uid}/entries/{yyyy-MM-dd} — 하루 문서 1개
class EntryService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _db.collection('users').doc(uid).collection('entries');

  Stream<List<DailyEntry>> watchEntries(String uid) {
    return _entries(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DailyEntry.fromDoc).toList());
  }

  /// 다른 기기 복구 — Firestore 전체 1회 조회
  Future<List<DailyEntry>> fetchAllEntries(String uid) async {
    final snap = await _entries(uid).orderBy('date', descending: true).get();
    return snap.docs.map(DailyEntry.fromDoc).toList();
  }

  Future<DailyEntry?> getEntryForDate(String uid, DateTime date) async {
    final doc = await _entries(uid).doc(DailyEntry.dateKeyFrom(date)).get();
    if (!doc.exists) return null;
    return DailyEntry.fromDoc(doc);
  }

  /// 로컬과 동일한 [DailyEntry]를 날짜 키 문서에 저장 (사진 URL·글 포함)
  Future<DailyEntry> saveEntry(DailyEntry entry) async {
    final docId = entry.dateKey;
    final ref = _entries(entry.userId).doc(docId);
    final existing = await ref.get();

    final data = Map<String, dynamic>.from(entry.toFirestoreMap())
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (entry.note == null || entry.note!.trim().isEmpty) {
      data['note'] = FieldValue.delete();
    } else {
      data['note'] = entry.note!.trim();
    }

    if (entry.aiLine == null || entry.aiLine!.trim().isEmpty) {
      data['aiLine'] = FieldValue.delete();
    } else {
      data['aiLine'] = entry.aiLine!.trim();
    }

    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
    final doc = await ref.get();
    return DailyEntry.fromDoc(doc);
  }

  Future<DailyEntry?> getOneYearAgo(String uid, DateTime today) async {
    final past = DateTime(today.year - 1, today.month, today.day);
    return getEntryForDate(uid, past);
  }

  /// 로컬에만 있던 기록을 Firestore로 최초 업로드
  Future<void> uploadAll(String uid, List<DailyEntry> entries) async {
    if (entries.isEmpty) return;
    final batch = _db.batch();
    for (final entry in entries) {
      if (entry.userId != uid) continue;
      final ref = _entries(uid).doc(entry.dateKey);
      batch.set(
        ref,
        {
          ...entry.toFirestoreMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
