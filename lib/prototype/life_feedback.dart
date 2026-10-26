import '../Avatar/avatar_widget.dart';
import 'daily_progress.dart';
import 'story_state.dart';

/// Derived only after a repository commit. Never persisted or replayed on load.
class LifeFeedback {
  final AvatarReaction reaction;
  final String caption;
  const LifeFeedback(this.reaction, this.caption);

  static LifeFeedback? between(
    StoryState before,
    StoryState after,
    String day,
  ) {
    if (after.owned.length > before.owned.length) {
      return const LifeFeedback(
        AvatarReaction.purchase,
        'Earned through your work. Now part of your space.',
      );
    }
    if (after.stubs.length > before.stubs.length) {
      return const LifeFeedback(
        AvatarReaction.payday,
        'Payday has arrived. Your statement is in Account.',
      );
    }
    final previous = before.progressFor(before.entry(day)).state;
    final current = after.progressFor(after.entry(day)).state;
    if (current.index <= previous.index) return null;
    return switch (current) {
      DailyState.showedUp => const LifeFeedback(
        AvatarReaction.showedUp,
        'You showed up. That counts.',
      ),
      DailyState.solidProgress => const LifeFeedback(
        AvatarReaction.solidProgress,
        'Solid progress. Your effort is adding up.',
      ),
      DailyState.targetMet => const LifeFeedback(
        AvatarReaction.targetMet,
        'Target met. Take a moment to enjoy it.',
      ),
      _ => null,
    };
  }
}
