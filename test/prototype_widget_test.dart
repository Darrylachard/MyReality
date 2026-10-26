import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

Future<void> settleUi(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  // Disk persistence is tested independently in story_repository_test.dart.
  setUp(() async {
    await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
  });

  testWidgets('new day keeps yesterday accessible from the recorded timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final yesterday = DateTime(2026, 9, 28);
    final state = StoryState()
      ..begin(
        yesterday,
        name: 'Build',
        outcome: 'Demo',
        reason: 'Learn',
        minutes: 120,
        nextMonday: false,
      );
    state.record(yesterday, 60, 'Finished the first screen', '');
    await Hive.box<dynamic>('account').put(StoryRepository.key, state.toMap());
    await tester.pumpWidget(
      MaterialApp(home: PrototypePage(now: () => addDays(yesterday, 1))),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open recorded timeline'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('60 minutes'), findsOneWidget);
    await tester.tap(find.text('Open recorded timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Your saved Story timeline'), findsOneWidget);
    expect(find.text('Finished the first screen'), findsWidgets);
    expect(
      StoryRepository(Hive.box<dynamic>('account')).state.work.single.minutes,
      60,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'mobile onboarding, partial work and Account survive navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: PrototypePage(now: () => DateTime(2026, 9, 29))),
      );
      await settleUi(tester);
      await tester.tap(find.text('Create my Story'));
      await settleUi(tester);
      await tester.tap(find.text('Start my Story'));
      await settleUi(tester);
      expect(tester.takeException(), isNull);
      var saved = StoryState.fromMap(
        Hive.box<dynamic>('account').get(StoryRepository.key),
      );
      expect(saved.finishDate, DateTime(2026, 10, 20));
      await tester.scrollUntilVisible(
        find.text('Record coding work'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await settleUi(tester);
      await tester.tap(find.text('Record coding work'));
      await settleUi(tester);
      await tester.enterText(find.byType(TextFormField).first, '60');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Built the first screen',
      );
      await tester.tap(find.text('Save work'));
      await settleUi(tester);
      saved = StoryState.fromMap(
        Hive.box<dynamic>('account').get(StoryRepository.key),
      );
      expect(saved.pendingGross, 6880);
      expect(saved.checking, 0);
      expect(find.text('Solid Progress'), findsWidgets);
      expect(find.text(r'+$68.80 pending gross'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await settleUi(tester);
      await tester.tap(find.text('Account'));
      await settleUi(tester);
      expect(find.text(r'$68.80'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('payday UI exposes the deposited net amount and deductions', (
    tester,
  ) async {
    final s = StoryState()
      ..begin(
        DateTime(2026, 9, 28),
        name: 'Build',
        outcome: 'Friend test',
        reason: '',
        minutes: 120,
        nextMonday: false,
      );
    for (var i = 0; i < 5; i++) {
      s.record(DateTime(2026, 9, 28 + i), 120, '', '');
    }
    await tester.runAsync(
      () => Hive.box<dynamic>('account').put(StoryRepository.key, s.toMap()),
    );
    await tester.pumpWidget(
      MaterialApp(home: PrototypePage(now: () => DateTime(2026, 10, 5))),
    );
    await settleUi(tester);
    await tester.tap(find.text('Account'));
    await settleUi(tester);
    expect(find.text(r'$253.14'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('2026-10-05 · \$573.14 net'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleUi(tester);
    await tester.tap(find.text('2026-10-05 · \$573.14 net'));
    await settleUi(tester);
    expect(find.text('Net deposited'), findsOneWidget);
    expect(find.text('Federal income tax'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
