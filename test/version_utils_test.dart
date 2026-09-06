import 'package:border_player/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses tagged and suffixed versions', () {
    expect(parseReleaseVersion('v2.0.5'), [2, 0, 5]);
    expect(parseReleaseVersion('2.10.0+7'), [2, 10, 0]);
    expect(parseReleaseVersion('v3.0.0-beta.1'), [3, 0, 0]);
  });

  test('compares semantic version components numerically', () {
    expect(isReleaseVersionNewer('v2.10.0', '2.9.0'), isTrue);
    expect(isReleaseVersionNewer('v2.0.10', '2.0.9'), isTrue);
    expect(isReleaseVersionNewer('v2.0.5', '2.0.5'), isFalse);
    expect(isReleaseVersionNewer('v2.0.4', '2.0.5'), isFalse);
  });

  test('rejects malformed versions without throwing', () {
    expect(parseReleaseVersion(''), isNull);
    expect(parseReleaseVersion('release-2.0.5'), isNull);
    expect(isReleaseVersionNewer(null, '2.0.5'), isFalse);
  });
}
