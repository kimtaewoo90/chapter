import 'package:chapter/core/utils/app_version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion', () {
    test('parse accepts build suffix', () {
      expect(AppVersion.parse('1.0.0+4')?.label, '1.0.0');
      expect(AppVersion.parse('2.10.3')?.label, '2.10.3');
    });

    test('parse rejects invalid strings', () {
      expect(AppVersion.parse(''), isNull);
      expect(AppVersion.parse('1.0'), isNull);
      expect(AppVersion.parse('a.b.c'), isNull);
    });

    test('isOlderThan compares semver', () {
      final v100 = AppVersion.parse('1.0.0')!;
      final v101 = AppVersion.parse('1.0.1')!;
      final v110 = AppVersion.parse('1.1.0')!;
      final v200 = AppVersion.parse('2.0.0')!;

      expect(v100.isOlderThan(v101), isTrue);
      expect(v101.isOlderThan(v100), isFalse);
      expect(v100.isOlderThan(v110), isTrue);
      expect(v110.isOlderThan(v200), isTrue);
      expect(v100.isOlderThan(v100), isFalse);
    });

    test('isAppVersionOlderThan', () {
      expect(isAppVersionOlderThan('1.0.0', '1.0.0'), isFalse);
      expect(isAppVersionOlderThan('1.0.0+4', '1.0.1'), isTrue);
      expect(isAppVersionOlderThan('1.2.0', '1.1.9'), isFalse);
      expect(isAppVersionOlderThan('bad', '1.0.0'), isFalse);
    });
  });
}
