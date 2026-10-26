import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_widget.dart';
import 'package:projects/prototype/life_feedback.dart';
import 'package:projects/prototype/story_state.dart';

void main() {
  test('recognition follows crossed thresholds, not repeated edits', () {
    final day = DateTime(2026, 9, 28);
    var previous = StoryState()
      ..begin(
        day,
        name: 'Build',
        outcome: 'Demo',
        reason: 'Learn',
        minutes: 100,
        nextMonday: false,
      );
    for (final sample in [
      (5, null),
      (15, AvatarReaction.showedUp),
      (30, null),
      (50, AvatarReaction.solidProgress),
      (100, AvatarReaction.targetMet),
      (120, null),
    ]) {
      final next = StoryState.fromMap(previous.toMap());
      next.record(day, sample.$1, 'A useful note', '');
      expect(
        LifeFeedback.between(previous, next, dateKey(day))?.reaction,
        sample.$2,
      );
      expect(
        LifeFeedback.between(
          next,
          StoryState.fromMap(next.toMap()),
          dateKey(day),
        ),
        isNull,
      );
      previous = next;
    }
  });
  test('payday and ownership react once, and do not mutate the ledger', () {
    final day = DateTime(2026, 9, 28);
    final before = StoryState()
      ..begin(
        day,
        name: 'Build',
        outcome: 'Demo',
        reason: 'Learn',
        minutes: 100,
        nextMonday: false,
      );
    for (var i = 0; i < 5; i++) {
      before.record(addDays(day, i), 100, 'Done', '');
    }
    final paid = StoryState.fromMap(before.toMap())..settle(addDays(day, 7));
    final balance = paid.checking;
    expect(
      LifeFeedback.between(before, paid, '2026-10-05')?.reaction,
      AvatarReaction.payday,
    );
    expect(paid.checking, balance);
    final bought = StoryState.fromMap(paid.toMap())
      ..buy(addDays(day, 7), 'plant');
    expect(
      LifeFeedback.between(paid, bought, '2026-10-05')?.reaction,
      AvatarReaction.purchase,
    );
    expect(
      LifeFeedback.between(
        bought,
        StoryState.fromMap(bought.toMap()),
        '2026-10-05',
      ),
      isNull,
    );
  });
}
