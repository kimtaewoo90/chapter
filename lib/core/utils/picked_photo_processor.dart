import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 갤러리·카메라 선택 — 용량 제한 + 앱 저장소로 복사 (임시 파일 삭제 방지)
class PickedPhotoProcessor {
  PickedPhotoProcessor._();

  static const double maxWidth = 2048;
  static const double maxHeight = 2048;
  static const int imageQuality = 88;

  static Future<File?> stage(XFile picked) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pending = Directory('${dir.path}/photos/pending');
      if (!await pending.exists()) {
        await pending.create(recursive: true);
      }
      final destPath = '${pending.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // iOS 갤러리 경로는 File.exists()가 false일 수 있어 XFile에서 직접 읽는다.
      final raw = await picked.readAsBytes();
      if (raw.isEmpty) return null;
      final bytes = raw.length > 2 * 1024 * 1024
          ? await compute(_compressJpeg, raw)
          : raw;
      final dest = File(destPath);
      await dest.writeAsBytes(bytes, flush: true);
      return dest;
    } catch (e, st) {
      debugPrint('PickedPhotoProcessor.stage failed: $e\n$st');
      return null;
    }
  }

  static Uint8List _compressJpeg(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    const maxEdge = 2048;
    final w = decoded.width;
    final h = decoded.height;
    final edge = w > h ? w : h;
    final resized = edge > maxEdge
        ? img.copyResize(
            decoded,
            width: (w * maxEdge / edge).round(),
            height: (h * maxEdge / edge).round(),
          )
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
