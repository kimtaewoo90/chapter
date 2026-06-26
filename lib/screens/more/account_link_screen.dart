import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/constants/dev_flags.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../services/google_sign_in_helper.dart';
import '../../widgets/paper_background.dart';

/// 익명 → 연결 · Google/Apple로 다른 기기에서 불러오기
class AccountLinkScreen extends StatefulWidget {
  const AccountLinkScreen({super.key});

  @override
  State<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends State<AccountLinkScreen> {
  bool _busy = false;
  String? _status;
  bool? _appleSignInAvailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoogleSignInHelper.instance.warmUp();
      if (Platform.isIOS || Platform.isMacOS) {
        SignInWithApple.isAvailable().then((available) {
          if (mounted) setState(() => _appleSignInAvailable = available);
        });
      }
    });
  }

  Future<bool> _confirmRestore(AppState state, {required String providerLabel}) async {
    if (state.totalDays == 0) return true;
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 불러오기'),
        content: Text(
          '이 기기에만 있는 ${state.totalDays}일의 기록은 그대로 두고, '
          '$providerLabel 계정에 백업된 기록을 가져옵니다.\n\n'
          '같은 날짜는 클라우드 내용으로 바뀔 수 있어요. 계속할까요?',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('불러오기'),
          ),
        ],
      ),
    );
    return choice ?? false;
  }

  Future<void> _run({
    required Future<({String? error, String? success})> Function() action,
    required String statusLabel,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = statusLabel;
    });
    await Future<void>.delayed(Duration.zero);
    final result = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = null;
    });
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), duration: const Duration(seconds: 4)),
      );
      return;
    }
    if (result.success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success!), duration: const Duration(seconds: 4)),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final linked = state.linkedProviders;
    final anonymous = state.isAnonymousAccount;
    final showApple = kEnableAppleSignIn &&
        (Platform.isIOS || Platform.isMacOS) &&
        (_appleSignInAvailable ?? true);

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('백업 · 다른 기기')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('이 기기에서 백업', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              anonymous
                  ? '지금까지 쓴 일기·사진은 그대로 두고 Google${showApple ? '·Apple' : ''}만 연결해요. '
                      'uid가 바뀌지 않아 실물 책·Firestore 경로도 같아요.'
                  : '이미 연결된 계정으로 백업 중이에요.',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
            ),
            if (!state.cloudSyncEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.accent.withValues(alpha: 0.1),
                ),
                child: Text(
                  state.lastCloudSyncError ??
                      'Firebase 로그인이 필요해요. 아래 버튼으로 다시 시도하거나 앱을 재시작해 주세요.',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.ink),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_busy) return;
                          setState(() {
                            _busy = true;
                            _status = 'Firebase 로그인 재시도…';
                          });
                          final ok = await context.read<AppState>().retryCloudAuth();
                          if (!mounted) return;
                          setState(() {
                            _busy = false;
                            _status = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? '로그인됐어요. 이제 Apple·Google 연결을 시도해 주세요.'
                                    : context.read<AppState>().lastCloudSyncError ??
                                        'Firebase 로그인에 실패했어요.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Firebase 로그인 다시 시도'),
                ),
              ),
            ],
            if (linked.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linked
                    .map(
                      (label) => Chip(
                        label: Text(label),
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (anonymous && state.cloudSyncEnabled) ...[
              const SizedBox(height: 20),
              _SocialButton(
                label: 'Google로 연결',
                icon: Icons.g_mobiledata_rounded,
                onPressed: _busy
                    ? null
                    : () => _run(
                          statusLabel: 'Google 계정 창을 여는 중…',
                          action: () async {
                            final err =
                                await context.read<AppState>().linkGoogleAccount();
                            if (err != null) return (error: err, success: null);
                            context.read<AnalyticsService>().logAccountLink('google');
                            return (
                              error: null,
                              success: '계정이 연결됐어요. 기록을 클라우드에 백업했어요.',
                            );
                          },
                        ),
              ),
              if (showApple) ...[
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Apple로 연결',
                  icon: Icons.apple,
                  onPressed: _busy
                      ? null
                      : () => _run(
                            statusLabel: 'Apple 로그인 준비 중…',
                            action: () async {
                              final err =
                                  await context.read<AppState>().linkAppleAccount();
                              if (err != null) return (error: err, success: null);
                              context.read<AnalyticsService>().logAccountLink('apple');
                              return (
                                error: null,
                                success: 'Apple 계정이 연결됐어요. 기록을 클라우드에 백업했어요.',
                              );
                            },
                          ),
                ),
              ] else if (kEnableAppleSignIn && (Platform.isIOS || Platform.isMacOS)) ...[
                const SizedBox(height: 12),
                Text(
                  '이 기기에서는 Apple 로그인을 사용할 수 없어요.',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
              ],
            ],
            const SizedBox(height: 32),
            const Divider(color: AppTheme.paperDark, height: 1),
            const SizedBox(height: 24),
            Text('다른 기기에서 불러오기', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '예전에 Google${showApple ? '·Apple' : ''}로 연결해 둔 계정으로 로그인하면, '
              '그때의 uid·일기·사진(클라우드)을 이 기기로 가져옵니다.',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.55),
            ),
            const SizedBox(height: 20),
            _SocialButton(
              label: 'Google로 불러오기',
              icon: Icons.cloud_download_outlined,
              onPressed: _busy
                  ? null
                  : () async {
                      final appState = context.read<AppState>();
                      if (!await _confirmRestore(appState, providerLabel: 'Google')) return;
                      await _run(
                        statusLabel: 'Google 계정 기록 불러오는 중…',
                        action: () async {
                          final result =
                              await appState.restoreFromGoogleAccount();
                          if (result.error != null) {
                            return (error: result.error, success: null);
                          }
                          context.read<AnalyticsService>().logAccountRestore(
                                provider: 'google',
                                importedCount: result.count,
                              );
                          if (result.count == 0) {
                            return (
                              error: '클라우드에 저장된 기록이 없어요. '
                                  '다른 기기에서 먼저 Google로 연결해 백업해 주세요.',
                              success: null,
                            );
                          }
                          return (
                            error: null,
                            success: '${result.count}일의 기록을 불러왔어요.',
                          );
                        },
                      );
                    },
            ),
            if (showApple) ...[
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 불러오기',
                icon: Icons.cloud_download_outlined,
                onPressed: _busy
                    ? null
                    : () async {
                        final appState = context.read<AppState>();
                        if (!await _confirmRestore(appState, providerLabel: 'Apple')) return;
                        await _run(
                          statusLabel: 'Apple 계정 기록 불러오는 중…',
                          action: () async {
                            final result =
                                await appState.restoreFromAppleAccount();
                            if (result.error != null) {
                              return (error: result.error, success: null);
                            }
                            context.read<AnalyticsService>().logAccountRestore(
                                  provider: 'apple',
                                  importedCount: result.count,
                                );
                            if (result.count == 0) {
                              return (
                                error: '클라우드에 저장된 기록이 없어요. '
                                    '다른 기기에서 먼저 Apple로 연결해 백업해 주세요.',
                                success: null,
                              );
                            }
                            return (
                              error: null,
                              success: '${result.count}일의 기록을 불러왔어요.',
                            );
                          },
                        );
                      },
              ),
            ],
            if (!anonymous) ...[
              const SizedBox(height: 20),
              Text(
                '이미 이 기기에서 Google${showApple ? '·Apple' : ''}로 연결했다면, 불러오기는 같은 계정을 다시 맞추는 용도예요.',
                style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.5),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              if (_status != null)
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppTheme.ink,
          side: const BorderSide(color: AppTheme.paperDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
