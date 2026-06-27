import 'book_layout_types.dart';
import 'book_pdf_style.dart';

class BookCalendarDayCell {
  const BookCalendarDayCell({
    this.day,
    this.dateKey,
    this.hasEntry = false,
    this.moodEmoji,
    this.coverPhotoUrl,
  });

  final int? day;
  final String? dateKey;
  final bool hasEntry;
  final String? moodEmoji;
  final String? coverPhotoUrl;
}

class BookCalendarMonthLayout {
  const BookCalendarMonthLayout({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.rowCount,
    required this.cells,
    required this.cellWidth,
    required this.rowHeight,
    required this.photoHeight,
    required this.dateRowHeight,
    required this.innerPad,
    required this.gap,
    required this.totalGridHeight,
  });

  final int year;
  final int month;
  final String monthLabel;
  final int rowCount;
  final List<BookCalendarDayCell> cells;
  final double cellWidth;
  final double rowHeight;
  final double photoHeight;
  final double dateRowHeight;
  final double innerPad;
  final double gap;
  final double totalGridHeight;
}

class BookCalendarLayout {
  BookCalendarLayout._();

  static const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  static String dateKeyFrom(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  static String monthLabelKo(int year, int month) => '$year년 $month월';

  static double calendarGridTopY() {
    const titleSize = 16.0;
    const titleBottomGap = 12.0;
    const weekdayRow = 11.0;
    const weekdayBottomGap = 6.0;
    return BookPdfPageSpec.margin +
        titleSize +
        titleBottomGap +
        weekdayRow +
        weekdayBottomGap;
  }

  static double calendarMaxGridHeight() =>
      BookPdfPageSpec.height - BookPdfPageSpec.margin - calendarGridTopY();

  static BookCalendarMonthLayout buildCalendarMonthLayout({
    required int year,
    required int month,
    required double gridWidth,
    Map<String, BookCalendarEntryLookup>? entriesByDate,
  }) {
    final gap = BookCalendarStyle.gap;
    final lookup = entriesByDate ?? {};
    const dateRowHeight = BookCalendarStyle.dateRowHeight;
    const innerPad = BookCalendarStyle.innerPad;
    const maxScale = 1.0;

    final first = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final rowCount = ((startWeekday + daysInMonth) / 7).ceil();

    final cellWidth = (gridWidth - gap * 6) / 7;
    final photoHeight = cellWidth / BookCalendarStyle.photoAspect;
    final rowHeight = dateRowHeight + photoHeight + innerPad * 2;
    final naturalGridHeight = rowHeight * rowCount + gap * (rowCount - 1);

    final maxH = calendarMaxGridHeight();
    final scale =
        naturalGridHeight > maxH ? (maxH / naturalGridHeight).clamp(0.0, maxScale) : maxScale;

    final cells = <BookCalendarDayCell>[];
    final totalSlots = rowCount * 7;

    for (var i = 0; i < totalSlots; i++) {
      if (i < startWeekday || i >= startWeekday + daysInMonth) {
        cells.add(const BookCalendarDayCell());
        continue;
      }

      final day = i - startWeekday + 1;
      final key = dateKeyFrom(year, month, day);
      final entry = lookup[key];

      cells.add(
        BookCalendarDayCell(
          day: day,
          dateKey: key,
          hasEntry: entry != null,
          moodEmoji: entry?.moodEmoji,
          coverPhotoUrl: entry?.coverPhotoUrl,
        ),
      );
    }

    return BookCalendarMonthLayout(
      year: year,
      month: month,
      monthLabel: monthLabelKo(year, month),
      rowCount: rowCount,
      cells: cells,
      cellWidth: cellWidth,
      rowHeight: rowHeight * scale,
      photoHeight: photoHeight * scale,
      dateRowHeight: dateRowHeight * scale,
      innerPad: innerPad * scale,
      gap: gap,
      totalGridHeight: naturalGridHeight * scale,
    );
  }

  static Map<String, BookCalendarEntryLookup> indexEntriesByDate(
    List<BookDiaryEntry> entries,
  ) {
    final map = <String, BookCalendarEntryLookup>{};
    for (final entry in entries) {
      final key = entry.date.length >= 10 ? entry.date.substring(0, 10) : entry.date;
      if (key.isEmpty) continue;
      map[key] = BookCalendarEntryLookup(
        moodEmoji: entry.moodEmoji,
        coverPhotoUrl: entry.photoUris.isNotEmpty ? entry.photoUris.first : null,
      );
    }
    return map;
  }

  static List<({int year, int month})> listMonthsWithEntries(
    List<BookDiaryEntry> entries,
  ) {
    final seen = <String>{};
    final months = <({int year, int month})>[];
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    for (final entry in sorted) {
      if (entry.date.length < 7) continue;
      final key = entry.date.substring(0, 7);
      if (seen.contains(key)) continue;

      final year = int.tryParse(entry.date.substring(0, 4));
      final month = int.tryParse(entry.date.substring(5, 7));
      if (year == null || month == null || month < 1 || month > 12) continue;

      seen.add(key);
      months.add((year: year, month: month));
    }
    return months;
  }

  static List<BookDiaryEntry> entriesForMonth(
    List<BookDiaryEntry> entries,
    int year,
    int month,
  ) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    return entries
        .where((entry) => entry.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class BookCalendarEntryLookup {
  const BookCalendarEntryLookup({this.moodEmoji, this.coverPhotoUrl});

  final String? moodEmoji;
  final String? coverPhotoUrl;
}
