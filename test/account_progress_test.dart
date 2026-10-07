import 'package:flutter_test/flutter_test.dart';
import 'package:projects/account_progress.dart';

void main() {
  test('one reward per date, including nonconsecutive repeats', () {
    final first = DateTime(2026, 9, 1, 8);
    var account = AccountProgress().checkIn(first);
    expect(account.checkIn(DateTime(2026, 9, 1, 23, 59)), same(account));
    account = account.checkIn(DateTime(2026, 9, 3));
    expect(account.checkIn(first), same(account));
    expect(account.completedDays.length, 2);
    expect(account.balanceCents, 27520);
    expect(account.lastStatementCents, isNull);
  });

  test(
    'statements close on check-ins 14 and 28, independently of spending',
    () {
      var account = AccountProgress();
      for (var day = 1; day <= 13; day++) {
        account = account.checkIn(DateTime(2026, 9, day));
      }
      expect(account.lastStatementCents, isNull);
      expect(account.daysInPeriod, 13);
      account = account.purchase(450).checkIn(DateTime(2026, 9, 14));
      expect(account.lastStatementCents, 192640);
      expect(account.balanceCents, 192190);
      expect(account.periodEarningsCents, 0);
      expect(account.daysInPeriod, 0);
      account = account.purchase(1200).checkIn(DateTime(2026, 9, 15));
      expect(account.lastStatementCents, 192640);
      expect(account.periodEarningsCents, 13760);
      for (var day = 16; day <= 28; day++) {
        account = account.checkIn(DateTime(2026, 9, day));
      }
      expect(account.lastStatementCents, 192640);
      expect(account.periodEarningsCents, 0);
      expect(account.balanceCents, 383630);
    },
  );

  test('saved progress preserves the daily guard and statement', () {
    var account = AccountProgress();
    for (var day = 1; day <= 14; day++) {
      account = account.checkIn(DateTime(2026, 9, day));
    }
    final restored = AccountProgress.fromMap(account.toMap());
    expect(restored.checkIn(DateTime(2026, 9, 14)), same(restored));
    expect(restored.lastStatementCents, 192640);
    expect(restored.purchase(9999999), same(restored));
    expect(restored.purchase(-1), same(restored));
  });
}
