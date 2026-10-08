# MyReality

A Flutter prototype where recorded coding commitments shape a character's simulated income, workspace and three-week Story.

## Run locally

```sh
flutter pub get
flutter run
```

Fully restart after updating from the original check-in prototype. Do not clear application storage: migration preserves the existing account snapshot.

On Home, choose **Create my Story**. Defaults are a 120-minute coding commitment on Monday–Friday for 21 calendar days. Record the total minutes completed today, not additional minutes. Account separates pending gross earnings from settled net pay.

## Daily recognition prototype

The Show Up minimum is 15% of the target, rounded upward to five minutes, with a five-minute floor and twenty-minute ceiling (never above the target). Home separates participation from weighted plan completion and targets met. The existing full-day streak still measures full completion.

Daily labels are **Not recorded yet**, **Started** (below the minimum), **Showed Up** (minimum reached, below 50%), **Solid Progress** (50% to below 100%), and **Target Met** (100% or more). After a successful work save, a recap shows actual minutes, completion, the accomplishment note, and only the additional simulated hours and pending gross from that update. Failed saves never show a success recap.

You can update work after reaching the target. Actual minutes are preserved (up to 1,440 per day), but earnings stop at 100%; repeating the same total or adding time beyond the target earns no extra pay. Existing same-day totals cannot be reduced. Settled workdays stay locked even after clock rollback, and a form opened on another date must be reopened before saving.

Recognition does not change Monday payroll, deductions, $64-per-weekday essentials, raises, purchase requirements, or the final reward's weighted-completion requirement. Minimum-only days therefore do not qualify as full days for financial progression. There is no timer or required start button, and existing saved Stories need no reset or schema migration.

In **Account → Pay statements**, tap a settled paycheck to open its earnings statement. It shows the saved pay period, equivalent work hours, wage, itemized deductions, net Checking deposit, and year-to-date totals through that statement. Statements use virtual CAD and existing payroll snapshots; opening one never changes a balance. The first statement appears after payroll settles. Year-to-date totals exclude imported balances and later paychecks.

## Verify

```sh
flutter test
flutter analyze
```

Tests use temporary Hive directories and injected clocks; they do not alter the user's account or device clock.

See [PROTOTYPE_PLAN.md](PROTOTYPE_PLAN.md) for the September 29–October 20 trial, migration details, payroll assumptions and friend-test checklist.
