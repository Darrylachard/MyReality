import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/Avatar/avatar_creation_page.dart';
import 'package:projects/Avatar/avatar_model.dart';

void main() {
  testWidgets('phone editor saves a copy with the selected hair color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = AvatarModel();
    AvatarModel? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<AvatarModel>(
                  MaterialPageRoute(
                    builder: (_) => AvatarCreatorPage(initial: original),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Copper'), 250);
    await tester.pumpAndSettle();
    final swatch = find
        .ancestor(of: find.text('Copper'), matching: find.byType(SizedBox))
        .first;
    await tester.tap(
      find.descendant(of: swatch, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    expect(original.hairColor, 'natural');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save appearance'));
    await tester.pumpAndSettle();
    expect(saved?.hairColor, 'copper');
    expect(identical(saved, original), isFalse);
  });
}
