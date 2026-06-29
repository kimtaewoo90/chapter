import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage: testUser/{userId}/{yyyy-MM-dd}/{filename}.jpg
class PhotoStorageService {
  final _storage = FirebaseStorage.instance;

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<String?> uploadLocalPhoto({
    required File file,
    required String userId,
    required DateTime date,
  }) async {
    try {
      final day = dateKey(date);
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('testUser/$userId/$day/$name');
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return ref.getDownloadURL();
    } catch (e, st) {
      debugPrint('PhotoStorageService upload failed: $e\n$st');
      return null;
    }
  }

  /// 로컬 경로와 **같은 인덱스**의 remote URL — 경로가 바뀌면 해당 슬롯 재업로드
  Future<List<String>> syncRemotePhotoUrls({
    required String userId,
    required List<String> localPaths,
    required List<String> existingRemoteUrls,
    required DateTime date,
    List<String> previousLocalPaths = const [],
  }) async {
    final urls = List<String>.from(existingRemoteUrls);
    while (urls.length < localPaths.length) {
      urls.add('');
    }
    if (urls.length > localPaths.length) {
      urls.removeRange(localPaths.length, urls.length);
    }

    for (var i = 0; i < localPaths.length; i++) {
      final path = localPaths[i];
      if (path.startsWith('http')) {
        urls[i] = path;
        continue;
      }

      final pathChanged = i >= previousLocalPaths.length || previousLocalPaths[i] != path;
      if (pathChanged) {
        urls[i] = '';
      }

      if (urls[i].isNotEmpty) {
        continue;
      }

      final file = File(path);
      if (!await file.exists()) {
        if (urls[i].isEmpty &&
            i < existingRemoteUrls.length &&
            existingRemoteUrls[i].isNotEmpty) {
          urls[i] = existingRemoteUrls[i];
        }
        continue;
      }

      final url = await uploadLocalPhoto(file: file, userId: userId, date: date);
      if (url != null) {
        urls[i] = url;
      }
    }

    return urls;
  }

}
