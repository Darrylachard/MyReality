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

    await tester.pumpAndSettle();
    final swatch = find
        .ancestor(of: find.text('Copper'), matching: find.byType(SizedBox))
        .first;
    final target = find.descendant(of: swatch, matching: find.byType(InkWell));
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(original.hairColor, 'natural');
    expect(tester.takeException(), isNull);
    await Scrollable.ensureVisible(
      tester.element(find.text('Clothing')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clothing'));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Jacket')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jacket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save appearance'));
    await tester.pumpAndSettle();
    expect(saved?.hairColor, 'copper');
    expect(saved?.outfit, 'jacket');
    expect(original.outfit, 'sweater');
    expect(AvatarModel.fromMap(saved!.toMap()).outfit, 'jacket');
    expect(identical(saved, original), isFalse);
  });
}
