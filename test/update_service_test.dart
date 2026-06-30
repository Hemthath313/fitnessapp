import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/services/update_service.dart';

void main() {
  group('UpdateService Version Comparison Tests', () {
    final updateService = UpdateService();

    test('Identical version strings should return 0', () {
      expect(updateService.compareVersions('1.0.5', '1.0.5'), 0);
      expect(updateService.compareVersions('2.1', '2.1'), 0);
    });

    test('Versions with different suffixes should ignore build numbers', () {
      expect(updateService.compareVersions('1.0.5+20', '1.0.5+19'), 0);
      expect(updateService.compareVersions('1.0.5+19', '1.0.5'), 0);
    });

    test('Newer patch/minor/major versions should return 1', () {
      // v1 (first argument) is newer/larger than v2 (second argument)
      expect(updateService.compareVersions('1.0.6', '1.0.5'), 1);
      expect(updateService.compareVersions('1.1.0', '1.0.5'), 1);
      expect(updateService.compareVersions('2.0.0', '1.0.5'), 1);
    });

    test('Older versions should return -1', () {
      // v1 is older than v2
      expect(updateService.compareVersions('1.0.4', '1.0.5'), -1);
      expect(updateService.compareVersions('1.0.0', '1.0.5'), -1);
      expect(updateService.compareVersions('0.9.9', '1.0.5'), -1);
    });

    test('Variable segment counts should parse correctly', () {
      // 1.0 vs 1.0.1
      expect(updateService.compareVersions('1.0.1', '1.0'), 1);
      expect(updateService.compareVersions('1.0', '1.0.1'), -1);
      // Double digit values
      expect(updateService.compareVersions('1.10.0', '1.9.0'), 1);
      expect(updateService.compareVersions('1.2.12', '1.2.2'), 1);
    });
  });
}
