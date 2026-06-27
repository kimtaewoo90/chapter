import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';

/// Firebase Analytics — PII(일기·주소·연락처)는 기록하지 않습니다.
class AnalyticsService {
  FirebaseAnalytics? _analytics;
  StreamSubscription<User?>? _authSub;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _ready = true;

      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        unawaited(setUserId(user?.uid));
      });
      await setUserId(FirebaseAuth.instance.currentUser?.uid);
    } catch (e, st) {
      debugPrint('Analytics init skipped: $e\n$st');
      _ready = false;
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
  }

  Future<void> setUserId(String? uid) async {
    if (!_ready || _analytics == null) return;
    try {
      await _analytics!.setUserId(id: uid);
    } catch (e) {
      debugPrint('Analytics setUserId failed: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _log((a) => a.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
        ));
  }

  Future<void> logLaunchPhase(String phase) => logEvent(
        'launch_phase',
        parameters: {'phase': phase},
      );

  Future<void> logTabSelect(String tab) => logEvent(
        'tab_select',
        parameters: {'tab': tab},
      );

  Future<void> logHomeViewMode(String mode) => logEvent(
        'home_view_mode',
        parameters: {'mode': mode},
      );

  Future<void> logOnboardingStep(int step) => logEvent(
        'onboarding_step',
        parameters: {'step': step},
      );

  Future<void> logOnboardingComplete(UserPreferences prefs) async {
    await logEvent('onboarding_complete');
    await setUserProperty('record_style', prefs.recordStyle);
    await setUserProperty('chronotype', prefs.chronotype);
    await setUserProperty('color_tone', prefs.colorTone);
  }

  Future<void> logDiarySave({
    required bool isToday,
    required bool hasPhotos,
    required bool hasMood,
    required bool hasNote,
    required bool hasAiLine,
  }) =>
      logEvent(
        'diary_save',
        parameters: {
          'is_today': isToday,
          'has_photos': hasPhotos,
          'has_mood': hasMood,
          'has_note': hasNote,
          'has_ai_line': hasAiLine,
        },
      );

  Future<void> logDiaryOpen({required String source}) => logEvent(
        'diary_open',
        parameters: {'source': source},
      );

  Future<void> logCalendarMonthChange({required int year, required int month}) =>
      logEvent(
        'calendar_month_change',
        parameters: {'year': year, 'month': month},
      );

  Future<void> logBookOrderStart({required int entryCount}) => logEvent(
        'book_order_start',
        parameters: {'entry_count': entryCount},
      );

  Future<void> logBookOrderSubmit({
    required int pageCount,
    required bool hardcover,
    required int amount,
    required String cover,
    required String style,
  }) =>
      logEvent(
        'book_order_submit',
        parameters: {
          'page_count': pageCount,
          'hardcover': hardcover,
          'amount': amount,
          'cover': cover,
          'style': style,
        },
      );

  Future<void> logBookOrderStep(int step) => logEvent(
        'book_order_step',
        parameters: {'step': step},
      );

  Future<void> logChapterReveal({
    required String action,
    String? arcId,
  }) =>
      logEvent(
        'chapter_reveal',
        parameters: {
          'action': action,
          if (arcId != null) 'arc_id': _truncate(arcId, 36),
        },
      );

  Future<void> logAccountLink(String provider) => logEvent(
        'account_link',
        parameters: {'provider': provider},
      );

  Future<void> logAccountRestore({
    required String provider,
    required int importedCount,
  }) =>
      logEvent(
        'account_restore',
        parameters: {
          'provider': provider,
          'imported_count': importedCount,
        },
      );

  Future<void> logNotificationSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) =>
      logEvent(
        'notification_settings',
        parameters: {
          'enabled': enabled,
          'hour': hour,
          'minute': minute,
        },
      );

  Future<void> logFontChange({
    required String appFont,
    required String diaryFont,
  }) =>
      logEvent(
        'font_change',
        parameters: {
          'app_font': appFont,
          'diary_font': diaryFont,
        },
      );

  Future<void> logGeminiCheck({required bool connected}) => logEvent(
        'gemini_check',
        parameters: {'connected': connected},
      );

  Future<void> setUserProperty(String name, String? value) async {
    if (!_ready || _analytics == null) return;
    if (value == null || value.isEmpty) return;
    try {
      await _analytics!.setUserProperty(name: name, value: _truncate(value, 36));
    } catch (e) {
      debugPrint('Analytics setUserProperty failed: $e');
    }
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await _log((a) => a.logEvent(
          name: name,
          parameters: _sanitizeParameters(parameters),
        ));
  }

  /// Firebase Analytics 파라미터는 String 또는 num만 허용합니다.
  Map<String, Object>? _sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null || parameters.isEmpty) return null;
    return {
      for (final entry in parameters.entries)
        entry.key: _sanitizeParameterValue(entry.value),
    };
  }

  Object _sanitizeParameterValue(Object value) {
    if (value is String || value is num) return value;
    if (value is bool) return value ? 1 : 0;
    return value.toString();
  }

  Future<void> _log(Future<void> Function(FirebaseAnalytics analytics) action) async {
    if (!_ready || _analytics == null) return;
    try {
      await action(_analytics!);
    } catch (e) {
      debugPrint('Analytics event failed: $e');
    }
  }

  String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}
