import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/Avatar/avatar_widget.dart';
import 'package:projects/prototype/life_scene.dart';

void main() {
  testWidgets('scene supports saved appearances, upgrades and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    for (final upgraded in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundary,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  LifeScene(
                    avatar: AvatarModel(skinTone: 'brown', hairColor: 'black'),
                    owned: upgraded ? {'plant', 'workspace', 'reward'} : {},
                    onEdit: () {},
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Real effort. Visible progress.',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final surface =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await surface.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('build/visual-review');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/${upgraded ? 'upgraded' : 'starter'}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AvatarWidget(
            avatar: AvatarModel(hairStyle: 'no_hair'),
            animate: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 7));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
