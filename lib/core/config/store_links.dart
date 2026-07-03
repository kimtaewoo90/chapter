/// 스토어 링크 — Remote Config가 비어 있을 때 사용
class StoreLinks {
  StoreLinks._();

  static const androidPackageId = 'com.bomi.chapter';

  static const androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// App Store Connect 앱 ID — 출시 후 `--dart-define=IOS_STORE_ID=123456789` 로 주입
  static const iosStoreId = String.fromEnvironment('IOS_STORE_ID', defaultValue: '');

  static String get defaultIosStoreUrl {
    if (iosStoreId.isEmpty) return '';
    return 'https://apps.apple.com/app/id$iosStoreId';
  }
}
