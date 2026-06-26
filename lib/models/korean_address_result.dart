/// 카카오(다음) 우편번호 검색 결과
class KoreanAddressResult {
  const KoreanAddressResult({
    required this.postCode,
    required this.address,
    required this.roadAddress,
    required this.jibunAddress,
    required this.userSelectedType,
    this.buildingName = '',
  });

  final String postCode;
  final String address;
  final String roadAddress;
  final String jibunAddress;
  final String userSelectedType;
  final String buildingName;

  factory KoreanAddressResult.fromDaumJson(Map<String, dynamic> json) {
    final jibun = (json['jibunAddress'] as String?)?.trim() ?? '';
    final autoJibun = (json['autoJibunAddress'] as String?)?.trim() ?? '';

    return KoreanAddressResult(
      postCode: (json['zonecode'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      roadAddress: (json['roadAddress'] as String?)?.trim() ?? '',
      jibunAddress: jibun.isNotEmpty ? jibun : autoJibun,
      userSelectedType: (json['userSelectedType'] as String?)?.trim() ?? 'R',
      buildingName: (json['buildingName'] as String?)?.trim() ?? '',
    );
  }

  /// 사용자가 선택한 도로명/지번 주소
  String get userSelectedAddress {
    if (userSelectedType == 'J') {
      return jibunAddress.isNotEmpty ? jibunAddress : address;
    }
    return roadAddress.isNotEmpty ? roadAddress : address;
  }
}
