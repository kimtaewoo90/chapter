import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_link_exception.dart';
import 'apple_sign_in_helper.dart';
import 'google_sign_in_helper.dart';

class AuthService {
  AuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  String? get uid => currentUser?.uid;
  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// google.com, apple.com 등 (firebase anonymous 제외)
  List<String> get linkedProviderLabels {
    final user = currentUser;
    if (user == null) return [];
    return user.providerData
        .map((p) => p.providerId)
        .where((id) => id != 'firebase' && id != 'anonymous')
        .map(_providerLabel)
        .toList();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 익명 로그인 (기존 세션 복원 → 최대 3회 재시도)
  Future<User> signInAnonymously() async {
    final existing = currentUser;
    if (existing != null) return existing;

    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final cred = await _auth.signInAnonymously();
        final user = cred.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'null-user',
            message: '익명 로그인 후 사용자 정보가 없습니다.',
          );
        }
        debugPrint('Firebase Auth: anonymous uid=${user.uid}');
        return user;
      } on FirebaseAuthException catch (e) {
        lastError = e;
        debugPrint(
          'FirebaseAuthException (attempt ${attempt + 1}): '
          'code=${e.code}, message=${e.message}',
        );
        if (attempt < 2 && _shouldRetry(e)) {
          await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
          continue;
        }
        rethrow;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        debugPrint('signInAnonymously failed (attempt ${attempt + 1}): $e\n$st');
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }

    Error.throwWithStackTrace(
      lastError ?? StateError('signInAnonymously failed'),
      lastStack ?? StackTrace.empty,
    );
  }

  /// 익명 계정에 Google 연결 — uid 유지, Firestore/Storage 경로 그대로
  Future<User> linkWithGoogle() async {
    final user = _requireAnonymousUser();

    final account = await GoogleSignInHelper.instance.signInForLink();
    if (account == null) {
      throw AuthLinkException('Google 로그인을 취소했어요.');
    }

    final auth = await account.authentication;
    final credential = _googleCredential(auth);
    return _linkCredential(user, credential);
  }

  /// 익명 계정에 Apple 연결 (iOS/macOS)
  Future<User> linkWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw AuthLinkException('Apple 로그인은 iOS·Mac에서만 사용할 수 있어요.');
    }

    final user = _requireAnonymousUser();
    final credential = await AppleSignInHelper.buildFirebaseCredential();
    return _linkCredential(user, credential);
  }

  /// 이미 소셜만 로그인된 경우 Google로 로그인 (다른 기기 복구)
  Future<User> signInWithGoogle() async {
    final account = await GoogleSignInHelper.instance.signInForLink();
    if (account == null) {
      throw AuthLinkException('Google 로그인을 취소했어요.');
    }
    final auth = await account.authentication;
    return _signInWithCredential(_googleCredential(auth));
  }

  /// 이 기기 익명 세션을 끊고, 연결된 Google 계정(uid)으로 로그인
  Future<User> signInWithGoogleForRestore() async {
    try {
      await _auth.signOut();
      await GoogleSignInHelper.instance.signOutIfNeeded();
    } catch (e) {
      debugPrint('signOut before restore: $e');
    }
    return signInWithGoogle();
  }

  Future<User> signInWithAppleForRestore() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw AuthLinkException('Apple 로그인은 iOS·Mac에서만 사용할 수 있어요.');
    }
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('signOut before restore: $e');
    }
    return signInWithApple();
  }

  Future<User> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw AuthLinkException('Apple 로그인은 iOS·Mac에서만 사용할 수 있어요.');
    }
    final credential = await AppleSignInHelper.buildFirebaseCredential();
    return _signInWithCredential(credential);
  }

  AuthCredential _googleCredential(GoogleSignInAuthentication auth) {
    if (auth.idToken == null) {
      throw AuthLinkException(
        'Google 인증 토큰이 없어요. Firebase에서 Google 로그인을 켜고, '
        'Android는 SHA-1 등록 후 google-services.json, '
        'iOS는 GoogleService-Info.plist를 다시 받아 주세요. '
        '(scripts/check_google_config.py)',
      );
    }
    return GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
  }

  User _requireAnonymousUser() {
    final user = currentUser;
    if (user == null) {
      throw AuthLinkException('먼저 앱을 시작해 기록을 불러온 뒤 다시 시도해 주세요.');
    }
    if (!user.isAnonymous) {
      throw AuthLinkException('이미 연결된 계정이에요.');
    }
    return user;
  }

  Future<User> _linkCredential(User user, AuthCredential credential) async {
    try {
      final result = await user.linkWithCredential(credential);
      final linked = result.user;
      if (linked == null) {
        throw AuthLinkException('연결에 실패했어요. 다시 시도해 주세요.');
      }
      await linked.reload();
      debugPrint('Firebase Auth: linked ${linked.providerData.map((p) => p.providerId)} uid=${linked.uid}');
      await linked.getIdToken(true);
      return linked;
    } on FirebaseAuthException catch (e) {
      throw AuthLinkException(_mapLinkError(e));
    }
  }

  Future<User> _signInWithCredential(AuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final signedIn = result.user;
      if (signedIn == null) {
        throw AuthLinkException('로그인에 실패했어요.');
      }
      await signedIn.reload();
      await signedIn.getIdToken(true);
      return signedIn;
    } on FirebaseAuthException catch (e) {
      throw AuthLinkException(_mapLinkError(e));
    }
  }

  String _mapLinkError(FirebaseAuthException e) {
    switch (e.code) {
      case 'credential-already-in-use':
        return '이 계정은 이미 다른 CHAPTER 기록에 연결되어 있어요. 그 계정으로 로그인해 주세요.';
      case 'provider-already-linked':
        return '이미 이 방식으로 연결되어 있어요.';
      case 'account-exists-with-different-credential':
        return '같은 이메일로 다른 로그인 방식이 등록되어 있어요.';
      case 'operation-not-allowed':
        return 'Firebase Console → Authentication → Sign-in method에서 Apple(또는 Google) 로그인을 켜 주세요.';
      case 'invalid-credential':
        return 'Apple 로그인 인증이 만료됐거나 올바르지 않아요. '
            'Firebase Console에서 Apple 로그인 사용 설정·앱 번들 ID(com.bomi.chapter)를 확인한 뒤 다시 시도해 주세요.';
      default:
        return e.message ?? '계정 연결에 실패했어요. (${e.code})';
    }
  }

  bool _shouldRetry(FirebaseAuthException e) {
    return e.code == 'internal-error' ||
        e.code == 'network-request-failed' ||
        e.code == 'too-many-requests';
  }

  Future<User?> retrySignIn() async {
    try {
      if (currentUser != null) {
        await _auth.signOut();
      }
      return await signInAnonymously();
    } catch (e, st) {
      debugPrint('retrySignIn failed: $e\n$st');
      return null;
    }
  }

  static String _providerLabel(String providerId) {
    return switch (providerId) {
      'google.com' => 'Google',
      'apple.com' => 'Apple',
      _ => providerId,
    };
  }
}
