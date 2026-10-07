import 'package:flutter_test/flutter_test.dart';
import 'package:projects/prototype/story_state.dart';

StoryState story(DateTime start) => StoryState()
  ..begin(
    start,
    name: 'Ship MyReality',
    outcome: 'Friend tests the app',
    reason: 'Finish what I started',
    minutes: 120,
    nextMonday: false,
  );

void main() {
  test('arrears can be cleared without taking Savings automatically', () {
    final s = story(DateTime(2026, 9, 28));
    s.settle(s.finishDate);
    s.ledger.add(
      MoneyEntry('gift', '', 'Test opening', 'savings', 'opening', 40000),
    );
    expect(s.arrears, 32000);
    s.transfer(s.finishDate, 32000, toSavings: false);
    s.payArrears(s.finishDate);
    expect(s.arrears, 0);
    expect(s.checking, 0);
    expect(s.savings, 8000);
  });

  test(
    'final reward needs deadline, outcome and consistency and spends only once',
    () {
      final s = story(DateTime(2026, 9, 28));
      for (final day in s.scheduledDays) {
        s.settle(day);
        s.record(day, 120, '', '');
      }
      s.settle(s.finishDate);
      s.transfer(s.finishDate, 40000, toSavings: true);
      expect(() => s.buy(s.finishDate, 'reward'), throwsStateError);
      s.deliverableDone = true;
      expect(() => s.buy(s.lastDate, 'reward'), throwsStateError);
      s.buy(s.finishDate, 'reward');
      expect(s.savings, 0);
      expect(s.owned, contains('reward'));
      expect(() => s.buy(s.finishDate, 'reward'), throwsStateError);
    },
  );

  test('2026 standard Ontario sample and zero earnings', () {
    final p = PayStub.calculate(
      '2026-09-28',
      '2026-10-04',
      '2026-10-05',
      68800,
      40,
      1720,
    );
    expect(
      [p.federal, p.ontario, p.cpp, p.ei, p.net],
      [4125, 2547, 3693, 1121, 57314],
    );
    final zero = PayStub.calculate('a', 'b', 'c', 0, 0, 1720);
    expect(zero.net, 0);
    expect(zero.deductions, 0);
    expect(
      () => PayStub.calculate('a', 'b', 'c', 100000, 40, 2500),
      throwsStateError,
    );
  });

  test(
    'partial work is replaceable total, no duplicate pay or weekend credit',
    () {
      final s = story(DateTime(2026, 9, 28));
      s.record(DateTime(2026, 9, 28), 60, 'Halfway', '');
      expect(s.pendingGross, 6880);
      s.record(DateTime(2026, 9, 28), 60, 'Same total', '');
      expect(s.pendingGross, 6880);
      expect(s.checking, 0);
      s.record(DateTime(2026, 9, 28), 120, 'Finished', '');
      expect(s.pendingGross, 13760);
      expect(s.work.length, 1);
      expect(
        () => s.record(DateTime(2026, 10, 3), 120, '', ''),
        throwsStateError,
      );
      expect(
        () => s.record(DateTime(2026, 9, 28), 121, '', ''),
        throwsArgumentError,
      );
      expect(
        () => s.record(DateTime(2026, 9, 28), 10, '', ''),
        throwsArgumentError,
      );
    },
  );

  test(
    'calendar weekly payroll, expenses, one raise and final settlement reconcile',
    () {
      final start = DateTime(2026, 9, 28);
      final s = story(start);
      for (var day = 0; day < 21; day++) {
        final date = addDays(start, day);
        s.settle(date);
        if (s.scheduled(date)) s.record(date, 120, 'Built something', '');
      }
      s.settle(s.finishDate);
      expect(s.stubs.length, 3);
      expect(s.stubs.map((p) => p.gross), [68800, 68800, 70800]);
      expect(s.raisedFrom, '2026-10-12');
      expect(s.checking, 77383);
      expect(s.pendingGross, 0);
      expect(s.consistency(s.finishDate), 1);
      expect(s.longestStreak, 15);
      final entries = s.ledger.length;
      s.settle(DateTime(2026, 12, 31));
      expect(s.ledger.length, entries);
      expect(s.checking, 77383);
      expect(s.arrears, 0);
    },
  );

  test(
    'Tuesday start gives 15 weekdays, four deposits and prorated essentials',
    () {
      final start = DateTime(2026, 9, 29);
      final s = story(start);
      expect(s.finishDate, DateTime(2026, 10, 20));
      expect(s.scheduledDays.length, 15);
      for (var day = 0; day < 21; day++) {
        final date = addDays(start, day);
        s.settle(date);
        if (s.scheduled(date)) s.record(date, 120, '', '');
      }
      s.settle(s.finishDate);
      expect(s.stubs.map((p) => p.hours), [32, 40, 40, 8]);
      expect(s.stubs.last.payday, '2026-10-20');
      expect(
        s.ledger
            .where((e) => e.category == 'expense')
            .fold<int>(0, (n, e) => n - e.cents),
        96000,
      );
      expect(s.pendingGross, 0);
    },
  );

  test(
    'rest preserves streak, missed work breaks it without deleting history',
    () {
      final s = story(DateTime(2026, 9, 28));
      for (var day = 28; day <= 30; day++) {
        s.record(DateTime(2026, 9, day), 120, '', '');
      }
      for (var day = 1; day <= 2; day++) {
        s.record(DateTime(2026, 10, day), 120, '', '');
      }
      expect(s.streak(DateTime(2026, 10, 4)), 5);
    expect(s.streak(DateTime(2026, 10, 5, 10)), 5);
    s.record(DateTime(2026, 10, 5, 10), 60, 'Still working', '');
    expect(s.streak(DateTime(2026, 10, 5, 10)), 5);
      expect(s.streak(DateTime(2026, 10, 6)), 0);
      expect(s.longestStreak, 5);
      expect(s.consistency(DateTime(2026, 10, 6)), closeTo(5.5 / 6, .0001));
    },
  );

  test(
    'absence preserves completed work; zero attendance creates bounded arrears',
    () {
      final s = story(DateTime(2026, 9, 28));
      s.record(DateTime(2026, 9, 28), 60, 'Progress', '');
      s.record(DateTime(2026, 9, 28), 60, 'Progress', 'Sick');
      expect(s.pendingGross, 6880);
      final absent = story(DateTime(2026, 9, 28));
      absent.settle(DateTime(2026, 12, 1));
      expect(absent.checking, 0);
      expect(absent.arrears, 32000);
      expect(absent.raisedFrom, isNull);
    },
  );

  test('legacy opening money and paid check-in are never credited twice', () {
    final s = StoryState.fromLegacy({
      'balanceCents': 50000,
      'completedDays': ['2026-09-29'],
      'lastStatementCents': 192640,
      'periodEarningsCents': 13760,
    });
    s.begin(
      DateTime(2026, 9, 29),
      name: 'Test',
      outcome: 'Done',
      reason: '',
      minutes: 120,
      nextMonday: false,
    );
    expect(s.checking, 50000);
    expect(s.pendingGross, 0);
    expect(s.entry('2026-09-29')!.legacy, isTrue);
    expect(
      () => s.record(DateTime(2026, 9, 29), 120, '', ''),
      throwsStateError,
    );
    final restored = StoryState.fromMap(s.toMap());
    expect(restored.checking, 50000);
    expect(restored.legacyStatement, 192640);
  });

  test('transfers conserve money and purchases cannot repeat or overspend', () {
    final s = story(DateTime(2026, 9, 28));
    s.ledger.add(
      MoneyEntry('opening', '', 'Opening', 'checking', 'opening', 20000),
    );
    s.transfer(DateTime(2026, 9, 28), 12000, toSavings: true);
    expect(s.checking + s.savings, 20000);
    expect(() => s.buy(DateTime(2026, 9, 28), 'workspace'), throwsStateError);
    s.buy(DateTime(2026, 9, 28), 'plant');
    expect(s.checking, 5000);
    expect(() => s.buy(DateTime(2026, 9, 28), 'plant'), throwsStateError);
    expect(
      () => s.transfer(DateTime(2026, 9, 28), -1, toSavings: true),
      throwsArgumentError,
    );
  });
}
