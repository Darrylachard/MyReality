# MyReality status

Updated: 2026-10-26. Weekly target: 2026-11-01.
Repository: https://github.com/Darrylachard/MyReality
Working branch: `codex/visible-life-milestone`.

## Current state
- Three-week weekday Story, configurable/tested Showed Up threshold, accomplishment notes, pending income, weekly payroll, savings and three purchases work.
- Settled periods and stale work dialogs remain protected. No economy or Story rules changed in this chapter.
- Original Flutter vector character and warm room replace broken asset layers and the watermarked background in the active app. Existing appearance IDs are preserved.
- Character breathes/blinks periodically and acknowledges successfully saved Showed Up, Solid Progress, Target Met, payday and purchases. Reduced-motion settings are respected. Motion is presentation-only.
- Plant, workspace furniture and final monitor reward visibly change the room; a purchase returns to Home.
- Current validation: 43 tests verified (full suite plus corrected phone-viewport navigation test), analyzer clean, debug Android APK builds. Pixel_4_XL update installed without clearing data; Home inspected on-device.

## Completed this week
1. `e4b2da9`: explicitly flush successful Story writes; disk-reopen regression covers work, notes, appearance, payroll, savings and ownership; invalid saves are not reset.
2. `53fa86d`: replace active avatar and room with original illustrations and ownership-driven furniture.
3. `2cca369`: wire committed-event feedback, short celebrations and purchase navigation; add threshold/replay tests.
4. `dd6e040`: Added cumulative recorded effort and a direct saved-timeline sheet; yesterday remains accessible on a new day without beginning another Story.
5. Created daily 10:00 local-time follow-up in this chat (`myreality-weekly-milestone`). Machine must be on and desktop app running. Stop implementation after November 1 or verified completion, then pause the automation.

## October 26 accessibility check
- Reproduced a 107-pixel Home header overflow at 200% text on a 320px phone viewport. Replaced the rigid header row with wrapping controls.
- Regression verifies no overflow and a tappable Create avatar control at 100%, 200% and 300% text. Scene/reduced-motion and avatar editor tests also pass (3 targeted tests); full analyzer passes with no issues.
- Emulator is connected, but this bounded task used isolated widget fixtures; no device settings or user Story data were changed. Android install remains the October 25 build until the next device QA pass.
- Broader large-text review and isolated on-device reactions/purchases remain pending.

## Current task
Core visual foundation and timeline continuity are implemented. Full Pixel_4_XL shutdown/relaunch passed: the entire decoded snapshot was identical before and after restart. The update preserves the October 8 Story, one 120-minute entry, its note, and avatar exactly. Two newly due pay periods settled on October 25 before the comparison. Private local snapshots are in `.myreality-local/2026-10-25/`, ignored by Git; never publish them. Final Android build passed and was installed over the existing app without clearing data. Next: isolated-device reaction/upgrade QA and user visual review.

## Next task / ordered queue
1. Complete actual-device reaction/upgrade QA on isolated test data and extend large-text review beyond the now-fixed Home scene header. The real user timeline has already passed full emulator restart verification.
2. Review the new cumulative effort total and Open recorded timeline shortcut with the user; verify the distinction between today and past history is clear.
3. Verify work reactions, payday, all appearance variants, reduced motion and purchase persistence on a separate test dataset/device. Do not alter the user's saved Story to demonstrate rewards.
4. Review visual direction with the user; refine character proportions/expressions and room detail based on real Android viewing. Current art is a first coherent pass, not final art approval.
5. Design a safe portable restore flow for the existing backup export: validate schema, preview the selected Story, preserve the current save, explicit restore confirmation, failure tests. No silent reset or automatic replacement.
6. Finish narrow-screen/large-text QA, Android smoke test and milestone acceptance. Commit each verified task separately and back up the branch to GitHub.

## Known bugs / limits
- Historical reported reset was not reproduced: the full saved snapshot survived the October 25 emulator shutdown/relaunch. ADB can report a missing app directory during Android boot before credential-encrypted storage unlocks. Wait for `sys.boot_completed=1` and RUNNING_UNLOCKED before diagnosing loss.
- Local saves cannot survive emulator Wipe Data or uninstall. Clipboard export exists; portable restore UI does not yet exist.
- Legacy HomePage and legacy stock assets remain in source but are not the active route. Do not delete major systems casually.
- Physical phone not connected/tested. Debug emulator rendering is not performance acceptance.
- Rive is not integrated; no usable authored `.riv` or rig exists.

## Decisions made
- Use Flutter-native original vector art and finite animations now. Retain stable saved appearance/item IDs so a future renderer can replace it.
- Reactions derive from committed state transitions; repeated edits and reloads do not earn or replay pay.
- Protect real effort -> acknowledgment -> pending income -> weekly settlement -> spend/save -> visible environment improvement.
- Preserve 15% Showed Up hypothesis, floor/ceiling and rounding as testable recognition logic independent of payroll.

## Decisions requiring user input
- Whether the illustrated character/room direction feels sufficiently mature and close to the desired style.
- Any changes to economy philosophy, Story mechanics, progression, monetization or major system removal require discussion first.

## End-of-week definition of done
- [x] Complete character visible on Home; clean shave and customization render without broken image layers.
- [x] Subtle idle and short work/payday/purchase reactions implemented.
- [x] Original room with no watermark in the active app; purchases alter actual furniture.
- [x] Showed Up, fast work recap, notes, pending pay and protected weekly settlement retained.
- [x] Full disk reopen test retains timeline, appearance, purchases and money without duplicate payroll.
- [x] Existing/new tests pass, analyzer passes, Android debug build passes.
- [x] Full emulator shutdown/relaunch verified and documented.
- [ ] Actual-device reaction/upgrade QA and large-text review completed.
- [ ] User visual review incorporated; target-phone check if available.

## Resume instructions
Read this file, inspect Git status, preserve unrelated/user changes, then choose the first unfinished safe task. Work only on MyReality. Do not reset saved progress, wipe emulator data, falsify work, or purchase items in the user's Story for testing. Use isolated fixtures for demonstrations. Keep this file current after each verified task. Never claim scheduled work ran when the machine/app was unavailable.
