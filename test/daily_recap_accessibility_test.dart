import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_model.dart';
import 'package:projects/Avatar/avatar_widget.dart';
import 'package:projects/prototype/daily_progress.dart';
import 'package:projects/prototype/daily_recap_dialog.dart';

void main() {
  testWidgets('work recap remains scrollable and dismissible with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final sample in [
      (const Size(320, 640), 3.0),
      (const Size(640, 360), 2.0),
    ]) {
      tester.view.physicalSize = sample.$1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(sample.$2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => DailyRecapDialog(
                      progress: DailyProgress(
                        actualMinutes: 60,
                        targetMinutes: 120,
                      ),
                      earnedGross: 6880,
                      earnedHours: 4,
                      note:
                          'Finished an important screen and reviewed the result.',
                      avatar: AvatarModel(),
                      reaction: AvatarReaction.solidProgress,
                    ),
                  ),
                  child: const Text('Recap'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Recap'));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${sample.$1} at ${sample.$2}x',
      );
      await tester.ensureVisible(find.text('What you moved forward'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyRecapDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
