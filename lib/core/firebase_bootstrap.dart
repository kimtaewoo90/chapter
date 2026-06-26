import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth 초기화 — 시뮬레이터·디버그에서 internal-error 완화
Future<void> configureFirebaseAuth() async {
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    } catch (e) {
      debugPrint('FirebaseAuth.setSettings skipped: $e');
    }
  }

  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  if (kDebugMode && useEmulators) {
    const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    debugPrint('Firebase Auth emulator: $host:9099');
  }
}
