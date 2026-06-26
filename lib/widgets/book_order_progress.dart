import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/book_order.dart';

/// 책 제작 파이프라인 단계
class BookOrderPipeline {
  BookOrderPipeline._();

  static const steps = [
    '주문 · 스냅샷',
    '입금 대기',
    '입금 확인',
    'PDF 제작',
    '인쇄',
    '배송',
  ];

  /// 완료된 마지막 단계 인덱스 (0-based)
  static int completedIndex(BookOrderStatus status) => switch (status) {
        BookOrderStatus.pendingPayment => 0,
        BookOrderStatus.paid => 2,
        BookOrderStatus.processing => 3,
        BookOrderStatus.printed => 4,
        BookOrderStatus.shipped => 5,
        BookOrderStatus.cancelled => -1,
      };

  /// 현재 진행 중인 단계 인덱스
  static int activeIndex(BookOrderStatus status) => switch (status) {
        BookOrderStatus.pendingPayment => 1,
        BookOrderStatus.paid => 2,
        BookOrderStatus.processing => 3,
        BookOrderStatus.printed => 4,
        BookOrderStatus.shipped => 5,
        BookOrderStatus.cancelled => 0,
      };

  static bool isInProgress(BookOrderStatus status) =>
      status != BookOrderStatus.shipped && status != BookOrderStatus.cancelled;
}

class BookOrderProgressCard extends StatelessWidget {
  const BookOrderProgressCard({
    super.key,
    required this.order,
    this.compact = false,
  });

  final BookOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountFmt = NumberFormat('#,###', 'ko_KR');
    final dateLabel = order.createdAt != null
        ? DateFormat('M월 d일', 'ko_KR').format(order.createdAt!)
        : null;
    final cancelled = order.status == BookOrderStatus.cancelled;
    final done = order.status == BookOrderStatus.shipped;
    final completed = BookOrderPipeline.completedIndex(order.status);
    final active = BookOrderPipeline.activeIndex(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppTheme.accent.withValues(alpha: 0.35)
              : AppTheme.paperDark.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmShadow.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.bookTitle, style: textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      [
                        '${order.pageCount}일',
                        order.hardcover ? '하드커버' : '소프트커버',
                        '${amountFmt.format(order.amount)}원',
                        if (dateLabel != null) dateLabel,
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          if (!compact && !cancelled) ...[
            const SizedBox(height: 16),
            _StepperRow(
              completedIndex: completed,
              activeIndex: active,
              done: done,
            ),
          ],
          if (cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '취소된 주문이에요.',
                style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      BookOrderStatus.pendingPayment => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      BookOrderStatus.paid => (AppTheme.accent.withValues(alpha: 0.12), AppTheme.accent),
      BookOrderStatus.processing => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      BookOrderStatus.printed => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      BookOrderStatus.shipped => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
      BookOrderStatus.cancelled => (Colors.black12, AppTheme.inkMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.completedIndex,
    required this.activeIndex,
    required this.done,
  });

  final int completedIndex;
  final int activeIndex;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final steps = BookOrderPipeline.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            final isComplete = i <= completedIndex || done;
            final isActive = !done && i == activeIndex;
            final lineColor = isComplete ? AppTheme.accent : AppTheme.paperDark;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: i == 0
                        ? const SizedBox.shrink()
                        : Container(height: 2, color: lineColor.withValues(alpha: isComplete ? 1 : 0.35)),
                  ),
                  _StepDot(complete: isComplete, active: isActive),
                  Expanded(
                    child: i == steps.length - 1
                        ? const SizedBox.shrink()
                        : Container(
                            height: 2,
                            color: (i < completedIndex || done)
                                ? AppTheme.accent
                                : AppTheme.paperDark.withValues(alpha: 0.35),
                          ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(steps.length, (i) {
            final isComplete = i <= completedIndex || done;
            final isActive = !done && i == activeIndex;
            return Text(
              steps[i],
              style: TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppTheme.accent
                    : isComplete
                        ? AppTheme.ink.withValues(alpha: 0.75)
                        : AppTheme.inkMuted.withValues(alpha: 0.55),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.complete, required this.active});

  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: complete ? AppTheme.accent : Colors.white,
        border: Border.all(
          color: complete || active ? AppTheme.accent : AppTheme.paperDark,
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 6)]
            : null,
      ),
      child: complete
          ? const Icon(Icons.check, size: 7, color: Colors.white)
          : null,
    );
  }
}
