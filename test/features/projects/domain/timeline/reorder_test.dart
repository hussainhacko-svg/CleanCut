import 'package:cleancut/features/projects/domain/timeline/reorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Clips of 2 s, 4 s and 2 s: centers at 1 s, 4 s and 7 s.
  const durations = [2000000, 4000000, 2000000];

  test('staying near its own center keeps the index', () {
    expect(reorderTargetIndex(durations, 1, 4000000), 1);
    expect(reorderTargetIndex(durations, 0, 1000000), 0);
  });

  test('passing a neighbour center moves past it', () {
    expect(reorderTargetIndex(durations, 0, 4000001), 1);
    expect(reorderTargetIndex(durations, 0, 9000000), 2);
    expect(reorderTargetIndex(durations, 2, 3999999), 1);
    expect(reorderTargetIndex(durations, 2, -5000000), 0);
  });

  test('a single clip always stays at 0', () {
    expect(reorderTargetIndex(const [1000000], 0, 99000000), 0);
  });

  test('rejects an invalid index', () {
    expect(() => reorderTargetIndex(durations, 3, 0), throwsRangeError);
  });
}
