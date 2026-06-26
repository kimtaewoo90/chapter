/// 소셜 계정 연결 실패 — UI 메시지용
class AuthLinkException implements Exception {
  AuthLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}
