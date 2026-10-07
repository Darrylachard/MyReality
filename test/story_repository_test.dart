import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/prototype/story_repository.dart';

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
