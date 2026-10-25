import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/product_variant_controller.dart';
import 'package:frontend/services/api_service.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  test('onSearchVariant filters by name and shows all variants when cleared', () {
    final ctr = ProductVariantController();

    ctr.variantsList.assignAll([
      {'name': 'Regular'},
      {'name': 'Large Iced Latte'},
      {'name': 'Espresso'},
    ]);

    ctr.onSearchVariant('latte');
    expect(
      ctr.searchVariantList.map((v) => v['name']).toList(),
      ['Large Iced Latte'],
    );

    ctr.onSearchVariant('  ');
    expect(ctr.searchVariantList.length, 3);
  });

  test('buildRecipePayload sends the picked ingredient with its unit', () {
    final ctr = ProductVariantController();

    ctr.ingredientsForRecipe.assignAll([
      {'id': 3, 'name': 'Milk', 'unit': 'ml', 'is_active': true},
    ]);
    ctr.recipeIngredientId.value = 3;
    ctr.recipeQuantityController.text = ' 150 ';

    expect(ctr.buildRecipePayload(), {
      'ingredient_id': 3,
      'quantity': '150',
      'unit': 'ml',
    });
  });

  test('validateRecipeQuantity accepts positives and rejects the rest', () {
    expect(ProductVariantController.validateRecipeQuantity('0.5'), isNull);

    for (final bad in ['', '   ', 'abc', '0', '-2']) {
      expect(
        ProductVariantController.validateRecipeQuantity(bad),
        isNotNull,
        reason: '"$bad" should be rejected',
      );
    }
  });

  test('availableRecipeIngredients hides bound and inactive ingredients', () {
    final ctr = ProductVariantController();

    ctr.ingredientsForRecipe.assignAll([
      {'id': 1, 'name': 'Milk', 'unit': 'ml', 'is_active': true},
      {'id': 2, 'name': 'Sugar', 'unit': 'g', 'is_active': true},
      {'id': 3, 'name': 'Old Syrup', 'unit': 'ml', 'is_active': false},
    ]);
    ctr.recipes[7] = [
      {'ingredient_id': 1, 'quantity': '150.000', 'unit': 'ml'},
    ];

    expect(
      ctr.availableRecipeIngredients(7).map((i) => i['name']).toList(),
      ['Sugar'],
    );
  });

  test('a 422 on quantity is shown under the quantity field', () {
    final ctr = ProductVariantController();

    ctr.handleRecipeError(
      ValidationException(
        'The quantity field must have 0-3 decimal places.',
        {
          'quantity': ['The quantity field must have 0-3 decimal places.'],
        },
      ),
    );

    expect(
      ctr.recipeServerErrors['quantity'],
      'The quantity field must have 0-3 decimal places.',
    );
  });
}
