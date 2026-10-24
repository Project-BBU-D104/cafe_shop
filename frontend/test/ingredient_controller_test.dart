import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/ingredient_controller.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  test('onSearchIngredient filters by name and shows all ingredients when cleared', () {
    final ctr = IngredientController();

    ctr.ingredientsList.assignAll([
      {'name': 'Milk'},
      {'name': 'Condensed Milk'},
      {'name': 'Sugar'},
    ]);

    ctr.onSearchIngredient('milk');
    expect(
      ctr.searchIngredientList.map((i) => i['name']).toList(),
      ['Milk', 'Condensed Milk'],
    );

    ctr.onSearchIngredient('  ');
    expect(ctr.searchIngredientList.length, 3);
  });

  test('buildPayload omits stock on update and defaults blank cost to zero', () {
    final ctr = IngredientController();

    ctr.currentStockController.text = '12';
    ctr.costPerUnitController.clear();

    final payload = ctr.buildPayload(includeStock: false);

    expect(payload.containsKey('current_stock'), isFalse);
    expect(payload['cost_per_unit'], '0');
  });
}