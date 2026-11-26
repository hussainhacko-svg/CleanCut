// Regression tests for the post-Phase-2 audit findings in the domain layer.
import 'dart:math' as math;

import 'package:cleancut/features/projects/domain/model/clip.dart';
import 'package:cleancut/features/projects/domain/model/easing.dart';
import 'package:cleancut/features/projects/domain/model/tracks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('validate() reports instead of throwing', () {
    test('AudioClip with speed 0 and fades', () {
      final clip = AudioClip(
        id: 'a',
        media: audio(),
        sourceInUs: 0,
        sourceOutUs: 1000000,
        speed: 0,
        fadeInUs: 10,
      );
      expect(clip.validate, returnsNormally);
      expect(clip.validate(), contains('speed out of range'));
    });

    test('Project with an invalid overlay clip', () {
      final bad = Clip.fromMedia(id: 'x', media: image()).copyWith(speed: 0);
      final p = project().copyWith(
        overlayTracks: [
          LayerTrack(
            id: 'o',
            items: [PlacedClip(startUs: 0, clip: bad)],
          ),
        ],
      );
      expect(p.validate, returnsNormally);
      expect(p.validate().join(), contains('speed out of range'));
    });

    test('Project with an inverted audio clip', () {
      final p = project().copyWith(
        audioTracks: [
          AudioTrack(
            id: 'a',
            items: [
              PlacedAudioClip(
                startUs: 0,
                clip: AudioClip(
                  id: 'c',
                  media: audio(),
                  sourceInUs: 2000000,
                  sourceOutUs: 1000000,
                ),
              ),
            ],
          ),
        ],
      );
      expect(p.validate, returnsNormally);
      expect(p.validate().join(), contains('zero or negative length'));
    });
  });

  test('Easing matches a brute-force reference for steep curves', () {
    double bez(double a, double b, double s) {
      final inv = 1 - s;
      return 3 * inv * inv * s * a + 3 * inv * s * s * b + s * s * s;
    }

    double reference(Easing e, double x) {
      var lo = 0.0;
      var hi = 1.0;
      for (var i = 0; i < 100; i++) {
        final mid = (lo + hi) / 2;
        if (bez(e.x1, e.x2, mid) < x) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return bez(e.y1, e.y2, (lo + hi) / 2);
    }

    var worst = 0.0;
    for (final (x1, x2) in [(0.0, 1.0), (1.0, 0.0), (0.0, 0.0), (1.0, 1.0)]) {
      final e = Easing(x1: x1, y1: -0.5, x2: x2, y2: 1.5);
      for (var i = 0; i <= 500; i++) {
        final t = i / 500;
        worst = math.max(worst, (e.transform(t) - reference(e, t)).abs());
      }
    }
    expect(worst, lessThan(1e-4));
  });
}
