import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/book_order.dart';
import '../../widgets/book_payment_info_card.dart';
import '../../widgets/book_order_progress.dart';
import '../../widgets/book_pdf_preview.dart';
import '../../widgets/paper_background.dart';

/// 주문 스냅샷 기준 — 인쇄 PDF와 같은 책 미리보기
class BookOrderPreviewScreen extends StatelessWidget {
  const BookOrderPreviewScreen({super.key, required this.order});

  final BookOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountFmt = NumberFormat('#,###', 'ko_KR');
    final dateLabel = order.createdAt != null
        ? DateFormat('yyyy년 M월 d일', 'ko_KR').format(order.createdAt!)
        : null;
    final hasSnapshots = order.snapshots.isNotEmpty;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(order.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('제작 현황', style: textTheme.labelLarge?.copyWith(color: AppTheme.inkMuted)),
                        const SizedBox(height: 6),
                        Text(
                          [
                            '${order.pageCount}일',
                            order.hardcover ? '하드커버' : '소프트커버',
                            '${amountFmt.format(order.amount)}원',
                            if (dateLabel != null) dateLabel,
                          ].join(' · '),
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  BookOrderStatusChip(status: order.status),
                ],
              ),
            ),
            if (order.status == BookOrderStatus.pendingPayment) ...[
              const SizedBox(height: 16),
              BookPaymentInfoCard(
                amount: order.amount,
                depositorName: order.recipientName,
              ),
            ],
            const SizedBox(height: 20),
            Text('책 미리보기', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              hasSnapshots
                  ? '주문 시 저장된 일기 스냅샷으로, 실제 인쇄 PDF와 같은 배치예요.'
                  : '스냅샷이 없어 미리보기를 표시할 수 없어요.',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (hasSnapshots)
              BookPdfPreview.fromSnapshots(
                snapshots: order.snapshots,
                bookTitle: order.bookTitle,
                coverType: order.cover,
                coverPhotoUri: order.coverPhotoUrl,
                coverTitle: order.coverTitle,
                diaryFontId: order.diaryFontId,
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.paperDark),
                ),
                child: Text(
                  '일기 스냅샷 없음',
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
