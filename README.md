# MyReality

A Flutter prototype where recorded coding commitments shape a character's simulated income, workspace and three-week Story.

## Run locally

```sh
flutter pub get
flutter run
```

Fully restart after updating from the original check-in prototype. Do not clear application storage: migration preserves the existing account snapshot.

On Home, choose **Create my Story**. Defaults are a 120-minute coding commitment on Monday–Friday for 21 calendar days. Record the total minutes completed today, not additional minutes. Account separates pending gross earnings from settled net pay.

In **Account → Pay statements**, tap a settled paycheck to open its earnings statement. It shows the saved pay period, equivalent work hours, wage, itemized deductions, net Checking deposit, and year-to-date totals through that statement. Statements use virtual CAD and existing payroll snapshots; opening one never changes a balance. The first statement appears after payroll settles. Year-to-date totals exclude imported balances and later paychecks.

## Verify

```sh
flutter test
flutter analyze
```

Tests use temporary Hive directories and injected clocks; they do not alter the user's account or device clock.

See [PROTOTYPE_PLAN.md](PROTOTYPE_PLAN.md) for the September 29–October 20 trial, migration details, payroll assumptions and friend-test checklist.
