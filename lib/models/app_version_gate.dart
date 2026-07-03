enum VersionBlockReason {
  forceUpdate,
  maintenance,
}

/// Remote Config 기반 버전·점검 게이트 결과
class AppVersionGateResult {
  const AppVersionGateResult({
    required this.currentVersion,
    required this.minSupportedVersion,
    this.blockReason,
    this.title = '',
    this.message = '',
    this.storeUrl = '',
  });

  final String currentVersion;
  final String minSupportedVersion;
  final VersionBlockReason? blockReason;
  final String title;
  final String message;
  final String storeUrl;

  bool get isBlocked => blockReason != null;

  AppVersionGateResult copyWith({
    String? currentVersion,
    String? minSupportedVersion,
    VersionBlockReason? blockReason,
    bool clearBlockReason = false,
    String? title,
    String? message,
    String? storeUrl,
  }) {
    return AppVersionGateResult(
      currentVersion: currentVersion ?? this.currentVersion,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      blockReason: clearBlockReason ? null : (blockReason ?? this.blockReason),
      title: title ?? this.title,
      message: message ?? this.message,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }
}
