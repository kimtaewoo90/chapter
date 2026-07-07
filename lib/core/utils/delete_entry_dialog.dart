import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<bool> confirmDeleteDiaryEntry(BuildContext context, DateTime date) async {
  final label = DateFormat('M월 d일', 'ko_KR').format(date);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('이 날 기록 삭제'),
      content: Text('$label의 사진과 일기를 모두 삭제할까요?\n되돌릴 수 없어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  return result ?? false;
}
