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
import 'package:projects/prototype/story_state.dart';
import 'package:projects/prototype/story_repository.dart';

void main() {
  testWidgets('render isolated redesign previews', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
    Future<void> capture(String name, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: RepaintBoundary(key: const ValueKey('capture'), child: child),
        ),
      );
      await tester.pumpAndSettle();
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
        await Directory('build/design-preview').create(recursive: true);
        await File(
          'build/design-preview/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      image.dispose();
    }

    await capture(
      'editor',
      AvatarCreatorPage(
        initial: AvatarModel(
          hairStyle: 'short',
          outfit: 'jacket',
          glasses: 'round',
        ),
      ),
    );
    await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
    final date = DateTime(2026, 11, 9);
    final state = StoryState()
      ..begin(
        date,
        name: 'Build my app',
        outcome: 'Working prototype',
        reason: 'Learn',
        minutes: 120,
        nextMonday: false,
      );
    state.record(date, 60, 'Refined the home screen', '');
    state.avatar = AvatarModel(hairStyle: 'curly', skinTone: 'brown').toMap();
    await Hive.box<dynamic>('account').put(StoryRepository.key, state.toMap());
    await capture('home', PrototypePage(now: () => date));
    await tester.pumpWidget(const SizedBox());
    await Hive.close();
  });
}

