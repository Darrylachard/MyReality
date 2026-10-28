import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

void main() {
  setUp(() async => Hive.openBox<dynamic>('account', bytes: Uint8List(0)));
  tearDown(() async => Hive.close());

  testWidgets(
    'buying a plant changes Home and survives page recreation without another charge',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final start = DateTime(2026, 9, 28);
      final payday = addDays(start, 7);
      final fixture = StoryState()
        ..begin(
          start,
          name: 'Demo',
          outcome: 'Screen',
          reason: 'Learn',
          minutes: 120,
          nextMonday: false,
        );
      for (var i = 0; i < 5; i++) {
        fixture.record(addDays(start, i), 120, 'Test work', '');
      }
      fixture.settle(payday);
      final originalChecking = fixture.checking;
      final box = Hive.box<dynamic>('account');
      await box.put(StoryRepository.key, fixture.toMap());
      Widget app() => MaterialApp(home: PrototypePage(now: () => payday));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Your room'), findsOneWidget);
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review purchase').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review purchase').first);
      await tester.pumpAndSettle();
      expect(find.text('Buy Desk plant?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Buy'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Your room, desk plant'), findsOneWidget);
      expect(
        find.text('Earned through your work. Now part of your space.'),
        findsOneWidget,
      );
      final bought = StoryRepository(box).state;
      expect(
        bought.checking,
        originalChecking - StoryState.products['plant']!.$2,
      );
      expect(bought.owned, ['plant']);
      final saved = bought.toMap();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Your room, desk plant'), findsOneWidget);
      expect(
        find.text('Earned through your work. Now part of your space.'),
        findsNothing,
      );
      expect(StoryRepository(box).state.toMap(), saved);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
