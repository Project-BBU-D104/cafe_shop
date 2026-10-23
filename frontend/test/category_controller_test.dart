import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/category_management_theme.dart';
import 'package:frontend/screen/category/category_screen.dart';
import 'package:frontend/screen/category/widget/add_category_widget.dart';
import 'package:frontend/screen/category/widget/card_category_widget.dart';
import 'package:frontend/screen/category/widget/edit_category_widget.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  test(
    'onSearchCategory filters by name and restores results when cleared',
    () {
      final controller = CategoryController();

      controller.categoriesList.assignAll([
        {'name': 'Coffee'},
        {'name': 'Tea'},
        {'name': 'Pastries'},
      ]);

      controller.onSearchCategory(' tea ');
      expect(
        controller.searchCategoryList
            .map((category) => category['name'])
            .toList(),
        ['Tea'],
      );

      controller.onSearchCategory('');
      expect(controller.searchCategoryList.length, 3);
    },
  );

  testWidgets('category font supports Khmer and stays scoped to its screen', (
    tester,
  ) async {
    final baseTheme = ThemeData.light().copyWith(
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
        fontFamily: 'Roboto',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: baseTheme,
        home: Scaffold(
          body: Column(
            children: [
              CategoryManagementTheme(
                child: Builder(
                  builder: (context) => Text(
                    'Category កាហ្វេ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const Text('Products'),
            ],
          ),
        ),
      ),
    );

    final categoryContext = tester.element(find.text('Category កាហ្វេ'));
    final otherModuleContext = tester.element(find.text('Products'));

    expect(
      Theme.of(categoryContext).textTheme.bodyMedium?.fontFamily,
      categoryManagementFontFamily,
    );
    expect(
      Theme.of(otherModuleContext).textTheme.bodyMedium?.fontFamily,
      'Roboto',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category card hides description and handles narrow layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: const [
              CardCategoryWidget(
                category: {
                  'name':
                      'A long category name that should wrap on a narrow screen',
                  'description': 'This must remain hidden on the list.',
                  'is_active': true,
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('This must remain hidden on the list.'), findsNothing);
    expect(
      find.text('A long category name that should wrap on a narrow screen'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category content expands when the window is resized wider', (
    tester,
  ) async {
    Get.reset();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _CategoryControllerWithoutLoading();
    Get.put<CategoryController>(controller);
    final category = {
      'id': 7,
      'name': 'Coffee',
      'description': 'Hidden from category cards.',
      'is_active': true,
      'sort_order': 1,
    };
    controller.categoriesList.assignAll([category]);
    controller.searchCategoryList.assignAll([category]);

    await tester.pumpWidget(GetMaterialApp(home: CategoryScreen()));
    await tester.pumpAndSettle();

    final cardFinder = find.byType(CardCategoryWidget);
    final restoredWidth = tester.getSize(cardFinder).width;
    expect(restoredWidth, greaterThan(700));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1600, 900);
    await tester.pumpAndSettle();

    final maximizedWidth = tester.getSize(cardFinder).width;
    expect(maximizedWidth, greaterThan(restoredWidth + 500));
    expect(maximizedWidth, greaterThan(1400));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(480, 540);
    await tester.pumpAndSettle();

    expect(tester.getSize(cardFinder).width, lessThan(maximizedWidth));
    expect(tester.takeException(), isNull);

    Get.reset();
  });

  testWidgets('category details show complete description and metadata', (
    tester,
  ) async {
    Get.reset();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _CategoryControllerWithoutLoading();
    Get.put<CategoryController>(controller);
    const description =
        'Coffee drinks in this category are made with freshly roasted beans.\n'
        'This second line verifies that the complete multiline description is shown.';
    final category = {
      'id': 7,
      'name': 'Coffee',
      'description': description,
      'is_active': true,
      'sort_order': 2,
      'created_at': '2026-10-23T08:30:00Z',
      'updated_at': '2026-10-23T09:15:00Z',
    };
    controller.categoriesList.assignAll([category]);
    controller.searchCategoryList.assignAll([category]);

    await tester.pumpWidget(GetMaterialApp(home: CategoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text(description), findsNothing);
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();

    expect(find.text(description), findsOneWidget);
    expect(find.text('Category ID'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Last Updated'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Get.reset();
  });

  testWidgets('add and edit forms retain their Description fields', (
    tester,
  ) async {
    Get.reset();
    final controller = _CategoryControllerWithoutLoading();
    Get.put<CategoryController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ListView(
            children: [AddCategoryWidget(), EditCategoryWidget(categoryId: 7)],
          ),
        ),
      ),
    );
    await tester.pump();

    final descriptionFields = find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField &&
          widget.controller == controller.cateDescController,
    );
    expect(descriptionFields, findsNWidgets(2));
    expect(find.text('Enter Description'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    Get.reset();
  });
}

class _CategoryControllerWithoutLoading extends CategoryController {
  @override
  // ignore: must_call_super
  void onInit() {}
}
