import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screen/user/user_screen.dart';

void main() {
  testWidgets('user screen adapts to window sizes and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const viewports = [Size(320, 560), Size(768, 768), Size(1440, 900)];
    const textScales = [1.0, 2.0];

    for (final viewport in viewports) {
      for (final textScale in textScales) {
        tester.view.physicalSize = viewport;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: const UserScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('User Management'), findsNWidgets(2));
        expect(find.textContaining('Manage your café team'), findsOneWidget);
        expect(find.text('Search users...'), findsOneWidget);
        expect(
          find.text('User directory is not connected yet.'),
          findsOneWidget,
        );
        if (viewport.width >= 1440 && textScale == 1) {
          expect(
            tester.getSize(find.byType(TextField)).width,
            greaterThan(900),
          );
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
}
