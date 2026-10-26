import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/prototype/life_scene.dart';

void main() {
  testWidgets(
    'scene edit remains reachable on narrow screens with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 2.0, 3.0]) {
        var edited = false;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: LifeScene(
                    avatar: AvatarModel(),
                    owned: const {'plant', 'workspace'},
                    onEdit: () => edited = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Text scale $scale');
        await tester.ensureVisible(find.text('Create avatar'));
        await tester.tap(find.text('Create avatar'));
        expect(edited, isTrue);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
