import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chapter_photo_image.dart';

/// 일기 사진 전체화면 — 좌우 슬라이드, 아래로 스와이프해 닫기
Future<void> showEntryPhotoViewer(
  BuildContext context, {
  required List<String> uris,
  int initialIndex = 0,
}) {
  if (uris.isEmpty) return Future.value();
  final index = initialIndex.clamp(0, uris.length - 1);
  HapticFeedback.selectionClick();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => EntryPhotoViewer(uris: uris, initialIndex: index),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class EntryPhotoViewer extends StatefulWidget {
  const EntryPhotoViewer({
    super.key,
    required this.uris,
    this.initialIndex = 0,
  });

  final List<String> uris;
  final int initialIndex;

  @override
  State<EntryPhotoViewer> createState() => _EntryPhotoViewerState();
}

class _EntryPhotoViewerState extends State<EntryPhotoViewer> {
  late final PageController _pageController;
  late int _page;
  final _transformController = TransformationController();
  double _dismissDy = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex.clamp(0, widget.uris.length - 1);
    _pageController = PageController(initialPage: _page);
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    if (mounted) setState(() {});
  }

  bool get _isZoomed => _transformController.value.getMaxScaleOnAxis() > 1.02;

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() => _dismissDy += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) {
      setState(() => _dismissDy = 0);
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldDismiss = _dismissDy > 110 || velocity > 720;
    if (shouldDismiss) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _dismissDy = 0);
  }

  File? _fileForUri(String uri) {
    if (uri.startsWith('http')) return null;
    final path = uri.startsWith('file://') ? uri.replaceFirst('file://', '') : uri;
    if (path.startsWith('/')) return File(path);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final progress = (_dismissDy.abs() / math.max(size.height * 0.35, 220)).clamp(0.0, 1.0);
    final backdrop = (1.0 - progress * 0.55).clamp(0.0, 1.0);
    final scale = (1.0 - progress * 0.06).clamp(0.9, 1.0);

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: backdrop),
        body: SafeArea(
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, _dismissDy),
                child: Transform.scale(
                  scale: scale,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.uris.length,
                    physics: widget.uris.length > 1
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() {
                        _page = i;
                        _dismissDy = 0;
                      });
                      _resetZoom();
                    },
                    itemBuilder: (context, index) {
                      final uri = widget.uris[index];
                      final isCurrent = index == _page;
                      return InteractiveViewer(
                        transformationController: isCurrent ? _transformController : null,
                        minScale: 1,
                        maxScale: 3.2,
                        panEnabled: isCurrent && _isZoomed,
                        scaleEnabled: isCurrent,
                        child: Center(
                          child: ChapterPhotoImage(
                            file: _fileForUri(uri),
                            uri: uri,
                            width: size.width,
                            height: size.height,
                            fit: BoxFit.contain,
                            fullResolution: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: '닫기',
                    ),
                    const Spacer(),
                    if (widget.uris.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_page + 1} / ${widget.uris.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
