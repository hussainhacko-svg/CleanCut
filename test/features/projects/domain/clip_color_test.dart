import 'dart:convert';
import 'dart:io';

import 'package:cleancut/features/projects/data/composition_mapper.dart';
import 'package:cleancut/features/projects/data/project_codec.dart';
import 'package:cleancut/features/projects/domain/commands/clip_commands.dart';
import 'package:cleancut/features/projects/domain/commands/style_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/clip_color.dart';
import 'package:cleancut/features/projects/domain/model/project.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('FilterPreset catalog', () {
    test(
      'has 12 unique presets across 3 categories with bundled .cube files',
      () {
        expect(FilterPreset.all, hasLength(12));
        final ids = FilterPreset.all.map((p) => p.id).toSet();
        expect(ids, hasLength(12));
        for (final category in FilterCategory.values) {
          expect(FilterPreset.inCategory(category), hasLength(4));
        }
        for (final preset in FilterPreset.all) {
          expect(FilterPreset.byId(preset.id), same(preset));
          final file = File(
            'android/app/src/main/assets/luts/${preset.id}.cube',
          );
          expect(file.existsSync(), isTrue, reason: file.path);
        }
        expect(FilterPreset.byId('unknown'), isNull);
      },
    );
  });

  group('ClipFilter & ClipAdjustments', () {
    test('ClipFilter validates id and intensity range', () {
      expect(const ClipFilter(id: 'film_gold').validate(), isEmpty);
      expect(
        const ClipFilter(id: 'film_gold', intensity: 0).validate(),
        isEmpty,
      );
      expect(const ClipFilter(id: '  ').validate(), isNotEmpty);
      expect(
        const ClipFilter(id: 'film_gold', intensity: -0.1).validate(),
        isNotEmpty,
      );
      expect(
        const ClipFilter(id: 'film_gold', intensity: 1.1).validate(),
        isNotEmpty,
      );
      expect(
        const ClipFilter(id: 'film_gold', intensity: double.nan).validate(),
        isNotEmpty,
      );
    });

    test('ClipAdjustments defaults to neutral and validates every field', () {
      expect(ClipAdjustments.none.isNone, isTrue);
      expect(ClipAdjustments.none.validate(), isEmpty);

      for (final field in AdjustmentField.values) {
        final modified = field.withValue(ClipAdjustments.none, field.max);
        expect(modified.isNone, isFalse);
        expect(field.valueOf(modified), field.max);
        expect(modified.validate(), isEmpty);

        // Out-of-range values clamp cleanly through withValue.
        expect(
          field.valueOf(field.withValue(ClipAdjustments.none, 99)),
          field.max,
        );
        expect(
          field.valueOf(field.withValue(ClipAdjustments.none, -99)),
          field.min,
        );
        expect(
          field.valueOf(field.withValue(ClipAdjustments.none, double.nan)),
          0,
        );
      }

      expect(const ClipAdjustments(exposure: 1.5).validate(), isNotEmpty);
      expect(const ClipAdjustments(sharpen: -0.1).validate(), isNotEmpty);
      expect(const ClipAdjustments(vignette: 1.2).validate(), isNotEmpty);
    });

    test('schema v4 round-trips filter & adjustments and migrates v3', () {
      const codec = ProjectCodec();
      final p = project(mainSeconds: [3]);
      final graded =
          const SetClipAdjustmentsCommand(
            'm0',
            ClipAdjustments(
              exposure: 0.25,
              contrast: -0.15,
              warmth: 0.4,
              sharpen: 0.3,
              vignette: 0.5,
            ),
          ).apply(
            const SetClipFilterCommand(
              'm0',
              ClipFilter(id: 'film_cinema', intensity: 0.75),
            ).apply(p),
          );

      final decoded = codec.decode(codec.encode(graded));
      expect(decoded, graded);
      expect(decoded.schemaVersion, Project.currentSchemaVersion);
      expect(
        decoded.mainTrack.clips.first.filter,
        const ClipFilter(id: 'film_cinema', intensity: 0.75),
      );
      expect(decoded.mainTrack.clips.first.adjustments.vignette, 0.5);

      // v3 file without filter/adjustments migrates cleanly to v4.
      final v3Json = p.toJson()..['schemaVersion'] = 3;
      final clips = v3Json['mainTrack'] as Map<String, dynamic>;
      ((clips['clips'] as List<dynamic>).first as Map<String, dynamic>)
        ..remove('filter')
        ..remove('adjustments');
      final migrated = codec.decode(jsonEncode(v3Json));
      expect(migrated.schemaVersion, Project.currentSchemaVersion);
      expect(migrated.mainTrack.clips.first.filter, isNull);
      expect(migrated.mainTrack.clips.first.adjustments, ClipAdjustments.none);
    });
  });

  group('Color EditCommands & mapper', () {
    test('SetClipFilterCommand supports undo, coalescing and validation', () {
      var h = History.initial(project(mainSeconds: [4]));
      h = h.apply(
        const SetClipFilterCommand('m0', ClipFilter(id: 'film_gold')),
      );
      expect(h.present.mainTrack.clips.first.filter?.id, 'film_gold');

      // Coalesced intensity drags form one undo step.
      h = h
          .apply(
            const SetClipFilterCommand(
              'm0',
              ClipFilter(id: 'film_gold', intensity: 0.7),
              coalesce: true,
            ),
          )
          .apply(
            const SetClipFilterCommand(
              'm0',
              ClipFilter(id: 'film_gold', intensity: 0.4),
              coalesce: true,
            ),
          )
          .seal();
      expect(h.present.mainTrack.clips.first.filter?.intensity, 0.4);
      h = h.undo();
      expect(h.present.mainTrack.clips.first.filter?.intensity, 1.0);
      h = h.undo();
      expect(h.present.mainTrack.clips.first.filter, isNull);

      expect(
        () => const SetClipFilterCommand(
          'm0',
          ClipFilter(id: ''),
        ).apply(h.present),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('SetClipAdjustmentsCommand coalesces drags and survives split', () {
      var h = History.initial(project(mainSeconds: [4]));
      h = h
          .apply(
            const SetClipAdjustmentsCommand(
              'm0',
              ClipAdjustments(brightness: 0.2),
            ),
          )
          .apply(
            const SetClipAdjustmentsCommand(
              'm0',
              ClipAdjustments(brightness: 0.5),
            ),
          )
          .seal();
      h = h.apply(
        const SetClipFilterCommand(
          'm0',
          ClipFilter(id: 'bw_noir', intensity: 0.8),
        ),
      );

      // Split preserves both filter and adjustments on both halves.
      final split = SplitClipCommand(
        'm0',
        timeUs: 2000000,
        newId: sequentialIds('s'),
      ).apply(h.present);
      for (final c in split.mainTrack.clips) {
        expect(c.filter, const ClipFilter(id: 'bw_noir', intensity: 0.8));
        expect(c.adjustments.brightness, 0.5);
      }

      // Mapper forwards filter and adjustments (even when uncropped for Crop).
      final spec = compositionSpecOf(split, uncroppedClipId: 'm0');
      final style = spec.clips.first.style;
      expect(style.filterId, 'bw_noir');
      expect(style.filterIntensity, 0.8);
      expect(style.adjustments.brightness, 0.5);

      // Undo reverts filter, then the whole brightness drag in one step.
      h = h.undo();
      expect(h.present.mainTrack.clips.first.filter, isNull);
      h = h.undo();
      expect(h.present.mainTrack.clips.first.adjustments, ClipAdjustments.none);
    });
  });
}
