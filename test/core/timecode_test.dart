import 'package:cleancut/core/utils/timecode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats minutes and hours', () {
    expect(formatDurationUs(0), '0:00');
    expect(formatDurationUs(999999), '0:00');
    expect(formatDurationUs(65 * 1000000), '1:05');
    expect(formatDurationUs((3600 + 61) * 1000000), '1:01:01');
  });

  test('clamps negative values', () {
    expect(formatDurationUs(-5), '0:00');
  });
}
