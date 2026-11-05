import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/utils/session.dart';
import 'package:get/get.dart';

class _FakeStorageService implements IStorageService {
  bool loginRemoved = false;
  String? startupRoute;

  @override
  Future<void> lastUserLoginRemove() async {
    loginRemoved = true;
  }

  @override
  Future<void> appStartUpWrite({required String route}) async {
    startupRoute = route;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _FakeStorageService fakeStorage;

  setUpAll(() {
    fakeStorage = _FakeStorageService();
    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(fakeStorage);
    }
  });

  testWidgets('logout clears the session and opens the login screen',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/start',
        getPages: [
          GetPage(name: '/start', page: () => const Scaffold()),
          GetPage(name: AppRoutes.login, page: () => const Scaffold()),
        ],
      ),
    );

    logout();
    await tester.pumpAndSettle();

    expect(fakeStorage.loginRemoved, isTrue);
    expect(fakeStorage.startupRoute, AppRoutes.login);
    expect(Get.currentRoute, AppRoutes.login);
  });
}