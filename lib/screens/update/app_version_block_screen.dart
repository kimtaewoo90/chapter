import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_version_gate.dart';
import '../../widgets/book_spine_logo.dart';
import '../../widgets/paper_background.dart';

/// 최소 버전 미달·점검 시 앱 진입을 막는 전면 화면
class AppVersionBlockScreen extends StatefulWidget {
  const AppVersionBlockScreen({
    super.key,
    required this.gate,
    required this.onRetry,
    this.onOpenStore,
  });

  final AppVersionGateResult gate;
  final Future<void> Function() onRetry;
  final VoidCallback? onOpenStore;

  @override
  State<AppVersionBlockScreen> createState() => _AppVersionBlockScreenState();
}

class _AppVersionBlockScreenState extends State<AppVersionBlockScreen> {
  bool _retrying = false;

  bool get _isMaintenance => widget.gate.blockReason == VersionBlockReason.maintenance;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _handleOpenStore() async {
    widget.onOpenStore?.call();
    final url = widget.gate.storeUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showStoreButton = !_isMaintenance && widget.gate.storeUrl.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      child: PaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const BookSpineLogo(expanded: true),
                  const SizedBox(height: 28),
                  Text(
                    widget.gate.title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 14),
                  Text(
                    widget.gate.message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.inkMuted,
                      height: 1.65,
                    ),
                  ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                  if (!_isMaintenance) ...[
                    const SizedBox(height: 20),
                    Text(
                      '현재 ${widget.gate.currentVersion} · 필요 ${widget.gate.minSupportedVersion} 이상',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                  const Spacer(flex: 3),
                  if (showStoreButton)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _handleOpenStore,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('스토어에서 업데이트'),
                      ),
                    ),
                  if (showStoreButton) const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _retrying ? null : _handleRetry,
                      child: _retrying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                            )
                          : Text(_isMaintenance ? '다시 확인' : '업데이트 후 다시 확인'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
