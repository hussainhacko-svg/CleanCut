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

  test('clock format pads minutes like the editor readout', () {
    expect(formatClockUs(0), '00:00');
    expect(formatClockUs(6 * 1000000), '00:06');
    expect(formatClockUs(12 * 60 * 1000000 + 999999), '12:00');
    expect(formatClockUs((3600 + 61) * 1000000), '1:01:01');
    expect(formatClockUs(-1), '00:00');
  });
}
