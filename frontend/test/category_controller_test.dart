import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/category_management_theme.dart';
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
}
