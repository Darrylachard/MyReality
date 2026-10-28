import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/Avatar/avatar_widget.dart';

void main() {
  testWidgets(
    'hidden character drops reactions instead of replaying them when shown',
    (tester) async {
      Widget scene(bool visible, int event) => MaterialApp(
        home: TickerMode(
          enabled: visible,
          child: AvatarWidget(
            avatar: AvatarModel(),
            animate: true,
            reaction: AvatarReaction.targetMet,
            event: event,
          ),
        ),
      );
      Animation<double> animation() =>
          tester
                  .widget<AnimatedBuilder>(
                    find.descendant(
                      of: find.byType(AvatarWidget),
                      matching: find.byType(AnimatedBuilder),
                    ),
                  )
                  .animation
              as Animation<double>;
      await tester.pumpWidget(scene(false, 1));
      expect(animation().status, AnimationStatus.dismissed);
      await tester.pumpWidget(scene(false, 2));
      expect(animation().status, AnimationStatus.dismissed);
      await tester.pumpWidget(scene(true, 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(animation().value, 0);
      await tester.pumpWidget(scene(true, 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(animation().value, greaterThan(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
