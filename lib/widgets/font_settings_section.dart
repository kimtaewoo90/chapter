import 'package:flutter/material.dart';

import '../core/constants/app_fonts.dart';
import '../core/theme/app_theme.dart';

class FontPickerSection extends StatelessWidget {
  const FontPickerSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
    this.previewText = '오늘은 유난히 따뜻한 하루',
    this.previewUsesDiaryStyle = false,
  });

  final String title;
  final String subtitle;
  final AppFontId selected;
  final ValueChanged<AppFontId> onSelect;
  final String previewText;
  final bool previewUsesDiaryStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 12),
        ...kAppFontOptions.map((option) {
          final isSelected = option.id == selected;
          TextStyle optionLabelStyle({required double size, Color? color, FontWeight? weight}) {
            if (previewUsesDiaryStyle) {
              return diaryFontStyle(option.id, fontSize: size, color: color, fontWeight: weight);
            }
            return appFontStyle(option.id, fontSize: size, fontWeight: weight, color: color);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelect(option.id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: optionLabelStyle(
                                size: 18,
                                weight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.description,
                              style: optionLabelStyle(size: 13, color: AppTheme.inkMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              previewText,
                              style: optionLabelStyle(size: 14, color: AppTheme.accent),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppTheme.accent, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
