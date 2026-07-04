import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/book_order.dart';

/// 책 제작 진행 — 사용자-facing 5단계
class BookOrderPipeline {
  BookOrderPipeline._();

  static const steps = [
    '입금 대기',
    '입금 완료',
    '제작중',
    '배송중',
    '배송완료',
  ];

  static int completedIndex(BookOrderStatus status) {
    final step = status.displayStep;
    if (step < 0) return -1;
    return step;
  }

  static int activeIndex(BookOrderStatus status) {
    final step = status.displayStep;
    if (step < 0) return 0;
    return step;
  }

  static bool isInProgress(BookOrderStatus status) => status.showInBookList;
}

class BookOrderProgressCard extends StatelessWidget {
  const BookOrderProgressCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final BookOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountFmt = NumberFormat('#,###', 'ko_KR');
    final dateLabel = order.createdAt != null
        ? DateFormat('M월 d일', 'ko_KR').format(order.createdAt!)
        : null;
    final cancelled = order.status == BookOrderStatus.cancelled;
    final completed = BookOrderPipeline.completedIndex(order.status);
    final active = BookOrderPipeline.activeIndex(order.status);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.8)),
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
                    Text(order.displayTitle, style: textTheme.titleSmall),
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
                    if (onTap != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '탭해서 디지털 미리보기',
                        style: textTheme.labelSmall?.copyWith(color: AppTheme.accent),
                      ),
                    ],
                  ],
                ),
              ),
              BookOrderStatusChip(status: order.status),
            ],
          ),
          if (!cancelled) ...[
            const SizedBox(height: 16),
            _StepperRow(
              completedIndex: completed,
              activeIndex: active,
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

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }
}

class BookOrderStatusChip extends StatelessWidget {
  const BookOrderStatusChip({super.key, required this.status});

  final BookOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status.displayStep) {
      0 => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      1 => (AppTheme.accent.withValues(alpha: 0.12), AppTheme.accent),
      2 => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      3 => (const Color(0xFFE8EAF6), const Color(0xFF3949AB)),
      4 => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
      _ => (Colors.black12, AppTheme.inkMuted),
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
  });

  final int completedIndex;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final steps = BookOrderPipeline.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            final isComplete = i < completedIndex;
            final isCurrent = i == activeIndex;
            final lineColor = isComplete || isCurrent ? AppTheme.accent : AppTheme.paperDark;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: i == 0
                        ? const SizedBox.shrink()
                        : Container(
                            height: 2,
                            color: lineColor.withValues(alpha: (i <= activeIndex) ? 1 : 0.35),
                          ),
                  ),
                  _StepDot(complete: isComplete, active: isCurrent),
                  Expanded(
                    child: i == steps.length - 1
                        ? const SizedBox.shrink()
                        : Container(
                            height: 2,
                            color: (i < activeIndex)
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
        Row(
          children: List.generate(steps.length, (i) {
            final isComplete = i < completedIndex;
            final isCurrent = i == activeIndex;
            return Expanded(
              child: Text(
                steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.2,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? AppTheme.accent
                      : isComplete
                          ? AppTheme.ink.withValues(alpha: 0.75)
                          : AppTheme.inkMuted.withValues(alpha: 0.55),
                ),
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
