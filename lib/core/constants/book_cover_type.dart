/// 실물 책 표지 종류
class BookCoverType {
  BookCoverType._();

  static const chapterIcon = 'chapter_icon';
  static const customPhoto = 'custom_photo';

  static const labels = <String, String>{
    chapterIcon: 'Chapter 아이콘',
    customPhoto: '사진 표지',
  };

  static String label(String? type) =>
      labels[type] ?? labels[chapterIcon]!;
}
