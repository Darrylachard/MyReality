/// A single saved snapshot keeps check-ins, rewards, and statements together.
class AccountProgress {
  static const daysPerStatement = 14;
  static const dailyEarningsCents = 1720 * 8;

  final List<String> completedDays;
  final int balanceCents;
  final int periodEarningsCents;
  final int? lastStatementCents;

  AccountProgress({
    List<String> completedDays = const [],
    this.balanceCents = 0,
    this.periodEarningsCents = 0,
    this.lastStatementCents,
  }) : completedDays = List.unmodifiable(completedDays);

  factory AccountProgress.fromMap(Map<dynamic, dynamic> data) {
    return AccountProgress(
      completedDays: List<String>.from(data['completedDays'] as List),
      balanceCents: data['balanceCents'] as int,
      periodEarningsCents: data['periodEarningsCents'] as int,
      lastStatementCents: data['lastStatementCents'] as int?,
    );
  }

  static String dayKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  bool hasCompleted(DateTime date) => completedDays.contains(dayKey(date));

  int get daysInPeriod => completedDays.length % daysPerStatement;

  AccountProgress checkIn(DateTime date) {
    if (hasCompleted(date)) return this;

    final days = [...completedDays, dayKey(date)];
    final earnings = periodEarningsCents + dailyEarningsCents;
    final closesPeriod = days.length % daysPerStatement == 0;
    return AccountProgress(
      completedDays: days,
      balanceCents: balanceCents + dailyEarningsCents,
      periodEarningsCents: closesPeriod ? 0 : earnings,
      lastStatementCents: closesPeriod ? earnings : lastStatementCents,
    );
  }

  AccountProgress purchase(int priceCents) {
    if (priceCents < 0 || priceCents > balanceCents) return this;
    return AccountProgress(
      completedDays: completedDays,
      balanceCents: balanceCents - priceCents,
      periodEarningsCents: periodEarningsCents,
      lastStatementCents: lastStatementCents,
    );
  }

  Map<String, dynamic> toMap() => {
    'completedDays': completedDays,
    'balanceCents': balanceCents,
    'periodEarningsCents': periodEarningsCents,
    'lastStatementCents': lastStatementCents,
  };
}
