import 'dart:io';

/// 일기 사진 표시용 URI (로컬 파일 우선, 없으면 Storage URL)
class EntryPhotos {
  EntryPhotos._();

  /// 기록 화면 편집용 — local/remote 인덱스를 맞춘 슬롯
  ///
  /// 클라우드에서 내려온 항목은 [localPhotoPaths]가 비어 있고 [remotePhotoUrls]만
  /// 있을 수 있다. 이 경우 URL을 local 슬롯 placeholder로 써서 저장 시 잘리지 않게 한다.
  static ({List<String> localPaths, List<String> remoteUrls}) editSlots({
    required List<String> localPaths,
    required List<String> remoteUrls,
  }) {
    if (localPaths.isNotEmpty) {
      final locals = <String>[];
      final remotes = List<String>.from(remoteUrls);
      while (remotes.length < localPaths.length) {
        remotes.add('');
      }
      if (remotes.length > localPaths.length) {
        remotes.removeRange(localPaths.length, remotes.length);
      }
      for (var i = 0; i < localPaths.length; i++) {
        final local = localPaths[i];
        if (local.isEmpty) continue;
        if (local.startsWith('http')) {
          locals.add(local);
          continue;
        }
        if (_localFileExists(local)) {
          locals.add(local);
          continue;
        }
        if (i < remotes.length && remotes[i].isNotEmpty) {
          locals.add(remotes[i]);
        }
      }
      final alignedRemotes = <String>[];
      for (var i = 0; i < locals.length; i++) {
        final local = locals[i];
        if (local.startsWith('http')) {
          alignedRemotes.add(local);
        } else if (i < remotes.length) {
          alignedRemotes.add(remotes[i]);
        } else {
          alignedRemotes.add('');
        }
      }
      return (localPaths: locals, remoteUrls: alignedRemotes);
    }

    if (remoteUrls.isNotEmpty) {
      return (
        localPaths: List<String>.from(remoteUrls),
        remoteUrls: List<String>.from(remoteUrls),
      );
    }

    return (localPaths: <String>[], remoteUrls: <String>[]);
  }

  /// 저장 직전 — pending·깨진 로컬 경로 정리 + 새 파일 영구 저장
  static Future<List<String>> persistLocalPaths({
    required List<String> localPaths,
    required Future<String> Function(File file) saveLocal,
  }) async {
    final out = <String>[];
    for (final path in localPaths) {
      if (path.isEmpty) {
        out.add('');
        continue;
      }
      if (path.startsWith('http')) {
        out.add(path);
        continue;
      }
      final file = File(path);
      if (!await file.exists()) {
        out.add('');
        continue;
      }
      if (path.contains('/photos/pending/')) {
        out.add(await saveLocal(file));
      } else {
        out.add(path);
      }
    }
    return out;
  }

  /// 빈 로컬 슬롯 제거 시 remote URL 인덱스 유지
  static ({List<String> locals, List<String> remotes}) compactPhotoSlots({
    required List<String> localPaths,
    required List<String> remoteUrls,
  }) {
    final locals = <String>[];
    final remotes = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      final local = localPaths[i];
      if (local.isEmpty) continue;
      locals.add(local);
      final remote = i < remoteUrls.length ? remoteUrls[i] : '';
      if (remote.isNotEmpty) {
        remotes.add(remote);
      } else if (local.startsWith('http')) {
        remotes.add(local);
      } else {
        remotes.add('');
      }
    }
    while (remotes.length < locals.length) {
      remotes.add('');
    }
    return (locals: locals, remotes: remotes);
  }

  /// local 슬롯 수에 맞춰 remote URL 배열 길이 정렬
  static List<String> alignRemoteUrls({
    required List<String> localPaths,
    required List<String> remoteUrls,
  }) {
    final out = List<String>.from(remoteUrls);
    while (out.length < localPaths.length) {
      out.add('');
    }
    if (out.length > localPaths.length) {
      out.removeRange(localPaths.length, out.length);
    }
    return out;
  }

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
