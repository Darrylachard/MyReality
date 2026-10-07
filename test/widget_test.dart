import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projects/account_progress.dart';
import 'package:projects/main.dart';

void main() {
  late Directory storage;

  setUp(() async {
    storage = await Directory.systemTemp.createTemp('discipline_account_test_');
    Hive.init(storage.path);
    await Hive.openBox<dynamic>('account');
  });

  tearDown(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });

  testWidgets(
    'rapid taps earn once; restart preserves the guard; next day unlocks',
    (tester) async {
      var now = DateTime(2026, 9, 20, 23, 59);
      Widget app() => MaterialApp(home: HomePage(now: () => now));
      await tester.pumpWidget(app());
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'I showed up!'),
      );
      await tester.runAsync(() async {
        button.onPressed!();
        button.onPressed!();
        await Hive.box<dynamic>('account').flush();
      });
      await tester.pumpAndSettle();
      expect(find.text('Already showed up today'), findsOneWidget);
      var saved = AccountProgress.fromMap(
        Hive.box<dynamic>('account').get('progress') as Map,
      );
      expect(saved.balanceCents, 13760);
      expect(saved.completedDays.length, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await Hive.close();
        await Hive.openBox<dynamic>('account');
      });
      await tester.pumpWidget(app());
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Already showed up today'),
            )
            .onPressed,
        isNull,
      );

      now = DateTime(2026, 9, 21);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('I showed up!'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('I showed up!'));
        await Hive.box<dynamic>('account').flush();
      });
      await tester.pumpAndSettle();
      saved = AccountProgress.fromMap(
        Hive.box<dynamic>('account').get('progress') as Map,
      );
      expect(saved.balanceCents, 27520);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Account captures day 14 earnings and spending leaves statement intact',
    (tester) async {
      var account = AccountProgress();
      for (var day = 1; day <= 13; day++) {
        account = account.checkIn(DateTime(2026, 9, day));
      }
      await tester.runAsync(
        () => Hive.box<dynamic>('account').put('progress', account.toMap()),
      );
      await tester.pumpWidget(
        MaterialApp(home: HomePage(now: () => DateTime(2026, 9, 14))),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('No statement yet'), findsOneWidget);
      expect(
        find.text('13 of 14 check-in days toward your next statement'),
        findsOneWidget,
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('I showed up!'));
        await Hive.box<dynamic>('account').flush();
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text(r'Last statement: $1,926.40'), findsOneWidget);
      expect(
        find.text('0 of 14 check-in days toward your next statement'),
        findsOneWidget,
      );
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Buy').first);
        await Hive.box<dynamic>('account').flush();
      });
      await tester.pumpAndSettle();
      expect(find.text(r'$1,921.90'), findsOneWidget);
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text(r'Last statement: $1,926.40'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
