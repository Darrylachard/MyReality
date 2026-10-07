# MyReality — first friend test

## Personal trial

- Start: September 29, 2026.
- Last scheduled workday: October 19, 2026.
- Final settlement / friend-test target: October 20, 2026.
- Goal: Get MyReality ready for my friend's first test.
- Commitment: 120 minutes of coding, Monday–Friday.
- Outcome: A working app a friend can install or open and test.
- Story creation remains an explicit in-app action. No personal Story is silently created by installation.

## Playable core now

The app opens the new prototype UI. It reuses the existing avatar assets and creator, and keeps the old HomePage implementation available for regression coverage but not as a second earning route.

One local Story lasts 21 calendar days with 15 scheduled weekdays. Partial coding work earns proportional salary-equivalent hours, up to eight per day. Logging replaces today's total rather than adding another reward. Calling in preserves already-recorded work; its optional reason does not change pay. Weekends preserve the scheduled-day streak. Avatar choices, notes and purchases survive restart.

Gross earnings remain pending. Each Monday settles the previous calendar week, and the Story boundary settles the final partial week. A Tuesday start therefore has four deposits: October 5, 12, 19 and 20. The last is a final partial settlement, not another full weekly paycheck.

Net pay enters Checking with one ledger entry. A bundled starter-essentials bill costs $64 per scheduled weekday ($320/full week), collected after payroll. Unpaid bills never grow beyond $320 and do not accrue interest. Savings can be moved back to Checking to clear arrears. This prototype uses a bundle, not separate daily/monthly bills or the full planned absence/leave policy.

The first permanent $0.50/hour raise requires ten full-day equivalents and at least 90% recent weighted completion at a payroll review. It takes effect in the next period. With the default Tuesday start, perfect participation reaches this review on October 19. The full Monday-start test earns it on the third Monday.

Shop items are one-time visual icons in the Home scene: plant ($30), workspace ($100), final reward ($400 from Savings). The final reward also requires Story end, the deliverable checkbox, and 80% weighted consistency. These prices and the 80% threshold are visible prototype defaults to tune during the trial.

## Persistence and migration

- Existing Hive box: `account`.
- Existing key: `progress`, preserved unchanged.
- New key: `storyPrototypeV1`, explicit schema version 1.
- Old balance becomes one opening-ledger entry.
- Old current-period earnings are already paid and are not reissued.
- Same-day legacy completion is carried in as already-paid work.
- Repository commands clone state, settle due events, apply the command, and persist the entire snapshot before publishing it to the UI.
- Failed saves leave the prior state visible. Unsupported schema versions are not reset.
- Account's backup action copies the new snapshot to the clipboard. It includes private notes; there is not yet an import/restore UI.
- Do not run the old app version against a newer active Story: there is no reverse synchronization into the old key.

## Payroll boundaries

This is a narrow game simulation, not general payroll software. It uses fixed 2026 Ontario rules, one CPP-eligible adult with standard credits, 52 annualized weekly periods, wages limited to $17.20/$17.70, and at most three weeks of earned work. Annual contribution ceilings and higher tax brackets cannot be reached within these supported limits. Unsupported gross amounts are rejected. Rules are pinned and labelled; using the prototype in another tax year does not claim that those are current rates.

Sources verified September 29, 2026:

- [CRA Ontario 2026 payroll tables](https://www.canada.ca/en/revenue-agency/services/forms-publications/payroll/t4032-payroll-deductions-tables/t4032on-jan/t4032on-january-general-information.html)
- [CRA July 2026 changes (Ontario unchanged)](https://www.canada.ca/en/revenue-agency/services/forms-publications/payroll/t4127-payroll-deductions-formulas/t4127-jul/t4127-jul-payroll-deductions-formulas.html)
- [CRA detailed payroll formulas](https://www.canada.ca/en/revenue-agency/services/forms-publications/payroll/t4127-payroll-deductions-formulas/t4127-jan/t4127-jan-payroll-deductions-formulas-computer-programs.html)

Before broad release: validate against PDOC examples and replace the restricted calculator with versioned annual rules if expanding wages/duration. $17.20 is a fictional starting game wage, not current Ontario minimum wage.

## Three-week development checkpoints

### September 29–October 5: use the core

- Run the app on the actual test device.
- Create avatar and Story; record real coding work daily.
- Check restart persistence, partial-work editing and weekend rest.
- Observe first paycheck; compare the statement and ledger.
- Note confusing language or effort required to log a session.

### October 6–12: improve clarity

- Tune essentials, prices and visible reward progress based on the first week.
- Improve the character scene and paycheck presentation.
- Decide whether a simple, clearly labelled forecast helps daily use.
- Add only features needed for the friend's test; avoid expanding to other schedules yet.

### October 13–20: prepare the friend build

- Fix device-specific layout, startup and storage issues.
- Rehearse a full Story ending with an isolated test account/fixture, never by changing the clock on the personal account.
- Verify clean-install onboarding and update migration on the target device.
- Package the selected platform and write short installation instructions.
- Freeze the test build before October 20.

## Friend-test script

1. Without coaching, explain what the app asks you to do and when money is paid.
2. Create an avatar and a coding Story.
3. Record part of today's target, then increase the total. Confirm it is not a second payment.
4. Close and reopen; find the same Story and work note.
5. Explain pending earnings versus spendable Checking money.
6. In an isolated prepared sample account, inspect a pay stub, make a savings transfer, and consider a purchase.
7. Look at an ended sample Story and explain whether its goal was achieved.
8. Report one confusing interaction and whether the character changes feel connected to actual effort.

Success is comprehension and a reliable return after a missed day, not time spent tapping. No contact or messages are sent to the friend by the app.

## Deliberately later

Flexible cycles/swaps, multiple Stories, deadline revisions, sick leave/pause, advanced projections, monthly bill categories, investment/interest systems, account sync, production signing and store publishing. The first build does not pretend these are finished.
