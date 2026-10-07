import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/prototype/pay_statement_sheet.dart';
import 'package:projects/prototype/story_state.dart';

PayStub stub(String payday, int gross) => PayStub(
  periodStart: payday,
  periodEnd: payday,
  payday: payday,
  gross: gross,
  federal: 100,
  ontario: 200,
  cpp: 300,
  ei: 400,
  hours: 8,
  wage: 1720,
);

void main() {
  test('historical YTD excludes future paychecks and prior pay-date years', () {
    final previousYear = stub('2025-12-29', 5000);
    final first = stub('2026-09-28', 10000);
    final selected = stub('2026-10-05', 20000);
    final future = stub('2026-10-12', 30000);
    final sheet = PayStatementSheet(
      stub: selected,
      history: [future, first, previousYear, selected],
    );
    expect(sheet.yearToDate, [first, selected]);
    expect(sheet.yearToDate.fold<int>(0, (n, p) => n + p.net), 28000);
  });

  testWidgets(
    'statement fits a narrow screen with enlarged text and scrolls to totals',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = stub('2026-09-28', 10000);
      final selected = stub('2026-10-05', 20000);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: PayStatementSheet(stub: selected, history: [first, selected]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$190.00'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Pay summary'), 350);
      await tester.pumpAndSettle();
      expect(find.text(r'$280.00'), findsOneWidget);
      expect(find.text('Federal income tax'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
