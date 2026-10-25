import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/screen/user/user_screen.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:get/get.dart';

/// Empty session: the screen renders the no-access state, so no network runs.
class _FakeStorageService implements IStorageService {
  @override
  Map<String, dynamic> get lastUserLoginRead => const {'user': {'role': ''}};

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');

    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(_FakeStorageService());
    }
  });

  tearDown(() {
    Get.reset();
  });

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
          GetMaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: UserScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('User Management'), findsNWidgets(2));
        expect(find.textContaining('Manage your café team'), findsOneWidget);
        expect(find.text('Access restricted'), findsOneWidget);
        expect(find.text('Add User'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });
}