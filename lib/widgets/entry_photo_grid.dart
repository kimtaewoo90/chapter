import 'dart:io';

import 'package:flutter/material.dart';

import '../core/utils/entry_photos.dart';
import '../models/daily_entry.dart';
import 'entry_photo.dart';

class EntryPhotoGrid extends StatelessWidget {
  const EntryPhotoGrid({
    super.key,
    required this.localPaths,
    this.newFiles = const [],
    this.height = 120,
    this.onRemoveLocal,
    this.onRemoveNew,
  });

  final List<String> localPaths;
  final List<File> newFiles;
  final double height;
  final ValueChanged<int>? onRemoveLocal;
  final ValueChanged<int>? onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final total = localPaths.length + newFiles.length;
    if (total == 0) {
      return EntryPhoto(height: height);
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isLocal = index < localPaths.length;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: height * 0.85,
                  height: height,
                  child: isLocal
                      ? EntryPhoto(url: localPaths[index], height: height, borderRadius: 12)
                      : EntryPhoto(file: newFiles[index - localPaths.length], height: height, borderRadius: 12),
                ),
              ),
              if (onRemoveLocal != null || onRemoveNew != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      if (isLocal) {
                        onRemoveLocal?.call(index);
                      } else {
                        onRemoveNew?.call(index - localPaths.length);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class EntryPhotoHero extends StatelessWidget {
  const EntryPhotoHero({super.key, required this.entry, this.height = 200});

  final dynamic entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (entry is! DailyEntry) return EntryPhoto(height: height);
    final e = entry as DailyEntry;
    final paths = EntryPhotos.displayUris(
      localPaths: e.localPhotoPaths,
      remoteUrls: e.remotePhotoUrls,
    );
    if (paths.isEmpty) return EntryPhoto(height: height);
    if (paths.length == 1) {
      return EntryPhoto(url: paths.first, height: height);
    }
    return EntryPhotoGrid(localPaths: paths, height: height);
  }
}
