import 'dart:io';

import 'package:flutter/material.dart';

import '../core/book_layout/book_calendar_layout.dart';
import '../core/book_layout/book_layout_types.dart';
import '../core/book_layout/book_pdf_style.dart';
import 'entry_photo.dart';

/// chapter_admin `pdf/calendarPage.ts`
class BookPdfCalendarPage extends StatelessWidget {
  const BookPdfCalendarPage({super.key, required this.layout});

  final BookCalendarMonthLayout layout;

  @override
  Widget build(BuildContext context) {
    const margin = BookPdfPageSpec.margin;
    const contentWidth = BookPdfPageSpec.contentWidth;
    final gridTop = BookCalendarLayout.calendarGridTopY();
    final maxGridH = BookCalendarLayout.calendarMaxGridHeight();
    final gridStartY = gridTop + ((maxGridH - layout.totalGridHeight) / 2).clamp(0.0, double.infinity);

    return ColoredBox(
      color: BookCalendarStyle.paper,
      child: Stack(
        children: [
          Positioned(
            left: margin,
            top: margin,
            width: contentWidth,
            child: Text(
              layout.monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BookCalendarStyle.ink,
              ),
            ),
          ),
          Positioned(
            left: margin,
            top: margin + 16 + 12,
            width: contentWidth,
            child: Row(
              children: [
                for (final weekday in BookCalendarLayout.weekdays)
                  Expanded(
                    child: Text(
                      weekday,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: BookCalendarStyle.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var row = 0; row < layout.rowCount; row++)
            for (var col = 0; col < 7; col++)
              _buildCell(
                layout: layout,
                row: row,
                col: col,
                gridStartY: gridStartY,
                margin: margin,
              ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required BookCalendarMonthLayout layout,
    required int row,
    required int col,
    required double gridStartY,
    required double margin,
  }) {
    final cell = layout.cells[row * 7 + col];
    if (cell.day == null) return const SizedBox.shrink();

    final gap = layout.gap;
    final cellX = margin + col * (layout.cellWidth + gap);
    final rowY = gridStartY + row * (layout.rowHeight + gap);

    if (!cell.hasEntry) {
      return Positioned(
        left: cellX + 1,
        top: rowY + 1,
        width: layout.cellWidth - 2,
        child: Text(
          '${cell.day}',
          style: const TextStyle(
            fontSize: 7,
            color: BookCalendarStyle.dayEmpty,
          ),
        ),
      );
    }

    final innerPad = layout.innerPad;
    final photoX = cellX + innerPad;
    final photoY = rowY + innerPad + layout.dateRowHeight;
    final photoW = layout.cellWidth - innerPad * 2;
    final photoH = layout.photoHeight;

    return Positioned(
      left: cellX,
      top: rowY,
      width: layout.cellWidth,
      height: layout.rowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BookCalendarStyle.cellHasEntry,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: BookCalendarStyle.cellBorderEntry, width: 0.5),
        ),
        child: Stack(
          children: [
            Positioned(
              left: innerPad,
              top: innerPad,
              child: Text(
                '${cell.day}',
                style: const TextStyle(
                  fontSize: 8,
                  color: BookCalendarStyle.ink,
                ),
              ),
            ),
            Positioned(
              left: photoX - cellX,
              top: photoY - rowY,
              width: photoW,
              height: photoH,
              child: _CalendarCellPhoto(
                url: cell.coverPhotoUrl,
                moodEmoji: cell.moodEmoji,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCellPhoto extends StatelessWidget {
  const _CalendarCellPhoto({this.url, this.moodEmoji});

  final String? url;
  final String? moodEmoji;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: url!.startsWith('http')
            ? EntryPhoto(url: url!, height: double.infinity, borderRadius: 0, fit: BoxFit.cover)
            : EntryPhoto(
                file: File(url!),
                height: double.infinity,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
      );
    }

    if (moodEmoji != null && moodEmoji!.isNotEmpty) {
      return Align(
        alignment: Alignment(0, 0.2),
        child: Text(
          moodEmoji!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: BookCalendarStyle.ink),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
