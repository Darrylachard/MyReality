// Narrow-screen and large-text regression matrix for the November 9 redesign.
//
// Renders every active screen (onboarding, active Home, ended Home, Shop,
// Account, work form, avatar editor) across small phones, common phones,
// landscape, enlarged text and reduced motion. A RenderFlex overflow or any
// other layout exception fails the test and names the screen and setting.
//
// Uses an in-memory Hive box and fixed clocks only. It never opens the real
// account box on disk and never touches the device clock.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:projects/Avatar/avatar_creation_page.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/design/reality_theme.dart';
import 'package:projects/prototype/prototype_page.dart';
import 'package:projects/prototype/story_repository.dart';
import 'package:projects/prototype/story_state.dart';

class _Case {
  const _Case(this.width, this.height, this.textScale, {this.reduced = false});
  final double width;
  final double height;
  final double textScale;
  final bool reduced;
  @override
  String toString() =>
      '${width.toInt()}x${height.toInt()} @ ${textScale}x'
      '${reduced ? ' reduced motion' : ''}';
}

const _cases = [
  _Case(320, 568, 1.0), // iPhone SE (1st gen) / small Android
  _Case(320, 640, 2.0),
  _Case(360, 800, 1.3), // common Android
  _Case(390, 844, 2.0, reduced: true),
  _Case(412, 915, 1.5),
  _Case(640, 360, 1.5), // landscape phone
];

/// Active Story: started Monday Nov 2, a full first week recorded, viewed on
/// Monday Nov 9 so the first payroll settles on load and today is empty.
Map<String, dynamic> _activeStory() {
  final start = DateTime(2026, 11, 2);
  final s = StoryState()
    ..begin(
      start,
      name: 'Build my app',
      outcome: 'Working prototype',
      reason: 'Learn',
      minutes: 120,
      nextMonday: false,
    );
  for (var i = 0; i < 5; i++) {
    s.record(
      addDays(start, i),
      [120, 60, 15, 130, 90][i],
      'Day ${i + 1}: refined the home screen and fixed a layout issue',
      '',
    );
  }
  s.avatar = AvatarModel(hairStyle: 'curly', skinTone: 'brown').toMap();
  return s.toMap();
}

/// Ended Story with every weekday recorded, payroll settled and one purchase,
/// viewed a week after the final settlement.
Map<String, dynamic> _endedStory() {
  final start = DateTime(2026, 10, 12);
  final s = StoryState()
    ..begin(
      start,
      name: 'Ship the friend-test build of MyReality',
      outcome: 'Installable Android build',
      reason: 'Consistency',
      minutes: 120,
      nextMonday: false,
    );
  for (var i = 0; i < 21; i++) {
    final d = addDays(start, i);
    if (s.scheduled(d)) s.record(d, 120, 'Recorded session', '');
  }
  s.deliverableDone = true;
  s.settle(DateTime(2026, 11, 2));
  if (s.available >= StoryState.products['plant']!.$2) {
    s.buy(DateTime(2026, 11, 2), 'plant');
  }
  s.avatar = AvatarModel(hairStyle: 'short', glasses: 'round').toMap();
  return s.toMap();
}

void main() {
  setUp(() async {
    await Hive.openBox<dynamic>('account', bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
  });

  Future<List<String>> pumpCase(
    WidgetTester tester,
    _Case c,
    Widget home,
    String screen,
  ) async {
    tester.view.physicalSize = Size(c.width, c.height);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: RealityTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(c.textScale),
            disableAnimations: c.reduced,
          ),
          child: child!,
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
    final failures = <String>[];
    void check(String where) {
      final error = tester.takeException();
      if (error != null) {
        failures.add('$where — $c: ${error.toString().split('\n').first}');
      }
    }

    check(screen);
    return failures;
  }

  /// Scrolls the current tab's list to the end in steps, checking each
  /// viewport, so lazily built ListView children are laid out too.
  Future<void> scrollThrough(
    WidgetTester tester,
    void Function(String) check,
    String where, {
    Finder? scrollable,
  }) async {
    final list = scrollable ?? find.byType(Scrollable).first;
    if (list.evaluate().isEmpty) return;
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, -300), warnIfMissed: false);
      await tester.pumpAndSettle();
      check('$where (scrolled)');
    }
  }

  Future<List<String>> runPrototype(
    WidgetTester tester,
    _Case c,
    String label,
    Map<String, dynamic>? story,
    DateTime now, {
    bool openWorkForm = false,
  }) async {
    final box = Hive.box<dynamic>('account');
    await box.clear();
    if (story != null) await box.put(StoryRepository.key, story);
    final failures = await pumpCase(
      tester,
      c,
      PrototypePage(now: () => now),
      '$label Home',
    );
    void check(String where) {
      final error = tester.takeException();
      if (error != null) {
        failures.add('$where — $c: ${error.toString().split('\n').first}');
      }
    }

    await scrollThrough(tester, check, '$label Home');
    final dialogScroll = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    if (story == null) {
      final create = find.text('Create my Story');
      await tester.scrollUntilVisible(
        create,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      check('$label Story setup');
      await scrollThrough(
        tester,
        check,
        '$label Story setup',
        scrollable: dialogScroll.first,
      );
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
    }
    if (openWorkForm) {
      final button = find.text('Record coding work');
      await tester.scrollUntilVisible(
        button,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      check('$label work form');
      await scrollThrough(
        tester,
        check,
        '$label work form',
        scrollable: dialogScroll.first,
      );
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
    }
    for (final tab in ['Shop', 'Account']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      check('$label $tab');
      await scrollThrough(tester, check, '$label $tab');
    }
    await tester.pumpWidget(const SizedBox());
    return failures;
  }

  testWidgets('redesigned screens lay out on narrow phones and large text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final active = _activeStory();
    final ended = _endedStory();
    final failures = <String>[];
    for (final c in _cases) {
      failures.addAll(
        await runPrototype(
          tester,
          c,
          'Onboarding',
          null,
          DateTime(2026, 11, 9),
        ),
      );
      failures.addAll(
        await runPrototype(
          tester,
          c,
          'Active',
          active,
          DateTime(2026, 11, 9),
          openWorkForm: true,
        ),
      );
      failures.addAll(
        await runPrototype(tester, c, 'Ended', ended, DateTime(2026, 11, 9)),
      );
      failures.addAll(
        await pumpCase(
          tester,
          c,
          AvatarCreatorPage(
            initial: AvatarModel(
              hairStyle: 'short',
              outfit: 'jacket',
              glasses: 'round',
            ),
          ),
          'Avatar editor',
        ),
      );
      void checkEditor(String where) {
        final error = tester.takeException();
        if (error != null) {
          failures.add('$where — $c: ${error.toString().split('\n').first}');
        }
      }

      // Visit every editor tab, not just the default Hair tab.
      final editorScroll = find
          .byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                axisDirectionToAxis(w.axisDirection) == Axis.vertical,
          )
          .first;
      for (final tab in ['Hair', 'Skin & shape', 'Clothing', 'Details']) {
        final chip = find.widgetWithText(ChoiceChip, tab);
        await tester.scrollUntilVisible(chip, -200, scrollable: editorScroll);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        checkEditor('Avatar editor $tab');
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            editorScroll,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
          checkEditor('Avatar editor $tab (scrolled)');
        }
      }
      await tester.pumpWidget(const SizedBox());
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
