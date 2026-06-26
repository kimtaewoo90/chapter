// Firebase Console + FlutterFire CLI로 생성한 값으로 교체하세요.
// flutterfire configure
//
// 임시: 로컬 개발 시 Firebase 프로젝트 연결 후 이 파일을 덮어씁니다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7TS-Fk60oI_-HR7aYvXE0k0nNYha41ww',
    appId: '1:997338084636:web:2fc95d9b42166da91df6d9',
    messagingSenderId: '997338084636',
    projectId: 'chapter-cc187',
    authDomain: 'chapter-cc187.firebaseapp.com',
    storageBucket: 'chapter-cc187.firebasestorage.app',
    measurementId: 'G-KGV9W017H5',
  );

  // TODO: Firebase Console에서 앱 등록 후 flutterfire configure 실행

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMDy-4kshY9J4nNK2XS0YEi3ud2UzXqzI',
    appId: '1:997338084636:android:d57b150c0c8a2abe1df6d9',
    messagingSenderId: '997338084636',
    projectId: 'chapter-cc187',
    storageBucket: 'chapter-cc187.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAZykfg_KzeZZyS1wrT5MD69IzdHR1IVI',
    appId: '1:997338084636:ios:513e454f3d9a764f1df6d9',
    messagingSenderId: '997338084636',
    projectId: 'chapter-cc187',
    storageBucket: 'chapter-cc187.firebasestorage.app',
    androidClientId: '997338084636-3ce8b880hi07olu035pe5iti71a5cjei.apps.googleusercontent.com',
    iosClientId: '997338084636-utp9eavfasnpuulko3b0vo4gn70q6vlm.apps.googleusercontent.com',
    iosBundleId: 'com.bomi.chapter',
  );

  static const FirebaseOptions macos = ios;
}