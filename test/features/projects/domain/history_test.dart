import 'package:cleancut/features/projects/domain/commands/project_commands.dart';
import 'package:cleancut/features/projects/domain/history/edit_command.dart';
import 'package:cleancut/features/projects/domain/history/history.dart';
import 'package:cleancut/features/projects/domain/model/animatable.dart';
import 'package:cleancut/features/projects/domain/model/clip_transform.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

ClipTransform scaled(double s) =>
    ClipTransform(scale: Animatable<double>.constant(s));

void main() {
  group('History', () {
    test('starts with nothing to undo or redo', () {
      final h = History.initial(project());
      expect(h.canUndo, isFalse);
      expect(h.canRedo, isFalse);
      expect(h.undo(), same(h));
      expect(h.redo(), same(h));
    });

    test('apply, undo and redo walk the snapshots', () {
      final start = project();
      final h1 = History.initial(start).apply(const RenameProjectCommand('A'));
      final h2 = h1.apply(const RenameProjectCommand('B'));
      expect(h2.present.name, 'B');
      expect(h2.undoDepth, 2);

      final undone = h2.undo();
      expect(undone.present.name, 'A');
      expect(undone.canRedo, isTrue);
      expect(undone.undo().present, start);
      expect(undone.redo().present.name, 'B');
    });

    test('a new edit clears the redo stack', () {
      final h = History.initial(project())
          .apply(const RenameProjectCommand('A'))
          .undo()
          .apply(const RenameProjectCommand('C'));
      expect(h.canRedo, isFalse);
      expect(h.present.name, 'C');
    });

    test('a no-op command adds no undo step', () {
      final h = History.initial(project())
          .apply(const RenameProjectCommand('Test project'));
      expect(h.canUndo, isFalse);
    });

    test('rejected commands leave history untouched', () {
      final h = History.initial(project());
      expect(
        () => h.apply(const RenameProjectCommand('  ')),
        throwsA(isA<InvalidEditException>()),
      );
      expect(h.present, project());
    });

    test('drag ticks with the same key coalesce into one step', () {
      final start = project(mainSeconds: [1]);
      var h = History.initial(start);
      for (final s in [1.1, 1.2, 1.3]) {
        h = h.apply(SetClipTransformCommand('m0', scaled(s)));
      }
      expect(h.undoDepth, 1);
      expect(h.present.mainTrack.clips.first.transform, scaled(1.3));
      expect(h.undo().present, start);
    });

    test('seal ends coalescing', () {
      var h = History.initial(project(mainSeconds: [1]))
          .apply(SetClipTransformCommand('m0', scaled(2)))
          .seal()
          .apply(SetClipTransformCommand('m0', scaled(3)));
      expect(h.undoDepth, 2);
      h = h.undo();
      expect(h.present.mainTrack.clips.first.transform, scaled(2));
    });

    test('different keys or plain commands do not coalesce', () {
      final h = History.initial(project(mainSeconds: [1, 1]))
          .apply(SetClipTransformCommand('m0', scaled(2)))
          .apply(SetClipTransformCommand('m1', scaled(2)))
          .apply(const RenameProjectCommand('X'))
          .apply(const RenameProjectCommand('Y'));
      expect(h.undoDepth, 4);
    });

    test('undo breaks a coalescing run', () {
      final h = History.initial(project(mainSeconds: [1]))
          .apply(SetClipTransformCommand('m0', scaled(2)))
          .apply(const RenameProjectCommand('X'))
          .undo()
          .apply(SetClipTransformCommand('m0', scaled(3)));
      expect(h.undoDepth, 2);
    });

    test('keeps at most limit undo steps', () {
      var h = History.initial(project(), limit: 3);
      for (var i = 0; i < 5; i++) {
        h = h.apply(RenameProjectCommand('n$i'));
      }
      expect(h.undoDepth, 3);
      h = h.undo().undo().undo();
      expect(h.present.name, 'n1');
      expect(h.canUndo, isFalse);
    });

    test('rejects a limit below one', () {
      expect(() => History.initial(project(), limit: 0), throwsArgumentError);
    });
  });

  group('commands', () {
    test('rename trims whitespace', () {
      final p = const RenameProjectCommand('  Trip  ').apply(project());
      expect(p.name, 'Trip');
    });

    test('set canvas aspect', () {
      final p = const SetCanvasAspectCommand(CanvasAspect.portrait9x16)
          .apply(project());
      expect(p.canvas.aspect, CanvasAspect.portrait9x16);
    });

    test('append media adds clips in order with new ids', () {
      final p = AppendMediaCommand([
        video(seconds: 2),
        image(),
      ], newId: sequentialIds()).apply(project(mainSeconds: [1]));
      expect(p.mainTrack.clips.map((c) => c.id), ['m0', 'id0', 'id1']);
      expect(p.validate(), isEmpty);
    });

    test('append nothing is a no-op', () {
      final start = project();
      expect(
        AppendMediaCommand(const [], newId: sequentialIds()).apply(start),
        same(start),
      );
    });

    test('append rejects audio and zero-length media', () {
      expect(
        () => AppendMediaCommand([
          audio(),
        ], newId: sequentialIds()).apply(project()),
        throwsA(isA<InvalidEditException>()),
      );
      expect(
        () => AppendMediaCommand([
          video(seconds: 0),
        ], newId: sequentialIds()).apply(project()),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('set transform rejects unknown clips', () {
      expect(
        () => SetClipTransformCommand('nope', scaled(2)).apply(project()),
        throwsA(isA<InvalidEditException>()),
      );
    });

    test('newProject uses the given aspect', () {
      final p = newProject(
        id: 'x',
        name: 'New',
        now: testTime,
        aspect: CanvasAspect.square,
      );
      expect(p.canvas.aspect, CanvasAspect.square);
      expect(p.createdAt, p.updatedAt);
      expect(p.validate(), isEmpty);
    });
  });
}
