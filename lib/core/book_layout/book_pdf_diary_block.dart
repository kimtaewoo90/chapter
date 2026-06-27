import 'book_layout_types.dart';

sealed class BookDiaryBlock {
  const BookDiaryBlock();
}

class BookDiaryEntryGapBlock extends BookDiaryBlock {
  const BookDiaryEntryGapBlock();
}

class BookDiaryHeaderBlock extends BookDiaryBlock {
  const BookDiaryHeaderBlock(this.entry);

  final BookDiaryEntry entry;
}

class BookDiaryPhotosBlock extends BookDiaryBlock {
  const BookDiaryPhotosBlock(this.entry);

  final BookDiaryEntry entry;
}

class BookDiaryTextBlock extends BookDiaryBlock {
  const BookDiaryTextBlock({
    required this.entry,
    required this.text,
    required this.plan,
    required this.compact,
  });

  final BookDiaryEntry entry;
  final String text;
  final BookLayoutPlan plan;
  final bool compact;
}
