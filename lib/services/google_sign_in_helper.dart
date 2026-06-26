import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/google_oauth_ids.dart';
import 'auth_link_exception.dart';

/// Google Sign-In 단일 인스턴스 + 빠른 silent 시도
class GoogleSignInHelper {
  GoogleSignInHelper._();

  static final GoogleSignInHelper instance = GoogleSignInHelper._();

  static const _webClientIdOverride = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  late final GoogleSignIn _client = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: Platform.isIOS || Platform.isMacOS ? GoogleOAuthIds.iosClientId : null,
    serverClientId: _webClientIdOverride.isEmpty
        ? GoogleOAuthIds.webClientId
        : _webClientIdOverride,
  );

  GoogleSignIn get client => _client;

  /// 이미 기기에 로그인된 Google 계정이면 UI 없이 빠르게 반환
  Future<GoogleSignInAccount?> signInForLink() async {
    try {
      final cached = await _client.signInSilently().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (cached != null) {
        debugPrint('GoogleSignIn: silent ok');
        return cached;
      }
    } catch (e) {
      debugPrint('GoogleSignIn: silent skipped ($e)');
    }

    debugPrint('GoogleSignIn: opening account picker');
    try {
      return await _client.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw AuthLinkException(
            Platform.isIOS
                ? 'Google 계정 창이 뜨지 않았어요. '
                    'python3 scripts/sync_google_ios_config.py 실행 후 '
                    'flutter clean && flutter run 으로 다시 설치해 주세요.'
                : 'Google 계정 창이 뜨지 않았어요. '
                    'Firebase에 Android SHA-1을 등록하고 google-services.json을 다시 받아 주세요.',
          );
        },
      );
    } on AuthLinkException {
      rethrow;
    } catch (e, st) {
      debugPrint('GoogleSignIn signIn failed: $e\n$st');
      throw AuthLinkException(
        'Google 로그인을 열지 못했어요. ($e)',
      );
    }
  }

  /// 계정 연결 화면 진입 시 SDK 초기화 (첫 탭 반응 개선)
  void warmUp() {
    unawaited(
      _client.signInSilently().catchError((Object e) {
        debugPrint('GoogleSignIn warmUp: $e');
        return null;
      }),
    );
  }

  Future<void> signOutIfNeeded() async {
    try {
      await _client.signOut();
    } catch (_) {}
  }
}
