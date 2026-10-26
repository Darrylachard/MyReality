import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('myreality_story_test_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'disk reopen preserves the entire timeline, appearance and purchases',
    () async {
      var box = await Hive.openBox<dynamic>('account');
      final repo = StoryRepository(box);
      final monday = DateTime(2026, 9, 28);
      await repo.update(monday, (s) {
        s.begin(
          monday,
          name: 'Build',
          outcome: 'Demo',
          reason: 'Learn',
          minutes: 120,
          nextMonday: false,
        );
        s.avatar = {
          'body': 'F',
          'skin': 'brown',
          'hair': 'no_hair',
          'hairColor': 'copper',
        };
      });
      for (var i = 0; i < 5; i++) {
        final day = addDays(monday, i);
        await repo.update(day, (s) => s.record(day, 120, 'Milestone $i', ''));
      }
      final payday = addDays(monday, 7);
      await repo.update(payday, (s) {
        s.buy(payday, 'plant');
        s.transfer(payday, 5000, toSavings: true);
      });
      final snapshot = repo.state.toMap();
      expect(repo.state.stubs, hasLength(1));
      await Hive.close();
      Hive.init(directory.path);
      box = await Hive.openBox<dynamic>('account');
      final restored = StoryRepository(box);
      expect(restored.state.toMap(), snapshot);
      await restored.update(payday, (_) {});
      expect(
        restored.state.toMap(),
        snapshot,
        reason: 'Reopening cannot replay payday',
      );
    },
  );

  test('invalid saved data is preserved instead of starting over', () async {
    final box = await Hive.openBox<dynamic>('account');
    final invalid = {'version': 999, 'privateNote': 'Keep me'};
    await box.put(StoryRepository.key, invalid);
    expect(() => StoryRepository(box), throwsStateError);
    expect(box.get(StoryRepository.key), invalid);
  });
  test(
    'migration preserves old snapshot, survives reopen and rejects failed saves',
    () async {
      var box = await Hive.openBox<dynamic>('account');
      final legacy = {
        'balanceCents': 13760,
        'completedDays': ['2026-09-29'],
        'lastStatementCents': null,
        'periodEarningsCents': 13760,
      };
      await box.put('progress', legacy);
      final repo = StoryRepository(box);
      final day = DateTime(2026, 9, 29);
      await repo.update(
        day,
        (s) => s.begin(
          day,
          name: 'Ship',
          outcome: 'Friend test',
          reason: 'Finish',
          minutes: 120,
          nextMonday: false,
        ),
      );
      expect(box.get('progress'), legacy);
      await box.close();
      box = await Hive.openBox<dynamic>('account');
      final restored = StoryRepository(box);
      expect(restored.state.checking, 13760);
      expect(restored.state.entry('2026-09-29')!.legacy, isTrue);
      expect(box.get('progress'), legacy);
      await box.close();
      await expectLater(
        restored.update(day, (s) => s.deliverableDone = true),
        throwsA(anything),
      );
      expect(restored.state.deliverableDone, isFalse);
    },
  );
}
