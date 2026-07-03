/// `major.minor.patch`(+build) 비교 — 스토어 최소 버전 게이트용
class AppVersion {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  final int major;
  final int minor;
  final int patch;

  /// `1.2.3`, `1.2.3+45` 형식만 지원. 실패 시 null.
  static AppVersion? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final versionPart = trimmed.split('+').first.trim();
    final segments = versionPart.split('.');
    if (segments.length < 3) return null;

    final major = int.tryParse(segments[0]);
    final minor = int.tryParse(segments[1]);
    final patch = int.tryParse(segments[2]);
    if (major == null || minor == null || patch == null) return null;
    if (major < 0 || minor < 0 || patch < 0) return null;

    return AppVersion(major: major, minor: minor, patch: patch);
  }

  /// [other]보다 낮으면 true (업데이트 필요)
  bool isOlderThan(AppVersion other) {
    if (major != other.major) return major < other.major;
    if (minor != other.minor) return minor < other.minor;
    return patch < other.patch;
  }

  String get label => '$major.$minor.$patch';
}

bool isAppVersionOlderThan(String current, String minimum) {
  final currentVersion = AppVersion.parse(current);
  final minimumVersion = AppVersion.parse(minimum);
  if (currentVersion == null || minimumVersion == null) return false;
  return currentVersion.isOlderThan(minimumVersion);
}
