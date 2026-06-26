import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/chapter_builder.dart';
import '../core/utils/chapter_segmenter.dart';
import '../models/chapter_model.dart';
import '../models/daily_entry.dart';
import 'local_chapter_service.dart';

class ChapterService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _chapters(String uid) =>
      _db.collection('users').doc(uid).collection('chapters');

  Future<List<ChapterModel>> fetchAllChapters(String uid) async {
    final snap = await _chapters(uid).orderBy('startDate', descending: true).get();
    return snap.docs.map(ChapterModel.fromDoc).toList();
  }

  Stream<List<ChapterModel>> watchChapters(String uid) {
    return _chapters(uid)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChapterModel.fromDoc).toList());
  }

  Future<void> replaceCompletedChapters(
    String uid,
    List<CompletedChapterDraft> drafts,
  ) async {
    final snap = await _chapters(uid).get();
    final prevByKey = <String, String>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final start = (d['startDate'] as Timestamp?)?.toDate();
      final end = (d['endDate'] as Timestamp?)?.toDate();
      if (start == null || end == null) continue;
      final key = '${DailyEntry.dateKeyFrom(start)}_${DailyEntry.dateKeyFrom(end)}';
      prevByKey[key] = doc.id;
    }

    final batch = _db.batch();
    final keepIds = <String>{};

    for (final draft in drafts) {
      final segment = ChapterSegment(entries: draft.entries, isComplete: true);
      final model = ChapterBuilder.fromSegment(
        uid: uid,
        segment: segment,
        title: draft.title,
        narrative: draft.narrative,
        preserveId: prevByKey[draft.dateRangeKey],
        storyArcId: draft.storyArcId,
        category: draft.category,
      );
      final docId = prevByKey[draft.dateRangeKey] ?? model.id;
      keepIds.add(docId);
      batch.set(_chapters(uid).doc(docId), {
        ...model.toMap(),
        'dateRangeKey': draft.dateRangeKey,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!prevByKey.containsKey(draft.dateRangeKey)) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final doc in snap.docs) {
      if (!keepIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  Future<void> updateChapterTitle(String uid, String chapterId, String title) async {
    await _chapters(uid).doc(chapterId).update({'title': title});
  }
}
