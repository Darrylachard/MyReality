import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/daily_recap_dialog.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

void main() {
  final day = DateTime(2026, 9, 28);
  setUp(() async {
    final box = await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
    final s = StoryState()
      ..begin(
        day,
        name: 'Build',
        outcome: 'Ship',
        reason: '',
        minutes: 60,
        nextMonday: false,
      );
    await box.put(StoryRepository.key, s.toMap());
  });
  tearDown(() async {
    await Hive.close();
  });

  Future<void> openForm(WidgetTester tester, {bool update = false}) async {
    final button = find.text(
      update ? 'Update today’s work' : 'Record coding work',
    );
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'recap shows saved deltas, accepts extra time and survives reopen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app() => MaterialApp(home: PrototypePage(now: () => day));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      for (final sample in [
        (
          15,
          'Showed Up',
          r'+$34.40 pending gross',
          '+2.00 simulated work hours',
        ),
        (
          30,
          'Solid Progress',
          r'+$34.40 pending gross',
          '+2.00 simulated work hours',
        ),
        (
          60,
          'Target Met',
          r'+$68.80 pending gross',
          '+4.00 simulated work hours',
        ),
        (
          100,
          'Target Met',
          r'+$0.00 pending gross',
          '+0.00 simulated work hours',
        ),
        (
          100,
          'Target Met',
          r'+$0.00 pending gross',
          '+0.00 simulated work hours',
        ),
      ]) {
        final existing = StoryRepository(
          Hive.box<dynamic>('account'),
        ).state.work.isNotEmpty;
        await openForm(tester, update: existing);
        await tester.enterText(
          find.byType(TextFormField).first,
          '${sample.$1}',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'Fixed payroll date bug.',
        );
        await tester.tap(find.text('Save work'));
        await tester.pumpAndSettle();
        final recap = find.byType(DailyRecapDialog);
        expect(recap, findsOneWidget);
        expect(
          find.descendant(of: recap, matching: find.text(sample.$2)),
          findsOneWidget,
        );
        expect(find.text(sample.$3), findsOneWidget);
        expect(find.text(sample.$4), findsOneWidget);
        expect(
          find.text('${sample.$1} focused minutes recorded today'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recap,
            matching: find.text('Fixed payroll date bug.'),
          ),
          findsOneWidget,
        );
        expect(StoryRepository(Hive.box<dynamic>('account')).state.checking, 0);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final restored = StoryRepository(Hive.box<dynamic>('account')).state;
      expect(restored.work.single.minutes, 100);
      expect(restored.pendingGross, 13760);
      expect(restored.targetMetDays, 1);
      expect(find.byType(DailyRecapDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('failed save does not acknowledge or publish work', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: PrototypePage(now: () => day)));
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, '15');
    await Hive.box<dynamic>('account').close();
    await tester.tap(find.text('Save work'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyRecapDialog), findsNothing);
    expect(find.textContaining('Not saved:'), findsOneWidget);
    expect(find.text('0 / 60 minutes · total for today'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
