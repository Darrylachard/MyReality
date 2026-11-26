// Narrow-screen screenshots for a human eye check: active Home and the four
// avatar editor tabs at 320x640, at 1.0x and 2.0x text. Each screen is
// captured at the top and again scrolled to the end.
//
// Isolated fixtures only: in-memory Hive box, fixed clock. Writes PNGs to
// build/design-preview/narrow/ (not committed). Like redesign_preview_test,
// it needs C:/Windows/Fonts/segoeui.ttf and the C:\flutter icon font.
import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/Avatar/avatar_creation_page.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/design/reality_theme.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

void main() {
  testWidgets('render narrow-screen previews', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Preview');
    font.addFont(
      Future.value(
        ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
        ),
      ),
    );
    await tester.runAsync(() => font.load());
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      Future.value(
        ByteData.sublistView(
          File(
            'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
    await tester.runAsync(() => icons.load());
    final theme = RealityTheme.dark.copyWith(
      textTheme: RealityTheme.dark.textTheme.apply(fontFamily: 'Preview'),
      appBarTheme: RealityTheme.dark.appBarTheme.copyWith(
        titleTextStyle: const TextStyle(
          fontFamily: 'Preview',
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: RealityTheme.text,
        ),
      ),
    );

    Future<void> pump(Widget child, double scale) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: 'Preview'),
                child: child!,
              ),
            ),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    Future<void> shot(String name) async {
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      ))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(() async {
        await Directory('build/design-preview/narrow').create(recursive: true);
        await File(
          'build/design-preview/narrow/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      image.dispose();
    }

    Future<void> toEnd(Finder scrollable) async {
      for (var i = 0; i < 10; i++) {
        await tester.drag(
          scrollable,
          const Offset(0, -400),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
      }
    }

    Finder vertical() => find
        .byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              axisDirectionToAxis(w.axisDirection) == Axis.vertical,
        )
        .first;

    // Active Story: first week recorded, viewed Monday Nov 9 with 60 min
    // logged today, so payroll has settled and the Home is fully populated.
    final start = DateTime(2026, 11, 2);
    final today = DateTime(2026, 11, 9, 10);
    final state = StoryState()
      ..begin(
        start,
        name: 'Build my app',
        outcome: 'Working prototype',
        reason: 'Learn',
        minutes: 120,
        nextMonday: false,
      );
    for (var i = 0; i < 5; i++) {
      state.record(
        start.add(Duration(days: i)),
        [120, 60, 15, 130, 90][i],
        'Refined the home screen',
        '',
      );
    }
    state.settle(today);
    state.record(today, 60, 'Fixed a layout issue', '');
    state.avatar = AvatarModel(hairStyle: 'curly', skinTone: 'brown').toMap();

    for (final scale in [1.0, 2.0]) {
      final tag = '320x640_${scale.toStringAsFixed(1)}x';
      await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
      await Hive.box<dynamic>(
        'account',
      ).put(StoryRepository.key, state.toMap());
      await pump(PrototypePage(now: () => today), scale);
      await shot('home_${tag}_top');
      await toEnd(vertical());
      await shot('home_${tag}_end');
      await tester.pumpWidget(const SizedBox());
      await Hive.close();

      await pump(
        AvatarCreatorPage(
          initial: AvatarModel(
            hairStyle: 'short',
            outfit: 'jacket',
            glasses: 'round',
          ),
        ),
        scale,
      );
      final tabs = {
        'Hair': 'hair',
        'Skin & shape': 'skin',
        'Clothing': 'clothing',
        'Details': 'details',
      };
      for (final tab in tabs.entries) {
        final scroll = vertical();
        for (var i = 0; i < 3; i++) {
          await tester.fling(scroll, const Offset(0, 3000), 5000);
          await tester.pumpAndSettle();
        }
        final chip = find.widgetWithText(ChoiceChip, tab.key);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await shot('editor_${tab.value}_${tag}_top');
        // Bring the labelled rows under review fully into view.
        for (final focus
            in const {
                  'hair': {'swatches': 'Silver', 'styles': 'Side swept'},
                  'skin': {'swatches': 'Deep'},
                  'clothing': {'swatches': 'cream'},
                }[tab.value]?.entries ??
                <MapEntry<String, String>>[]) {
          final target = find.text(focus.value, findRichText: true);
          await tester.dragUntilVisible(target, scroll, const Offset(0, -60));
          // Centre the label so its whole row (and any wrapped lines) shows.
          await Scrollable.ensureVisible(
            tester.element(target.first),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          await shot('editor_${tab.value}_${tag}_${focus.key}');
        }
        await toEnd(scroll);
        await shot('editor_${tab.value}_${tag}_end');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
