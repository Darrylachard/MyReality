import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

StoryState story(DateTime day) => StoryState()
  ..begin(
    day,
    name: 'Build',
    outcome: 'Test',
    reason: '',
    minutes: 120,
    nextMonday: false,
  );

void main() {
  test('settled work remains locked after clock rollback and reload', () {
    final day = DateTime(2026, 9, 28);
    var s = story(day);
    s.record(day, 60, 'Original', '');
    s.settle(DateTime(2026, 10, 5));
    s = StoryState.fromMap(s.toMap());
    final before = s.toMap();
    expect(() => s.record(day, 120, 'Changed', ''), throwsStateError);
    expect(() => s.record(day, 60, 'Note edit', 'Sick'), throwsStateError);
    expect(() => s.record(DateTime(2026, 10, 2), 60, '', ''), throwsStateError);
    expect(s.toMap(), before);
    expect(s.pendingGross, 0);
    s.record(DateTime(2026, 10, 5), 20, 'New week', '');
    s.record(DateTime(2026, 10, 5), 60, 'More progress', '');
    expect(s.pendingGross, 6880);
  });

  test('zero pay and final short periods also lock inclusive boundaries', () {
    final s = story(DateTime(2026, 9, 29));
    s.settle(s.finishDate);
    for (final day in s.scheduledDays) {
      expect(s.settledDay(day), isTrue);
      expect(() => s.record(day, 20, '', ''), throwsStateError);
    }
    expect(s.stubs.length, 4);
    expect(s.pendingGross, 0);
  });

  test(
    'stale work day is rejected in either clock direction without mutation',
    () {
      final day = DateTime(2026, 9, 29);
      final s = story(DateTime(2026, 9, 28));
      s.record(day, 20, 'Original', '');
      final before = s.toMap();
      for (final changed in [addDays(day, 1), addDays(day, -1)]) {
        expect(
          () => s.record(changed, 60, '', '', expectedDay: dateKey(day)),
          throwsStateError,
        );
        expect(s.toMap(), before);
      }
      s.record(day, 60, 'Progress', '', expectedDay: dateKey(day));
      expect(s.entry(dateKey(day))!.minutes, 60);
    },
  );

  group('persisted commands and dialogs', () {
    setUp(() async {
      await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
    });
    tearDown(() async {
      await Hive.close();
    });

    test(
      'repository rejects rollback without changing persisted economy',
      () async {
        final day = DateTime(2026, 9, 28);
        final box = Hive.box<dynamic>('account');
        final s = story(day)..record(day, 60, 'Original', '');
        await box.put(StoryRepository.key, s.toMap());
        final repo = StoryRepository(box);
        await repo.update(DateTime(2026, 10, 5), (_) {});
        final before = repo.state.toMap();
        await expectLater(
          repo.update(day, (s) => s.record(day, 120, '', '')),
          throwsStateError,
        );
        expect(repo.state.toMap(), before);
        expect(StoryRepository(box).state.toMap(), before);
      },
    );

    for (final absence in [false, true]) {
      testWidgets(
        '${absence ? "absence" : "work"} dialog cannot cross midnight',
        (tester) async {
          var clock = DateTime(2026, 9, 29, 23, 59);
          final s = story(clock)..record(clock, 20, 'Original', '');
          await Hive.box<dynamic>(
            'account',
          ).put(StoryRepository.key, s.toMap());
          await tester.pumpWidget(
            MaterialApp(home: PrototypePage(now: () => clock)),
          );
          await tester.pumpAndSettle();
          final button = find.text(absence ? 'Call In' : 'Record coding work');
          await tester.scrollUntilVisible(
            button,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          if (!absence) {
            await tester.enterText(find.byType(TextFormField).first, '60');
          }
          clock = DateTime(2026, 9, 30, 0, 1);
          await tester.tap(find.text(absence ? 'Sick' : 'Save work'));
          await tester.pumpAndSettle();
          expect(find.textContaining('The date changed'), findsOneWidget);
          final saved = StoryRepository(Hive.box<dynamic>('account')).state;
          expect(saved.entry('2026-09-29')!.minutes, 20);
          expect(saved.entry('2026-09-30'), isNull);
          expect(saved.pendingGross, 2293);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets(
      'rollback UI disables work and absence for a paid partial day',
      (tester) async {
        final day = DateTime(2026, 9, 28);
        final s = story(day)
          ..record(day, 60, '', '')
          ..settle(DateTime(2026, 10, 5));
        await Hive.box<dynamic>('account').put(StoryRepository.key, s.toMap());
        await tester.pumpWidget(
          MaterialApp(home: PrototypePage(now: () => day)),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Record coding work'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Record coding work'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Call In'),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.text('This pay period is settled. Work entries are locked.'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
