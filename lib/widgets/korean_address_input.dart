import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/korean_address_result.dart';
import 'korean_address_search_screen.dart';

/// 카카오(다음) 우편번호 · 주소 검색 + 상세주소 입력
class KoreanAddressInput extends StatelessWidget {
  const KoreanAddressInput({
    super.key,
    required this.baseAddress,
    required this.zoneCode,
    required this.detailController,
    required this.onAddressSelected,
    this.detailFocusNode,
    this.onChanged,
  });

  final String baseAddress;
  final String zoneCode;
  final TextEditingController detailController;
  final ValueChanged<KoreanAddressResult> onAddressSelected;
  final FocusNode? detailFocusNode;
  final VoidCallback? onChanged;

  Future<void> _openSearch(BuildContext context) async {
    final result = await Navigator.push<KoreanAddressResult>(
      context,
      MaterialPageRoute(builder: (_) => const KoreanAddressSearchScreen()),
    );
    if (result != null) {
      onAddressSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasBase = baseAddress.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (zoneCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.paper.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  zoneCode,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppTheme.inkMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (zoneCode.isNotEmpty) const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _openSearch(context),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(hasBase ? '주소 다시 검색' : '주소 검색'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hasBase)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.paper.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: AppTheme.accent.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    baseAddress,
                    style: textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            '「주소 검색」으로 도로명·지번 주소를 찾아 주세요.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.35),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: detailController,
          focusNode: detailFocusNode,
          enabled: hasBase,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            labelText: '상세 주소',
            hintText: hasBase ? '101동 1001호, 현관 비밀번호 등' : '주소 검색 후 입력',
            prefixIcon: Icon(
              Icons.home_outlined,
              size: 20,
              color: AppTheme.accent.withValues(alpha: hasBase ? 0.85 : 0.4),
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ],
    );
  }
}
