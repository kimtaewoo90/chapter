import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/constants/book_payment.dart';
import '../core/theme/app_theme.dart';

/// 책 주문 계좌이체 안내 — 복사 버튼 포함
class BookPaymentInfoCard extends StatelessWidget {
  const BookPaymentInfoCard({
    super.key,
    required this.amount,
    this.depositorName,
    this.compact = false,
  });

  final int amount;
  final String? depositorName;
  final bool compact;

  static void showCopiedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) showCopiedSnackBar(context, '$label 복사됐어요');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountFmt = NumberFormat('#,###', 'ko_KR');
    final amountText = '${amountFmt.format(amount)}원';
    final name = depositorName?.trim();

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: compact ? 18 : 20,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              Text(
                '입금 안내',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          _CopyRow(
            label: '은행',
            value: BookPaymentInfo.bankName,
            onCopy: null,
          ),
          const SizedBox(height: 8),
          _CopyRow(
            label: '계좌번호',
            value: BookPaymentInfo.accountNumber,
            onCopy: () => _copy(context, BookPaymentInfo.accountNumber, '계좌번호'),
          ),
          const SizedBox(height: 8),
          _CopyRow(
            label: '예금주',
            value: BookPaymentInfo.accountHolder,
            onCopy: null,
          ),
          const SizedBox(height: 8),
          _CopyRow(
            label: '입금액',
            value: amountText,
            emphasize: true,
            onCopy: () => _copy(context, amount.toString(), '입금액'),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              name != null && name.isNotEmpty
                  ? '입금자명은 받는 분 이름($name)과 같게 해주세요.\n입금 확인 후 제작이 시작돼요.'
                  : '입금 확인 후 제작이 시작돼요.',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.inkMuted,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool emphasize;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.inkMuted,
              height: 1.35,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: AppTheme.ink,
              height: 1.35,
            ),
          ),
        ),
        if (onCopy != null)
          TextButton(
            onPressed: onCopy,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.accent,
            ),
            child: const Text('복사', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

/// 주문 완료 직후 입금 안내 바텀시트
Future<void> showBookOrderPaymentSheet(
  BuildContext context, {
  required int amount,
  String? depositorName,
  String? orderLabel,
}) {
  final textTheme = Theme.of(context).textTheme;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.paperDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '주문이 접수됐어요',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                orderLabel != null && orderLabel.isNotEmpty
                    ? '아래 계좌로 입금해 주시면 제작을 시작할게요.'
                    : '아래 계좌로 입금해 주시면 제작을 시작할게요.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              BookPaymentInfoCard(
                amount: amount,
                depositorName: depositorName,
              ),
              const SizedBox(height: 12),
              Text(
                '내 책에서도 입금 안내를 다시 볼 수 있어요.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
