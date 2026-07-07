import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import 'chapter_photo_image.dart';
import 'record_photo_picker_sheet.dart';

/// 오늘의 사진 — 겹친 스택 미리보기, 탭하면 그리드 시트
class TodayPhotoSection extends StatelessWidget {
  const TodayPhotoSection({
    super.key,
    required this.displayUris,
    required this.newPhotoFiles,
    this.maxPhotos = 3,
    this.isPickingPhotos = false,
    required this.onPickMultiple,
    required this.onPickCamera,
    required this.onRemoveDisplay,
    required this.onRemoveNew,
    required this.onReorderCombined,
  });

  final List<String> displayUris;
  final List<File> newPhotoFiles;
  final int maxPhotos;
  final bool isPickingPhotos;
  final VoidCallback onPickMultiple;
  final VoidCallback onPickCamera;
  final ValueChanged<String> onRemoveDisplay;
  final ValueChanged<int> onRemoveNew;
  final void Function(List<String> reorderedDisplayUris, List<File> reorderedNewFiles) onReorderCombined;

  List<_TodayPhotoEntry> get _entries => [
        ...displayUris.map((u) => _TodayPhotoEntry.display(u)),
        ...newPhotoFiles.map((f) => _TodayPhotoEntry.local(f)),
      ];

  bool get _canAddMore => _entries.length < maxPhotos;

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (entries.isEmpty) {
      return _EmptyTodayCut(
        isPickingPhotos: isPickingPhotos,
        canAddMore: _canAddMore,
        onAdd: () => showRecordPhotoSourceSheet(
          context,
          onGallery: onPickMultiple,
          onCamera: onPickCamera,
        ),
      );
    }

    return _PhotoStackPreview(
      entries: entries,
      maxPhotos: maxPhotos,
      canAddMore: _canAddMore,
      isPickingPhotos: isPickingPhotos,
      onTapOpen: () => _openGallerySheet(context, entries),
      onAdd: () => showRecordPhotoSourceSheet(
        context,
        onGallery: onPickMultiple,
        onCamera: onPickCamera,
      ),
    );
  }

  void _openGallerySheet(BuildContext context, List<_TodayPhotoEntry> entries) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TodayPhotoGallerySheet(
        entries: entries,
        maxPhotos: maxPhotos,
        canAddMore: _canAddMore,
        onAddMore: () => showRecordPhotoSourceSheet(
          context,
          onGallery: onPickMultiple,
          onCamera: onPickCamera,
        ),
        onRemoveDisplay: onRemoveDisplay,
        onRemoveNew: onRemoveNew,
        onReorderCombined: onReorderCombined,
      ),
    );
  }
}

class _TodayPhotoEntry {
  const _TodayPhotoEntry.display(this.uri)
      : file = null,
        isNew = false;

  const _TodayPhotoEntry.local(this.file)
      : uri = null,
        isNew = true;

  final String? uri;
  final File? file;
  final bool isNew;

  String get key => isNew ? 'n_${file!.path}' : 'd_$uri';
}

/// 사진 없을 때 — 스택 영역 중앙에 「오늘의 컷」 폴라로이드
class _EmptyTodayCut extends StatelessWidget {
  const _EmptyTodayCut({
    required this.onAdd,
    this.isPickingPhotos = false,
    this.canAddMore = true,
  });

  final VoidCallback onAdd;
  final bool isPickingPhotos;
  final bool canAddMore;

  @override
  Widget build(BuildContext context) {
    return _TodayPhotoStackFrame(
      onTap: canAddMore ? onAdd : null,
      onAdd: canAddMore ? onAdd : null,
      canAddMore: canAddMore,
      isPickingPhotos: isPickingPhotos,
      child: const Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [_PolaroidAddPlaceholder()],
      ),
    );
  }
}

/// 겹친 폴라로이드 스택
class _PhotoStackPreview extends StatelessWidget {
  const _PhotoStackPreview({
    required this.entries,
    required this.onTapOpen,
    required this.onAdd,
    required this.maxPhotos,
    this.canAddMore = true,
    this.isPickingPhotos = false,
  });

  final List<_TodayPhotoEntry> entries;
  final VoidCallback onTapOpen;
  final VoidCallback onAdd;
  final int maxPhotos;
  final bool canAddMore;
  final bool isPickingPhotos;

  static const _offsets = [
    Offset(-14, 6),
    Offset(10, -4),
    Offset(0, 0),
  ];
  static const _rotations = [-0.07, 0.05, 0.0];

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    final visible = count <= 3 ? entries : entries.sublist(count - 3);

    return _TodayPhotoStackFrame(
      onTap: onTapOpen,
      onAdd: canAddMore ? onAdd : null,
      canAddMore: canAddMore,
      isPickingPhotos: isPickingPhotos,
      badge: count > 1
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count/$maxPhotos장 · 탭해서 삭제·순서',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            _PolaroidTile(
              entry: visible[i],
              offset: _offsets[i],
              rotation: _rotations[i],
              elevation: i.toDouble(),
            ),
        ],
      ),
    );
  }
}

/// 사진 있을 때/없을 때 공통 외곽·중앙 스택·+ 버튼
class _TodayPhotoStackFrame extends StatelessWidget {
  const _TodayPhotoStackFrame({
    required this.onTap,
    required this.onAdd,
    required this.child,
    this.badge,
    this.canAddMore = true,
    this.isPickingPhotos = false,
  });

  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final Widget child;
  final Widget? badge;
  final bool canAddMore;
  final bool isPickingPhotos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.paperDark),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 118,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              left: 16,
              bottom: 12,
              child: badge!,
            ),
          if (canAddMore)
            Positioned(
              right: 12,
              bottom: 12,
              child: _AddPhotoFab(onTap: isPickingPhotos ? null : onAdd),
            ),
          if (isPickingPhotos)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accent),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPhotoFab extends StatelessWidget {
  const _AddPhotoFab({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.accent,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// 빈 상태 폴라로이드 — 사진 1장일 때와 같은 크기·위치
class _PolaroidAddPlaceholder extends StatelessWidget {
  const _PolaroidAddPlaceholder();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stamp = '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return _PolaroidFrame(
      offset: Offset.zero,
      rotation: 0,
      elevation: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: AppTheme.accent.withValues(alpha: 0.9), size: 26),
          const SizedBox(height: 6),
          const Text('오늘의 컷', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            stamp,
            style: TextStyle(fontSize: 9, color: AppTheme.inkMuted.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 5),
          Text(
            '탭해서 추가',
            style: TextStyle(fontSize: 8, color: AppTheme.accent.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PolaroidFrame extends StatelessWidget {
  const _PolaroidFrame({
    required this.offset,
    required this.rotation,
    required this.elevation,
    required this.child,
  });

  final Offset offset;
  final double rotation;
  final double elevation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.paperDark),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.12 + elevation * 0.04),
                blurRadius: 10 + elevation * 4,
                offset: Offset(0, 3 + elevation * 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PolaroidTile extends StatelessWidget {
  const _PolaroidTile({
    required this.entry,
    required this.offset,
    required this.rotation,
    required this.elevation,
  });

  final _TodayPhotoEntry entry;
  final Offset offset;
  final double rotation;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return _PolaroidFrame(
      offset: offset,
      rotation: rotation,
      elevation: elevation,
      child: ChapterPhotoImage(
        file: entry.file,
        uri: entry.uri,
        width: 96,
        height: 96,
      ),
    );
  }
}

/// 그리드 + 순서 변경 + 확대 보기
class _TodayPhotoGallerySheet extends StatefulWidget {
  const _TodayPhotoGallerySheet({
    required this.entries,
    required this.onAddMore,
    required this.onRemoveDisplay,
    required this.onRemoveNew,
    required this.onReorderCombined,
    required this.maxPhotos,
    this.canAddMore = true,
  });

  final List<_TodayPhotoEntry> entries;
  final VoidCallback onAddMore;
  final ValueChanged<String> onRemoveDisplay;
  final ValueChanged<int> onRemoveNew;
  final void Function(List<String> reorderedDisplayUris, List<File> reorderedNewFiles) onReorderCombined;
  final int maxPhotos;
  final bool canAddMore;

  @override
  State<_TodayPhotoGallerySheet> createState() => _TodayPhotoGallerySheetState();
}

class _TodayPhotoGallerySheetState extends State<_TodayPhotoGallerySheet> {
  bool _reorderMode = false;
  late List<_TodayPhotoEntry> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.entries);
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _PhotoViewerPage(
          entries: _items,
          initialIndex: initialIndex,
          onDelete: (index) => _removeAt(index, closeViewer: true),
        ),
      ),
    );
  }

  void _removeAt(int index, {bool closeViewer = false}) {
    final e = _items[index];
    if (e.isNew) {
      var newIdx = 0;
      for (var i = 0; i < index; i++) {
        if (_items[i].isNew) newIdx++;
      }
      widget.onRemoveNew(newIdx);
    } else {
      widget.onRemoveDisplay(e.uri!);
    }
    setState(() {
      _items.removeAt(index);
    });
    if (closeViewer && mounted) {
      Navigator.of(context).pop();
    }
    if (_items.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('오늘의 장면', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${_items.length}/${widget.maxPhotos}장 · ✕로 삭제',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _reorderMode = !_reorderMode),
                    icon: Icon(_reorderMode ? Icons.grid_view_rounded : Icons.swap_vert_rounded, size: 18),
                    label: Text(_reorderMode ? '격자 보기' : '순서 변경'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _reorderMode ? _reorderList() : _photoGrid(),
            ),
            if (widget.canAddMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onAddMore();
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: const Text('사진 추가'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  '하루 최대 ${widget.maxPhotos}장까지 담을 수 있어요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final e = _items[index];
        return _GridPhotoTile(
          entry: e,
          onTap: () => _openViewer(index),
          onRemove: () => _removeAt(index),
        );
      },
    );
  }

  Widget _reorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      buildDefaultDragHandles: true,
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        setState(() {
          final moved = _items.removeAt(oldIndex);
          _items.insert(newIndex, moved);
        });
        widget.onReorderCombined(
          [for (final e in _items) if (!e.isNew) e.uri!],
          [for (final e in _items) if (e.isNew) e.file!],
        );
      },
      itemBuilder: (context, index) {
        final e = _items[index];
        return ListTile(
          key: ValueKey(e.key),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ChapterPhotoImage(
              file: e.file,
              uri: e.uri,
              width: 52,
              height: 52,
            ),
          ),
          title: Text('${index + 1}번째 장면', style: const TextStyle(fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppTheme.inkMuted,
                tooltip: '삭제',
                onPressed: () => _removeAt(index),
              ),
              const Icon(Icons.drag_handle, color: AppTheme.inkMuted),
            ],
          ),
        );
      },
    );
  }
}

class _GridPhotoTile extends StatelessWidget {
  const _GridPhotoTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final _TodayPhotoEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                ChapterPhotoImage(
                  file: entry.file,
                  uri: entry.uri,
                  width: w,
                  height: h,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Material(
                    color: AppTheme.ink.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: Icon(Icons.zoom_out_map_rounded, size: 16, color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PhotoViewerPage extends StatefulWidget {
  const _PhotoViewerPage({
    required this.entries,
    required this.initialIndex,
    this.onDelete,
  });

  final List<_TodayPhotoEntry> entries;
  final int initialIndex;
  final ValueChanged<int>? onDelete;

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_page + 1} / ${widget.entries.length}'),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '이 사진 삭제',
              onPressed: () => widget.onDelete!(_page),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.entries.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 3,
            child: Center(
              child: ChapterPhotoImage(
                file: widget.entries[i].file,
                uri: widget.entries[i].uri,
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height * 0.75,
                fit: BoxFit.contain,
                fullResolution: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
