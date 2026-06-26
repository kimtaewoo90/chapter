import 'dart:io';

/// 일기 사진 표시용 URI (로컬 파일 우선, 없으면 Storage URL)
class EntryPhotos {
  EntryPhotos._();

  static List<String> displayUris({
    required List<String> localPaths,
    List<String> remoteUrls = const [],
    /// false면 로컬 경로를 바로 신뢰 (기록 화면 편집 중 UI 지연 방지)
    bool verifyLocalFiles = true,
  }) {
    if (localPaths.isEmpty) {
      return remoteUrls.where((u) => u.isNotEmpty).toList();
    }

    final uris = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      final local = localPaths[i];
      if (local.isEmpty) continue;
      if (local.startsWith('http')) {
        uris.add(local);
      } else if (!verifyLocalFiles || _localFileExists(local)) {
        uris.add(local);
      } else if (i < remoteUrls.length && remoteUrls[i].isNotEmpty) {
        uris.add(remoteUrls[i]);
      }
    }

    if (uris.isEmpty && remoteUrls.isNotEmpty) {
      return remoteUrls.where((u) => u.isNotEmpty).toList();
    }
    return uris;
  }

  static bool _localFileExists(String path) {
    if (path.startsWith('http')) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
