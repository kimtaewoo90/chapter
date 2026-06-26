import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/daily_reminder_defaults.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/paper_background.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _saving = false;

  Future<void> _pickTime(AppState state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.dailyReminderHour,
        minute: state.dailyReminderMinute,
      ),
      helpText: '알림 시간',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.accent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final err = await appState.setDailyReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      context.read<AnalyticsService>().logNotificationSettings(
            enabled: appState.dailyReminderEnabled,
            hour: picked.hour,
            minute: picked.minute,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final timeLabel = state.dailyReminderTimeLabel;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('알림')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '오늘의 기록',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '조용히 하루를 돌아볼 시간을 알려드려요. '
              '알림 문구는 「${DailyReminderDefaults.body}」예요.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.inkMuted,
                height: 1.55,
              ),
            ),
            if (state.dailyReminderPermissionDenied) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.accent.withValues(alpha: 0.12),
                ),
                child: Text(
                  '알림 권한이 꺼져 있어요. 기기 설정 → Chapter → 알림에서 허용해 주세요.',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.ink),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                title: const Text('매일 알림'),
                subtitle: Text(
                  state.dailyReminderEnabled
                      ? '매일 $timeLabel'
                      : '꺼짐',
                ),
                value: state.dailyReminderEnabled,
                activeTrackColor: AppTheme.accent.withValues(alpha: 0.45),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppTheme.accent
                      : null,
                ),
                onChanged: _saving
                    ? null
                    : (on) async {
                        setState(() => _saving = true);
                        final err =
                            await context.read<AppState>().setDailyReminderEnabled(on);
                        if (!mounted) return;
                        setState(() => _saving = false);
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        } else {
                          final appState = context.read<AppState>();
                          context.read<AnalyticsService>().logNotificationSettings(
                                enabled: appState.dailyReminderEnabled,
                                hour: appState.dailyReminderHour,
                                minute: appState.dailyReminderMinute,
                              );
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                enabled: state.dailyReminderEnabled && !_saving,
                title: const Text('알림 시간'),
                subtitle: Text(timeLabel),
                trailing: const Icon(Icons.schedule_outlined, color: AppTheme.accent),
                onTap: state.dailyReminderEnabled && !_saving
                    ? () => _pickTime(state)
                    : null,
              ),
            ),
            if (_saving) ...[
              const SizedBox(height: 28),
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
