import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/keyframe.dart';
import 'package:cleancut/features/projects/domain/model/retiming.dart';
import 'package:flutter_test/flutter_test.dart';

Animatable<double> ramp() => Animatable<double>.keyframed([
  Keyframe(timeUs: 0, value: 0),
  Keyframe(timeUs: 1000, value: 10),
  Keyframe(timeUs: 2000, value: 20),
]);

List<(int, double)> frames(Animatable<double> a) => [
  for (final k in (a as KeyframedAnimatable<double>).keyframes)
    (k.timeUs, k.value),
];

void main() {
  const constant = Animatable<double>.constant(3);

  group('shiftKeyframes', () {
    test('moves keyframes later', () {
      expect(frames(shiftKeyframes(ramp(), 500, lerpDouble)), [
        (500, 0.0),
        (1500, 10.0),
        (2500, 20.0),
      ]);
    });

    test('pins the value at the new start when cutting keyframes', () {
      expect(frames(shiftKeyframes(ramp(), -1500, lerpDouble)), [
        (0, 15.0),
        (500, 20.0),
      ]);
      // A keyframe landing exactly on 0 needs no pin.
      expect(frames(shiftKeyframes(ramp(), -1000, lerpDouble)), [
        (0, 10.0),
        (1000, 20.0),
      ]);
    });

    test('becomes a constant when every keyframe is cut', () {
      expect(
        shiftKeyframes(ramp(), -5000, lerpDouble),
        const Animatable<double>.constant(20),
      );
    });

    test('leaves constants and zero shifts alone', () {
      expect(shiftKeyframes(constant, -100, lerpDouble), same(constant));
      final r = ramp();
      expect(shiftKeyframes(r, 0, lerpDouble), same(r));
    });
  });

  group('clipKeyframes', () {
    test('drops later keyframes and pins the end value', () {
      expect(frames(clipKeyframes(ramp(), 1500, lerpDouble)), [
        (0, 0.0),
        (1000, 10.0),
        (1500, 15.0),
      ]);
    });

    test('keeps everything up to the end unchanged', () {
      final r = ramp();
      expect(clipKeyframes(r, 2000, lerpDouble), same(r));
    });

    test('becomes a constant when all keyframes are after the end', () {
      final late = Animatable<double>.keyframed([
        Keyframe(timeUs: 1000, value: 4),
        Keyframe(timeUs: 2000, value: 8),
      ]);
      expect(
        clipKeyframes(late, 500, lerpDouble),
        const Animatable<double>.constant(4),
      );
    });
  });

  group('scaleKeyframes', () {
    test('stretches keyframe times', () {
      expect(frames(scaleKeyframes(ramp(), 0.5)), [
        (0, 0.0),
        (500, 10.0),
        (1000, 20.0),
      ]);
    });

    test('merges keyframes that round onto the same time', () {
      final dense = Animatable<double>.keyframed([
        Keyframe(timeUs: 0, value: 0),
        Keyframe(timeUs: 1, value: 1),
        Keyframe(timeUs: 10, value: 2),
      ]);
      expect(frames(scaleKeyframes(dense, 0.1)), [(0, 1.0), (1, 2.0)]);
    });

    test('leaves constants alone', () {
      expect(scaleKeyframes(constant, 2), same(constant));
    });
  });
}
