import 'package:flutter_test/flutter_test.dart';
import 'package:projects/prototype/daily_progress.dart';
import 'package:projects/prototype/story_state.dart';

StoryState newStory() => StoryState()
  ..begin(
    DateTime(2026, 9, 28),
    name: 'Build',
    outcome: 'Ship',
    reason: '',
    minutes: 60,
    nextMonday: false,
  );

void main() {
  test('near-complete work is not displayed as 100 percent', () {
    const p = DailyProgress(actualMinutes: 479, targetMinutes: 480);
    expect(p.completionPercent, '99.8');
    expect(p.state, DailyState.solidProgress);
  });
  test('minimum rounds up, has floor and ceiling, never exceeds target', () {
    for (final sample in {
      1: 1,
      15: 5,
      30: 5,
      45: 10,
      60: 10,
      90: 15,
      120: 20,
      240: 20,
      480: 20,
    }.entries) {
      expect(
        DailyProgress(
          actualMinutes: 0,
          targetMinutes: sample.key,
        ).showUpMinutes,
        sample.value,
      );
    }
  });

  test('daily states have exact boundaries and no extra effort tier', () {
    for (final sample in {
      0: DailyState.notRecorded,
      1: DailyState.started,
      9: DailyState.started,
      10: DailyState.showedUp,
      29: DailyState.showedUp,
      30: DailyState.solidProgress,
      59: DailyState.solidProgress,
      60: DailyState.targetMet,
      100: DailyState.targetMet,
    }.entries) {
      final p = DailyProgress(actualMinutes: sample.key, targetMinutes: 60);
      expect(p.state, sample.value);
      expect(p.participated, sample.key >= 10);
      expect(p.completion, (sample.key / 60).clamp(0, 1));
    }
  });

  test('participation does not replace completion or target-met counts', () {
    final s = newStory();
    final day = s.startDate;
    s.record(day, 10, 'Investigated', '');
    s.record(addDays(day, 1), 30, 'Built', '');
    s.record(addDays(day, 2), 75, 'Shipped', '');
    expect(s.participationDays(addDays(day, 3)), 3);
    expect(s.targetMetDays, 1);
    expect(
      s.consistency(addDays(day, 3)),
      closeTo((1 / 6 + .5 + 1) / 3, .00001),
    );
    expect(s.streak(addDays(day, 3)), 1);
    expect(s.checking, 0);
  });

  test('pay is continuous at Show Up; repeated totals never pay twice', () {
    final s = newStory();
    final day = s.startDate;
    s.record(day, 9, '', '');
    expect(s.pendingGross, 2064);
    s.record(day, 10, '', '');
    expect(s.pendingGross, 2293);
    s.record(day, 15, 'Fixed bug', '');
    expect(s.pendingGross, 3440);
    s.record(day, 15, 'Edited note', '');
    expect(s.pendingGross, 3440);
    s.record(day, 30, '', '');
    expect(s.pendingGross, 6880);
    expect(s.checking, 0);
  });

  test(
    'extra time survives serialization and earns exactly capped weekly pay',
    () {
      var s = newStory();
      for (var i = 0; i < 5; i++) {
        s.record(addDays(s.startDate, i), 100, 'Accomplishment $i', '');
      }
      s = StoryState.fromMap(s.toMap());
      expect(s.work.first.minutes, 100);
      expect(s.work.first.note, 'Accomplishment 0');
      expect(s.targetMetDays, 5);
      expect(s.longestStreak, 5);
      s.settle(addDays(s.startDate, 7));
      expect(s.stubs.single.hours, 40);
      expect(s.stubs.single.gross, 68800);
      expect(s.checking, 25314);
      expect(s.pendingGross, 0);
      expect(() => s.record(s.startDate, 120, '', ''), throwsStateError);
    },
  );

  test('minimum-only Story does not qualify for a raise or final reward', () {
    final s = newStory();
    for (final day in s.scheduledDays) {
      s.settle(day);
      s.record(day, 10, '', '');
    }
    s.settle(s.finishDate);
    expect(s.participationDays(s.finishDate), 15);
    expect(s.targetMetDays, 0);
    expect(s.raisedFrom, isNull);
    expect(s.consistency(s.finishDate), closeTo(1 / 6, .00001));
    s.deliverableDone = true;
    s.ledger.add(
      MoneyEntry('fixture', '', 'Fixture', 'savings', 'opening', 40000),
    );
    expect(() => s.buy(s.finishDate, 'reward'), throwsStateError);
  });
}
