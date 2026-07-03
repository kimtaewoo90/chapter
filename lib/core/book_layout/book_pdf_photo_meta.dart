import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'book_sticker_collage.dart';

/// chapter_admin PDF — sharp().rotate() 와 동일한 표시 방향 기준 메타
class BookPdfPhotoMeta {
  BookPdfPhotoMeta._();

  static const fallback = BookImageMeta(width: 4, height: 3);

  static final Map<String, BookImageMeta> _cache = {};

  static Future<void> preload(Iterable<String> uris) async {
    await resolveAll(uris.where((u) => u.isNotEmpty).toList());
  }

  static BookImageMeta? cached(String uri) => _cache[uri];

  static Future<BookImageMeta?> resolve(String uri) async {
    if (uri.isEmpty) return null;
    if (_cache.containsKey(uri)) return _cache[uri];

    try {
      final bytes = await _readBytes(uri);
      if (bytes == null) return null;

      final meta = await _decodeMeta(bytes);
      if (meta == null) return null;

      _cache[uri] = meta;
      return meta;
    } catch (_) {
      return null;
    }
  }

  static Future<BookImageMeta> resolveCached(String uri) async {
    return await resolve(uri) ?? fallback;
  }

  static Future<List<BookImageMeta>> resolveAll(List<String> uris) async {
    if (uris.isEmpty) return const [];
    return Future.wait(uris.map(resolveCached));
  }

  /// Flutter Image / PDFKit 과 같은 EXIF 반영 크기
  static Future<BookImageMeta?> _decodeMeta(Uint8List bytes) async {
    ui.Image? image;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      if (image.width > 0 && image.height > 0) {
        return BookImageMeta(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
        );
      }
    } catch (_) {
      // Flutter 코덱 미지원 포맷 → image 패키지 + EXIF 보정
    } finally {
      image?.dispose();
    }

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        return null;
      }
      final oriented = img.bakeOrientation(decoded);
      return BookImageMeta(
        width: oriented.width.toDouble(),
        height: oriented.height.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _readBytes(String uri) async {
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode != 200) return null;
      return Uint8List.fromList(response.bodyBytes);
    }

    final path = uri.startsWith('file://') ? uri.substring(7) : uri;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}

/// chapter_admin `imagePrep.fitImageSize`
({double width, double height}) fitPdfImageSize({
  required double imageWidth,
  required double imageHeight,
  required double maxW,
  required double maxH,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) {
    return (width: maxW, height: maxH);
  }
  final scale = (maxW / imageWidth) < (maxH / imageHeight)
      ? maxW / imageWidth
      : maxH / imageHeight;
  return (width: imageWidth * scale, height: imageHeight * scale);
}
