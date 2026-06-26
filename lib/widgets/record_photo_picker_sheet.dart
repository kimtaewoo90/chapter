import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

enum _PhotoSource { gallery, camera }

/// 오늘의 컷 — 갤러리/카메라 선택 바텀시트
Future<void> showRecordPhotoSourceSheet(
  BuildContext context, {
  required VoidCallback onGallery,
  required VoidCallback onCamera,
}) async {
  await HapticFeedback.lightImpact();
  if (!context.mounted) return;

  final choice = await showModalBottomSheet<_PhotoSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final title = Theme.of(ctx).textTheme.titleMedium;
      final subtitle = Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('장면 붙이기', style: title),
              const SizedBox(height: 4),
              Text('갤러리에서 고르거나, 지금 바로 찍어 보세요', style: subtitle),
              const SizedBox(height: 18),
              _PhotoSourceOption(
                icon: Icons.photo_library_rounded,
                title: '갤러리에서 고르기',
                subtitle: '여러 장을 한 번에 선택할 수 있어요',
                onTap: () => Navigator.pop(ctx, _PhotoSource.gallery),
              ),
              const SizedBox(height: 10),
              _PhotoSourceOption(
                icon: Icons.camera_alt_rounded,
                title: '지금 찍기',
                subtitle: '카메라로 바로 담아요',
                onTap: () => Navigator.pop(ctx, _PhotoSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || choice == null) return;
  // 시트가 닫힌 뒤 카메라/갤러리를 열어야 iOS에서 멈춤·실패가 줄어듭니다.
  await Future<void>.delayed(const Duration(milliseconds: 280));
  if (!context.mounted) return;
  switch (choice) {
    case _PhotoSource.gallery:
      onGallery();
    case _PhotoSource.camera:
      onCamera();
  }
}

class _PhotoSourceOption extends StatelessWidget {
  const _PhotoSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.paperDark),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.inkMuted.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
