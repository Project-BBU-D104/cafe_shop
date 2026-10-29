import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/routes/app_pages.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class _FakeStorageService implements IStorageService {
  @override
  Map<String, dynamic> get lastUserLoginRead =>
      const {
        'user': {'role': 'admin'},
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<GetPage> extraPages = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.home,
      getPages: [...AppPages.pages, ...extraPages],
    ),
  );
  await tester.pumpAndSettle();
  // The welcome card loads a remote placeholder avatar, which tests cannot fetch.
  tester.takeException();
}

class _BoundController extends GetxController {}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');

    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(_FakeStorageService());
    }
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('navigation rail stays visible on pushed pages', (tester) async {
    await _pumpHome(tester);

    expect(find.byType(NavigationRail), findsOneWidget);

    Get.toNamed(AppRoutes.tableNumber, id: 1);
    await tester.pumpAndSettle();

    expect(find.text('Table Management'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    expect(find.text('Table Management'), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('route arguments reach pages pushed into the nested navigator',
      (tester) async {
    await _pumpHome(tester);

    Get.toNamed(AppRoutes.tableNumber, arguments: {'id': 7}, id: 1);
    await tester.pumpAndSettle();

    expect(Get.arguments, {'id': 7});
  });

  testWidgets('system back pops the page inside the nested navigator',
      (tester) async {
    await _pumpHome(tester);

    Get.toNamed(AppRoutes.tableNumber, id: 1);
    await tester.pumpAndSettle();
    expect(find.text('Table Management'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Table Management'), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('a sheet opened from a pushed page closes on Get.back',
      (tester) async {
    await _pumpHome(tester);

    Get.toNamed(AppRoutes.tableNumber, id: 1);
    await tester.pumpAndSettle();

    AppBottomSheets.show(
      tester.element(find.text('Table Management')),
      child: const Text('SHEET'),
    );
    await tester.pumpAndSettle();
    expect(find.text('SHEET'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('SHEET'), findsNothing);
  });

  testWidgets('a page pushed into the nested navigator keeps its binding',
      (tester) async {
    await _pumpHome(tester, extraPages: [
      GetPage(
        name: '/bound',
        page: () => const Scaffold(body: Text('BOUND')),
        binding: BindingsBuilder(() {
          Get.put(_BoundController());
        }),
      ),
    ]);

    Get.toNamed('/bound', id: 1);
    await tester.pumpAndSettle();

    expect(find.text('BOUND'), findsOneWidget);
    expect(Get.isRegistered<_BoundController>(), isTrue);
  });
}