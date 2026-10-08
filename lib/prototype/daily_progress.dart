/// Recognition only: changing these thresholds must not change payroll rules.
enum DailyState {
  notRecorded('Not recorded yet'),
  started('Started'),
  showedUp('Showed Up'),
  solidProgress('Solid Progress'),
  targetMet('Target Met');

  const DailyState(this.label);
  final String label;
}

class DailyProgress {
  static const showUpRatio = .15;
  static const roundingMinutes = 5;
  static const minimumMinutes = 5;
  static const maximumMinimumMinutes = 20;
  // Input sanity limit, not an additional reward tier.
  static const maximumDailyMinutes = 24 * 60;

  final int actualMinutes;
  final int targetMinutes;

  const DailyProgress({
    required this.actualMinutes,
    required this.targetMinutes,
  }) : assert(actualMinutes >= 0),
       assert(targetMinutes > 0);

  int get showUpMinutes =>
      ((targetMinutes * showUpRatio / roundingMinutes).ceil() * roundingMinutes)
          .clamp(minimumMinutes, maximumMinimumMinutes)
          .clamp(1, targetMinutes);

  double get completion => (actualMinutes / targetMinutes).clamp(0.0, 1.0);
  String get completionPercent =>
      (completion * 100).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  bool get participated => actualMinutes >= showUpMinutes;
  bool get targetMet => actualMinutes >= targetMinutes;

  DailyState get state {
    if (targetMet) return DailyState.targetMet;
    if (completion >= .5) return DailyState.solidProgress;
    if (participated) return DailyState.showedUp;
    if (actualMinutes > 0) return DailyState.started;
    return DailyState.notRecorded;
  }
}
