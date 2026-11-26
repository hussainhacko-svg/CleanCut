import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:cleancut/features/projects/domain/model/project_canvas.dart';
import 'package:cleancut/features/projects/presentation/aspect_sheet.dart';
import 'package:cleancut/features/projects/presentation/rename_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

/// Opens a route from a button so its result can be captured.
Widget launcher<T>(
  Future<T?> Function(BuildContext) open,
  void Function(T?) onResult,
) => localizedApp(
  Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async => onResult(await open(context)),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  group('AspectSheet', () {
    testWidgets('offers Original first, then presets', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          const Scaffold(
            body: AspectSheet(original: CanvasAspect.landscape4x3),
          ),
        ),
      );
      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data);
      expect(labels, ['Original', '9:16', '16:9', '1:1', '4:5', '3:4', '4:3']);
    });

    testWidgets('returns the tapped aspect', (tester) async {
      CanvasAspect? result;
      await tester.pumpWidget(
        launcher<CanvasAspect>(
          (c) => showAspectSheet(c, original: CanvasAspect.square),
          (r) => result = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();
      expect(result, CanvasAspect.square);
    });

    testWidgets('kit Ratio style: corners glyph for Original, selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          const Scaffold(
            body: AspectSheet(
              original: CanvasAspect.landscape4x3,
              selected: CanvasAspect.landscape16x9,
            ),
          ),
        ),
      );
      // Original ("Fit" in the kit) is drawn with the corners glyph.
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.icon == AppIcons.fullscreen,
        ),
        findsOneWidget,
      );
      // No boxed tiles: options are bare shapes with captions.
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        ),
        findsNothing,
      );
      final selected = tester.widget<Text>(find.text('16:9'));
      final other = tester.widget<Text>(find.text('9:16'));
      expect(selected.style?.fontWeight, FontWeight.w700);
      expect(other.style?.fontWeight, FontWeight.w400);
      expect(
        tester.getSemantics(find.bySemanticsLabel('16:9')),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('options are at least 48dp tall', (tester) async {
      await tester.pumpWidget(
        localizedApp(const Scaffold(body: AspectSheet())),
      );
      final option = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(InkWell),
      );
      final size = tester.getSize(option.first);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('RenameDialog', () {
    testWidgets('returns the trimmed name', (tester) async {
      String? result;
      await tester.pumpWidget(
        launcher<String>((c) => showRenameDialog(c, 'Old'), (r) => result = r),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  New  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'New');
    });

    testWidgets('blocks empty names', (tester) async {
      await tester.pumpWidget(
        launcher<String>((c) => showRenameDialog(c, 'Old'), (_) {}),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      final save = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(save.onPressed, isNull);
    });

    testWidgets('cancel returns null', (tester) async {
      var called = false;
      String? result = 'unset';
      await tester.pumpWidget(
        launcher<String>((c) => showRenameDialog(c, 'Old'), (r) {
          called = true;
          result = r;
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(result, isNull);
    });
  });
}
