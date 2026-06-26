import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_link_exception.dart';

/// Sign in with Apple → Firebase Auth credential (nonce 포함)
class AppleSignInHelper {
  AppleSignInHelper._();

  static Future<AuthCredential> buildFirebaseCredential() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256(rawNonce);

    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = apple.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthLinkException(
          'Apple 인증 토큰을 받지 못했어요. Xcode에서 Sign in with Apple capability를 켜고 다시 시도해 주세요.',
        );
      }

      final authorizationCode = apple.authorizationCode;
      if (authorizationCode.isEmpty) {
        throw AuthLinkException(
          'Apple 인증 코드를 받지 못했어요. 앱을 재시작한 뒤 다시 시도해 주세요.',
        );
      }

      return OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthLinkException(_mapAppleError(e));
    } on SignInWithAppleNotSupportedException {
      throw AuthLinkException('이 기기에서는 Apple 로그인을 지원하지 않아요.');
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String _mapAppleError(SignInWithAppleAuthorizationException e) {
    return switch (e.code) {
      AuthorizationErrorCode.canceled =>
        'Apple 로그인을 취소했어요.',
      AuthorizationErrorCode.failed =>
        'Apple 로그인에 실패했어요. 네트워크·Apple ID 설정을 확인해 주세요.',
      AuthorizationErrorCode.invalidResponse =>
        'Apple 로그인 응답이 올바르지 않아요. 앱을 재시작한 뒤 다시 시도해 주세요.',
      AuthorizationErrorCode.notHandled =>
        'Apple 로그인을 처리하지 못했어요. Xcode에서 Sign in with Apple을 확인해 주세요.',
      AuthorizationErrorCode.notInteractive =>
        'Apple 로그인 창을 띄울 수 없어요. 앱을 포그라운드에서 다시 시도해 주세요.',
      AuthorizationErrorCode.unknown =>
        'Apple 로그인 중 알 수 없는 오류가 났어요. (${e.message})',
    };
  }
}
